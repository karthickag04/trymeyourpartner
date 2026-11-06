import 'reflect-metadata';
import { INestApplication } from '@nestjs/common';
import { Test } from '@nestjs/testing';
import { randomUUID } from 'node:crypto';
import { Client } from 'pg';
import request from 'supertest';
import { AppModule } from '../src/app.module';
import { loadConfig } from '../src/config';
import { configureApp } from '../src/setup';

/**
 * End to end against a real PostgreSQL built from supabase/migrations by
 * supabase/tests/local/run.sh (CI: api job). The API connects as api_service,
 * so these tests prove row-level security decides what each caller sees.
 *
 * Each run creates its own two members (fresh ids) through the admin
 * connection, so it does not depend on what other database checks changed.
 *
 *   TEST_DATABASE_URL=postgres://api_service:<pw>@localhost:5432/tmyp_ci  *   TEST_DATABASE_ADMIN_URL=postgres://postgres:<pw>@localhost:5432/tmyp_ci npx jest db.e2e
 */
const url = process.env.TEST_DATABASE_URL;
/** Superuser connection: only to create fixtures and check what the API wrote. */
const adminUrl = process.env.TEST_DATABASE_ADMIN_URL;
const run = url && adminUrl ? describe : describe.skip;

const A = { id: randomUUID(), email: `e2e.a.${Date.now()}@x.com`, profile: randomUUID() };
const B = { id: randomUUID(), email: `e2e.b.${Date.now()}@x.com`, profile: randomUUID() };
const BM_X = { id: '44444444-4444-4444-4444-444444444444', email: 'bm.x@x.com' };
const B_PROFILE = B.profile;

async function admin<T>(work: (c: Client) => Promise<T>): Promise<T> {
  const c = new Client({ connectionString: adminUrl });
  await c.connect();
  try {
    return await work(c);
  } finally {
    await c.end();
  }
}

/** Unsigned tokens; the Supabase Auth stand-in below decides which are valid. */
function token(sub: string, aal: 'aal1' | 'aal2') {
  const b64 = (o: object) => Buffer.from(JSON.stringify(o)).toString('base64url');
  return `${b64({ alg: 'HS256' })}.${b64({ sub, aal, role: 'authenticated' })}.sig`;
}
const TOKENS = {
  a: token(A.id, 'aal1'),
  aWithMfa: token(A.id, 'aal2'),
  bmX: token(BM_X.id, 'aal2'),
};
const USERS = new Map([
  [TOKENS.a, A],
  [TOKENS.aWithMfa, A],
  [TOKENS.bmX, BM_X],
]);

