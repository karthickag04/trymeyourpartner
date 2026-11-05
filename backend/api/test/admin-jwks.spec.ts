import 'reflect-metadata';
import { INestApplication } from '@nestjs/common';
import { Test } from '@nestjs/testing';
import { createLocalJWKSet, exportJWK, generateKeyPair, KeyLike, SignJWT } from 'jose';
import request from 'supertest';
import { AdminController } from '../src/admin/admin.controller';
import { AuditService } from '../src/admin/audit.service';
import { StaffGuard } from '../src/admin/staff.guard';
import { SupabaseAuthGuard } from '../src/auth/auth.guard';
import { JWKS_KEY_SET, TokenVerifier } from '../src/auth/token-verifier';
import { API_CONFIG, loadConfig } from '../src/config';
import { SupabaseClient } from '../src/supabase/supabase.client';

/** The staff guard with provider-neutral token verification (signed JWTs, JWKS). */
describe('Admin API with JWKS-verified tokens', () => {
  const STAFF_ID = '44444444-4444-4444-4444-444444444444';
  let app: INestApplication;
  let key: KeyLike;
  const rpcCalls: string[] = [];

  const sign = (aal: string) =>
    new SignJWT({ aal, email: 'bm.x@example.com', role: 'authenticated' })
      .setProtectedHeader({ alg: 'ES256', kid: 'k1' })
      .setIssuer('https://example.supabase.co/auth/v1')
      .setAudience('authenticated')
      .setSubject(STAFF_ID)
      .setIssuedAt()
      .setExpirationTime('5m')
      .sign(key);

  beforeAll(async () => {
    const pair = await generateKeyPair('ES256');
    key = pair.privateKey;
    const jwk = { ...(await exportJWK(pair.publicKey)), kid: 'k1', alg: 'ES256' };
    const config = loadConfig({
      SUPABASE_URL: 'https://example.supabase.co',
      SUPABASE_PUBLISHABLE_KEY: 'sb_publishable_test',
      TOKEN_VERIFICATION: 'jwks',
    });
    global.fetch = jest.fn(async (input: string | URL | Request) => {
      const url = String(input);
      if (url.includes('/auth/v1/')) throw new Error('the provider must not be called in JWKS mode');
      rpcCalls.push(url);
      return new Response(
        JSON.stringify({
          user_id: STAFF_ID, role: 'admin', display_name: 'Admin', branch_id: null, branch_name: null,
          team_id: null, team_name: null, mfa_verified: true, permissions: ['staff.view'],
        }),
        { status: 200, headers: { 'Content-Type': 'application/json' } },
      );
    }) as typeof fetch;
    const mod = await Test.createTestingModule({
      controllers: [AdminController],
      providers: [
        { provide: API_CONFIG, useValue: config },
        { provide: JWKS_KEY_SET, useValue: createLocalJWKSet({ keys: [jwk] }) },
        SupabaseClient,
        TokenVerifier,
        SupabaseAuthGuard,
        StaffGuard,
        AuditService,
      ],
    }).compile();
    app = mod.createNestApplication();
    await app.init();
  });
  afterAll(() => app.close());
  beforeEach(() => (rpcCalls.length = 0));

  it('reads aal from the verified token: aal1 is refused before any database call', async () => {
    const res = await request(app.getHttpServer())
      .get('/admin/v1/me')
      .set('Authorization', `Bearer ${await sign('aal1')}`)
      .expect(403);
    expect(res.body.code).toBe('MFA_REQUIRED');
    expect(rpcCalls).toEqual([]);
  });

  it('accepts an aal2 token and returns the staff profile', async () => {
    const res = await request(app.getHttpServer())
      .get('/admin/v1/me')
      .set('Authorization', `Bearer ${await sign('aal2')}`)
      .expect(200);
    expect(res.body).toMatchObject({ userId: STAFF_ID, email: 'bm.x@example.com', role: 'admin' });
  });

  it('rejects a token with a forged aal claim (bad signature)', async () => {
    const [h, , s] = (await sign('aal1')).split('.');
    const forged = Buffer.from(JSON.stringify({ sub: STAFF_ID, aal: 'aal2' })).toString('base64url');
    const res = await request(app.getHttpServer())
      .get('/admin/v1/me')
      .set('Authorization', `Bearer ${h}.${forged}.${s}`)
      .expect(401);
    expect(res.body.code).toBe('INVALID_TOKEN');
  });
});
