import 'reflect-metadata';
import { INestApplication } from '@nestjs/common';
import { Test } from '@nestjs/testing';
import request from 'supertest';
import { AppModule } from '../src/app.module';
import { ApiConfig, loadConfig } from '../src/config';
import { Database, DatabaseError } from '../src/db/database';
import { configureApp } from '../src/setup';
import { FakeDatabase } from './helpers/fake-database';

const config: ApiConfig = loadConfig({
  SUPABASE_URL: 'https://example.supabase.co/',
  SUPABASE_PUBLISHABLE_KEY: 'sb_publishable_test',
  DATABASE_URL: 'postgres://api_service@localhost:5432/unused',
});

const MEMBER = { id: '11111111-1111-1111-1111-111111111111', email: 'a@example.com' };
const TARGET = '22222222-2222-2222-2222-222222222222';

type Handler = (url: string, init: RequestInit) => Response;
let handler: Handler;
const calls: { url: string; init: RequestInit }[] = [];

function json(status: number, body: unknown) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { 'Content-Type': 'application/json' },
  });
}

/** Supabase stand-in: a valid token is "good-token". */
function supabase(rest: (url: string, init: RequestInit) => Response): Handler {
  return (url, init) => {
    const auth = (init.headers as Record<string, string>).Authorization;
    if (url.endsWith('/auth/v1/user')) {
      return auth === 'Bearer good-token' ? json(200, MEMBER) : json(401, { msg: 'bad token' });
    }
    return rest(url, init);
  };
}

describe('API', () => {
  let app: INestApplication;
  const db = new FakeDatabase();

  beforeAll(async () => {
    global.fetch = jest.fn(async (input: string | URL | Request, init?: RequestInit) => {
      const url = String(input);
      calls.push({ url, init: init ?? {} });
      return handler(url, init ?? {});
    }) as typeof fetch;
    const mod = await Test.createTestingModule({ imports: [AppModule.forRoot(config)] })
      .overrideProvider(Database)
      .useValue(db)
      .compile();
    app = mod.createNestApplication();
    configureApp(app, config);
    await app.init();
  });
  afterAll(() => app.close());
  beforeEach(() => {
    calls.length = 0;
    db.reset();
    handler = supabase(() => json(500, { message: 'unexpected call' }));
  });

  it('GET /health works without signing in', async () => {
    await request(app.getHttpServer()).get('/health').expect(200, { status: 'ok' });
  });

  it('rejects requests without a token', async () => {
    const res = await request(app.getHttpServer()).get('/v1/me').expect(401);
    expect(res.body.code).toBe('NO_TOKEN');
  });

  it('rejects an invalid token', async () => {
    const res = await request(app.getHttpServer())
      .get('/v1/me')
      .set('Authorization', 'Bearer forged')
      .expect(401);
    expect(res.body.code).toBe('INVALID_TOKEN');
  });

  it("GET /v1/me returns the member's profile, queried as the member", async () => {
    db.handler = (sql) => (sql.includes('from public.matrimonial_profiles') ? [{ id: 'p1', name: 'A' }] : []);
    const res = await request(app.getHttpServer())
      .get('/v1/me')
      .set('Authorization', 'Bearer good-token')
      .expect(200);
    expect(res.body).toEqual({ email: 'a@example.com', profile: { id: 'p1', name: 'A' } });
    expect(db.calls).toHaveLength(1);
    expect(db.calls[0].params).toEqual([MEMBER.id]);
    expect(db.calls[0].user.id).toBe(MEMBER.id); // row-level security applies to this member
    expect(calls.some((c) => c.url.includes('/rest/v1/'))).toBe(false); // no Supabase REST
  });

  it('GET /v1/me says when there is no profile yet', async () => {
    db.handler = () => [];
    const res = await request(app.getHttpServer())
      .get('/v1/me')
      .set('Authorization', 'Bearer good-token')
      .expect(404);
    expect(res.body.code).toBe('NO_PROFILE');
  });

  it('contact reveal returns the numbers from the reveal_contact function', async () => {
    db.handler = (sql, params) => {
      expect(sql).toContain('public.reveal_contact($1::uuid)');
      expect(params).toEqual([TARGET]);
      return [{ r: { phone_number: '900', whatsapp_number: '901' } }];
    };
    const res = await request(app.getHttpServer())
      .post(`/v1/profiles/${TARGET}/contact-reveal`)
      .set('Authorization', 'Bearer good-token')
      .expect(200);
    expect(res.body).toEqual({ phoneNumber: '900', whatsappNumber: '901' });
  });

  it.each([
    ['CONTACT_LIMIT_REACHED', 403],
    ['PROFILE_NOT_AVAILABLE', 404],
    ['CANNOT_REVEAL_SELF', 400],
  ])('contact reveal maps %s to HTTP %i', async (code, status) => {
    db.handler = () => {
      throw new DatabaseError(code, 'P0001');
    };
    const res = await request(app.getHttpServer())
      .post(`/v1/profiles/${TARGET}/contact-reveal`)
      .set('Authorization', 'Bearer good-token')
      .expect(status);
    expect(res.body.code).toBe(code);
  });

  it('contact reveal rejects a malformed profile id before calling the database', async () => {
    await request(app.getHttpServer())
      .post('/v1/profiles/not-a-uuid/contact-reveal')
      .set('Authorization', 'Bearer good-token')
      .expect(400);
    expect(db.calls).toEqual([]);
  });

  it('serves the OpenAPI description', async () => {
    const res = await request(app.getHttpServer()).get('/docs/openapi.json').expect(200);
    expect(Object.keys(res.body.paths)).toEqual(
      expect.arrayContaining(['/health', '/v1/me', '/v1/profiles/{profileId}/contact-reveal']),
    );
  });
});

describe('config', () => {
  it('requires the Supabase URL and publishable key', () => {
    expect(() => loadConfig({})).toThrow(/SUPABASE_URL/);
  });

  it('requires a database connection and a plain member role name', () => {
    const base = { SUPABASE_URL: 'https://x.supabase.co', SUPABASE_PUBLISHABLE_KEY: 'k' };
    expect(() => loadConfig(base)).toThrow(/DATABASE_URL/);
    const withDb = { ...base, DATABASE_URL: 'postgres://u@h/db' };
    expect(loadConfig(withDb).databaseMemberRole).toBe('authenticated');
    expect(() => loadConfig({ ...withDb, DATABASE_MEMBER_ROLE: 'x; drop table y' })).toThrow(/plain role name/);
    expect(() => loadConfig({ ...withDb, DATABASE_POOL_SIZE: '0' })).toThrow(/POOL_SIZE/);
  });
});