run('API on plain PostgreSQL (row-level security end to end)', () => {
  let app: INestApplication;
  const get = (path: string, t: string) =>
    request(app.getHttpServer()).get(path).set('Authorization', `Bearer ${t}`);

  beforeAll(async () => {
    await admin(async (c) => {
      await c.query('insert into auth.users(id, email) values ($1, $2), ($3, $4)', [A.id, A.email, B.id, B.email]);
      await c.query(
        `insert into public.matrimonial_profiles
           (id, auth_user_id, name, gender, date_of_birth, religion, marital_status, is_active, is_verified)
         values ($1, $2, 'E2E A', 'Male', '1995-01-01', 'Hindu', 'Never Married', true, false),
                ($3, $4, 'E2E B', 'Female', '1996-01-01', 'Hindu', 'Never Married', true, true)`,
        [A.profile, A.id, B.profile, B.id],
      );
      await c.query(
        `insert into public.contact_info(profile_id, phone_number, whatsapp_number, current_address)
         values ($1, '9100000002', '9100000003', 'secret street')`,
        [B.profile],
      );
    });
    global.fetch = jest.fn(async (input: string | URL | Request, init?: RequestInit) => {
      const u = String(input);
      if (!u.endsWith('/auth/v1/user')) throw new Error(`unexpected network call: ${u}`);
      const auth = (init?.headers as Record<string, string>).Authorization.replace('Bearer ', '');
      const user = USERS.get(auth);
      return new Response(JSON.stringify(user ?? { msg: 'bad token' }), { status: user ? 200 : 401 });
    }) as typeof fetch;
    const config = loadConfig({
      SUPABASE_URL: 'https://example.supabase.co',
      SUPABASE_PUBLISHABLE_KEY: 'sb_publishable_test',
      TOKEN_VERIFICATION: 'provider',
      DATABASE_URL: url,
    });
    const mod = await Test.createTestingModule({ imports: [AppModule.forRoot(config)] }).compile();
    app = mod.createNestApplication();
    configureApp(app, config);
    await app.init();
  });
  afterAll(() => app?.close());

  it('api_service on its own can read nothing (no inherited rights)', async () => {
    const c = new Client({ connectionString: url });
    await c.connect();
    try {
      await expect(c.query('select id from public.matrimonial_profiles limit 1')).rejects.toThrow(
        /permission denied/,
      );
      await expect(c.query('select id from auth.users limit 1')).rejects.toThrow(/permission denied/);
    } finally {
      await c.end();
    }
  });

  it("GET /v1/me returns the member's own profile, with dates as plain dates", async () => {
    const res = await get('/v1/me', TOKENS.a).expect(200);
    expect(res.body.email).toBe(A.email);
    expect(res.body.profile).toMatchObject({
      id: A.profile,
      name: 'E2E A',
      date_of_birth: '1995-01-01',
      is_verified: false,
    });
  });

  it('contact reveal goes through reveal_contact and returns only the numbers', async () => {
    const res = await request(app.getHttpServer())
      .post(`/v1/profiles/${B_PROFILE}/contact-reveal`)
      .set('Authorization', `Bearer ${TOKENS.a}`)
      .expect(200);
    expect(res.body).toEqual({ phoneNumber: '9100000002', whatsappNumber: '9100000003' });
    expect(JSON.stringify(res.body)).not.toContain('secret street'); // never the address
  });

  it("the database's own errors reach the caller (cannot reveal yourself)", async () => {
    const res = await request(app.getHttpServer())
      .post(`/v1/profiles/${A.profile}/contact-reveal`)
      .set('Authorization', `Bearer ${TOKENS.a}`)
      .expect(400);
    expect(res.body.code).toBe('CANNOT_REVEAL_SELF');
  });

  it('a member with MFA still gets no admin access: the database says NOT_STAFF', async () => {
    const res = await get('/admin/v1/me', TOKENS.aWithMfa).expect(403);
    expect(res.body.code).toBe('NOT_STAFF');
  });

  it('a branch manager sees their branch only, and the view is audited', async () => {
    const me = await get('/admin/v1/me', TOKENS.bmX).expect(200);
    expect(me.body).toMatchObject({ role: 'branch_manager', branch: { name: 'Branch X' } });

    const audited = () =>
      admin(async (c) => {
        const r = await c.query(
          "select count(*)::int as n from public.audit_log where action = 'staff.list' and actor = $1",
          [BM_X.id],
        );
        return r.rows[0].n as number;
      });
    const before = await audited();
    const res = await get('/admin/v1/staff', TOKENS.bmX).expect(200);
    expect(await audited()).toBe(before + 1);
    const names = (res.body as { displayName: string }[]).map((s) => s.displayName);
    expect(names).toEqual(expect.arrayContaining(['BM X', 'Staff X']));
    expect(names).not.toContain('Staff Y'); // branch Y
    expect(names).not.toContain('Sys Admin'); // no branch
    const bm = (res.body as { displayName: string; branch: unknown }[]).find((s) => s.displayName === 'BM X');
    expect(bm?.branch).toEqual({ id: '0000000a-0000-0000-0000-00000000000a', code: 'BRX', name: 'Branch X' });
  });
});
