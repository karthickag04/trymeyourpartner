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

  beforeAll(async () => {
    global.fetch = jest.fn(async (input: string | URL | Request, init?: RequestInit) => {
      const url = String(input);
      calls.push({ url, init: init ?? {} });
      return handler(url, init ?? {});
    }) as typeof fetch;
    const mod = await Test.createTestingModule({ imports: [AppModule.forRoot(config)] }).compile();
    app = mod.createNestApplication();
    configureApp(app, config);
    await app.init();
  });
  afterAll(() => app.close());
  beforeEach(() => {
    calls.length = 0;
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

  it("GET /v1/me returns the member's profile, queried with the member's own token", async () => {
    handler = supabase((url) =>
      url.includes('/rest/v1/matrimonial_profiles') ? json(200, [{ id: 'p1', name: 'A' }]) : json(500, {}),
    );
    const res = await request(app.getHttpServer())
      .get('/v1/me')
      .set('Authorization', 'Bearer good-token')
      .expect(200);
    expect(res.body).toEqual({ email: 'a@example.com', profile: { id: 'p1', name: 'A' } });
    const rest = calls.find((c) => c.url.includes('/rest/v1/'))!;
    expect(rest.url).toContain(`auth_user_id=eq.${MEMBER.id}`);
    const headers = rest.init.headers as Record<string, string>;
    expect(headers.Authorization).toBe('Bearer good-token'); // row-level security applies
    expect(headers.apikey).toBe('sb_publishable_test'); // never a secret key
  });

  it('GET /v1/me says when there is no profile yet', async () => {
    handler = supabase(() => json(200, []));
    const res = await request(app.getHttpServer())
      .get('/v1/me')
      .set('Authorization', 'Bearer good-token')
      .expect(404);
    expect(res.body.code).toBe('NO_PROFILE');
  });

  it('contact reveal returns the numbers from the reveal_contact function', async () => {
    handler = supabase((url, init) => {
      expect(url).toMatch(/\/rest\/v1\/rpc\/reveal_contact$/);
      expect(JSON.parse(String(init.body))).toEqual({ p_target_profile_id: TARGET });
      return json(200, { phone_number: '900', whatsapp_number: '901' });
    });
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
    handler = supabase(() => json(400, { code: 'P0001', message: code }));
    const res = await request(app.getHttpServer())
      .post(`/v1/profiles/${TARGET}/contact-reveal`)
      .set('Authorization', 'Bearer good-token')
      .expect(status);
    expect(res.body.code).toBe(code);
  });

  it('contact reveal rejects a malformed profile id before calling Supabase', async () => {
    await request(app.getHttpServer())
      .post('/v1/profiles/not-a-uuid/contact-reveal')
      .set('Authorization', 'Bearer good-token')
      .expect(400);
    expect(calls.some((c) => c.url.includes('/rpc/'))).toBe(false);
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
});
