import 'reflect-metadata';
import { INestApplication } from '@nestjs/common';
import { Test } from '@nestjs/testing';
import request from 'supertest';
import { AppModule } from '../src/app.module';
import { ApiConfig, loadConfig } from '../src/config';
import { configureApp } from '../src/setup';

const config: ApiConfig = loadConfig({
  SUPABASE_URL: 'https://example.supabase.co/',
  SUPABASE_PUBLISHABLE_KEY: 'sb_publishable_test',
});

/** An unsigned token with the given claims; the stand-in below decides which tokens are valid. */
function token(sub: string, aal: 'aal1' | 'aal2') {
  const b64 = (o: object) => Buffer.from(JSON.stringify(o)).toString('base64url');
  return `${b64({ alg: 'HS256' })}.${b64({ sub, aal, role: 'authenticated' })}.sig`;
}

const USERS: Record<string, { id: string; email: string }> = {
  member: { id: '11111111-1111-1111-1111-111111111111', email: 'member@example.com' },
  manager: { id: '44444444-4444-4444-4444-444444444444', email: 'bm.x@example.com' },
  staff: { id: '55555555-5555-5555-5555-555555555555', email: 'staff.y@example.com' },
};
const TOKENS = {
  memberAal2: token(USERS.member.id, 'aal2'),
  managerAal1: token(USERS.manager.id, 'aal1'),
  managerAal2: token(USERS.manager.id, 'aal2'),
  staffAal2: token(USERS.staff.id, 'aal2'),
};
const VALID = new Map<string, { id: string; email: string }>([
  [TOKENS.memberAal2, USERS.member],
  [TOKENS.managerAal1, USERS.manager],
  [TOKENS.managerAal2, USERS.manager],
  [TOKENS.staffAal2, USERS.staff],
]);

const BRANCH_X = '0000000a-0000-0000-0000-00000000000a';
const PROFILES: Record<string, object | null> = {
  [USERS.member.id]: null,
  [USERS.manager.id]: {
    user_id: USERS.manager.id,
    role: 'branch_manager',
    display_name: 'BM X',
    branch_id: BRANCH_X,
    branch_name: 'Branch X',
    team_id: null,
    team_name: null,
    mfa_verified: true,
    permissions: ['org.view', 'staff.view', 'staff.manage', 'member_pii.view'],
  },
  [USERS.staff.id]: {
    user_id: USERS.staff.id,
    role: 'staff',
    display_name: 'Staff Y',
    branch_id: '0000000b-0000-0000-0000-00000000000b',
    branch_name: 'Branch Y',
    team_id: null,
    team_name: null,
    mfa_verified: true,
    permissions: ['moderation.manage', 'member_pii.view'],
  },
};
const STAFF_ROWS = [
  {
    id: 's1', user_id: USERS.manager.id, role: 'branch_manager', display_name: 'BM X', work_email: null,
    status: 'active', created_at: '2026-11-06T00:00:00Z', branch_id: BRANCH_X, team_id: null,
    branch: { code: 'BRX', name: 'Branch X' }, team: null,
  },
];

function json(status: number, body: unknown) {
  return new Response(JSON.stringify(body), { status, headers: { 'Content-Type': 'application/json' } });
}

type Rest = (url: string, init: RequestInit, user: { id: string }) => Response;
let rest: Rest;
let auditResponse: () => Response;
const calls: { url: string; init: RequestInit }[] = [];

/** Supabase stand-in: Auth accepts the tokens in VALID; REST answers as that user. */
function supabase(url: string, init: RequestInit): Response {
  const auth = (init.headers as Record<string, string>).Authorization ?? '';
  const user = VALID.get(auth.replace('Bearer ', ''));
  if (url.endsWith('/auth/v1/user')) return user ? json(200, user) : json(401, { msg: 'bad token' });
  if (!user) return json(401, { message: 'JWT invalid' });
  if (url.endsWith('/rest/v1/rpc/current_staff_profile')) return json(200, PROFILES[user.id] ?? null);
  if (url.endsWith('/rest/v1/rpc/log_audit')) return auditResponse();
  return rest(url, init, user);
}

describe('Admin API', () => {
  let app: INestApplication;
  const get = (path: string, t?: string) => {
    const r = request(app.getHttpServer()).get(path);
    return t ? r.set('Authorization', `Bearer ${t}`) : r;
  };

  beforeAll(async () => {
    global.fetch = jest.fn(async (input: string | URL | Request, init?: RequestInit) => {
      const url = String(input);
      calls.push({ url, init: init ?? {} });
      return supabase(url, init ?? {});
    }) as typeof fetch;
    const mod = await Test.createTestingModule({ imports: [AppModule.forRoot(config)] }).compile();
    app = mod.createNestApplication();
    configureApp(app, config);
    await app.init();
  });
  afterAll(() => app.close());
  beforeEach(() => {
    calls.length = 0;
    rest = () => json(500, { message: 'unexpected call' });
    auditResponse = () => json(200, 1);
  });

  it('rejects requests without a token', async () => {
    const res = await get('/admin/v1/me').expect(401);
    expect(res.body.code).toBe('NO_TOKEN');
  });

  it('rejects a token Supabase does not accept', async () => {
    const res = await get('/admin/v1/me', token(USERS.manager.id, 'aal2') + 'x').expect(401);
    expect(res.body.code).toBe('INVALID_TOKEN');
  });

  it('requires an MFA-verified session (aal2) before looking up staff status', async () => {
    const res = await get('/admin/v1/me', TOKENS.managerAal1).expect(403);
    expect(res.body.code).toBe('MFA_REQUIRED');
    expect(calls.some((c) => c.url.includes('/rest/v1/'))).toBe(false);
  });

  it('refuses members (no staff account)', async () => {
    const res = await get('/admin/v1/me', TOKENS.memberAal2).expect(403);
    expect(res.body.code).toBe('NOT_STAFF');
  });

  it("GET /admin/v1/me returns role, branch and permissions, asked as the staff member", async () => {
    const res = await get('/admin/v1/me', TOKENS.managerAal2).expect(200);
    expect(res.body).toEqual({
      userId: USERS.manager.id,
      email: 'bm.x@example.com',
      displayName: 'BM X',
      role: 'branch_manager',
      branch: { id: BRANCH_X, name: 'Branch X' },
      team: null,
      permissions: ['org.view', 'staff.view', 'staff.manage', 'member_pii.view'],
    });
    const rpc = calls.find((c) => c.url.endsWith('/rpc/current_staff_profile'))!;
    const headers = rpc.init.headers as Record<string, string>;
    expect(headers.Authorization).toBe(`Bearer ${TOKENS.managerAal2}`); // row-level security applies
    expect(headers.apikey).toBe('sb_publishable_test'); // never a secret key
  });

  it('GET /admin/v1/staff needs the staff.view permission', async () => {
    const res = await get('/admin/v1/staff', TOKENS.staffAal2).expect(403);
    expect(res.body.code).toBe('FORBIDDEN');
    expect(calls.some((c) => c.url.includes('/rest/v1/staff_accounts'))).toBe(false);
  });

  it('GET /admin/v1/staff lists staff in scope and writes an audit entry', async () => {
    rest = (url, init) => {
      expect(url).toContain('/rest/v1/staff_accounts?select=');
      expect((init.headers as Record<string, string>).Authorization).toBe(`Bearer ${TOKENS.managerAal2}`);
      return json(200, STAFF_ROWS);
    };
    const res = await get('/admin/v1/staff', TOKENS.managerAal2).expect(200);
    expect(res.body).toEqual([
      {
        id: 's1',
        userId: USERS.manager.id,
        displayName: 'BM X',
        workEmail: null,
        role: 'branch_manager',
        status: 'active',
        createdAt: '2026-11-06T00:00:00Z',
        branch: { id: BRANCH_X, code: 'BRX', name: 'Branch X' },
        team: null,
      },
    ]);
    const audit = calls.find((c) => c.url.endsWith('/rpc/log_audit'))!;
    expect(audit).toBeDefined();
    const body = JSON.parse(String(audit.init.body));
    expect(body).toMatchObject({ p_action: 'staff.list', p_entity: 'staff_accounts', p_after: { via: 'admin-api', count: 1 } });
    expect((audit.init.headers as Record<string, string>).Authorization).toBe(`Bearer ${TOKENS.managerAal2}`);
  });

  it('returns nothing when the audit entry cannot be written', async () => {
    rest = () => json(200, STAFF_ROWS);
    auditResponse = () => json(403, { code: '42501', message: 'MFA_REQUIRED' });
    const res = await get('/admin/v1/staff', TOKENS.managerAal2).expect(503);
    expect(res.body.code).toBe('AUDIT_UNAVAILABLE');
    expect(JSON.stringify(res.body)).not.toContain('BM X');
  });

  it('the admin endpoints are in the OpenAPI description', async () => {
    const res = await get('/docs/openapi.json').expect(200);
    expect(Object.keys(res.body.paths)).toEqual(expect.arrayContaining(['/admin/v1/me', '/admin/v1/staff']));
  });
});
