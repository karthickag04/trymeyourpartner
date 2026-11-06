import 'reflect-metadata';
import { createLocalJWKSet, exportJWK, generateKeyPair, SignJWT, KeyLike } from 'jose';
import { loadConfig } from '../src/config';
import { TokenVerifier } from '../src/auth/token-verifier';
import { SupabaseClient } from '../src/supabase/supabase.client';

const ISSUER = 'https://example.supabase.co/auth/v1';

describe('TokenVerifier with JWKS (provider-neutral)', () => {
  let privateKey: KeyLike;
  let otherKey: KeyLike;
  let verifier: TokenVerifier;
  const supabase = { getUser: jest.fn() } as unknown as SupabaseClient;

  beforeAll(async () => {
    const pair = await generateKeyPair('ES256');
    privateKey = pair.privateKey;
    otherKey = (await generateKeyPair('ES256')).privateKey;
    const jwk = { ...(await exportJWK(pair.publicKey)), kid: 'k1', alg: 'ES256' };
    const config = loadConfig({
      SUPABASE_URL: 'https://example.supabase.co',
      SUPABASE_PUBLISHABLE_KEY: 'sb_publishable_test',
      DATABASE_URL: 'postgres://u@localhost/unused',
      TOKEN_VERIFICATION: 'jwks',
    });
    verifier = new TokenVerifier(config, supabase, createLocalJWKSet({ keys: [jwk] }));
  });

  const sign = (claims: Record<string, unknown>, opts: { key?: KeyLike; iss?: string; aud?: string; exp?: string } = {}) =>
    new SignJWT(claims)
      .setProtectedHeader({ alg: 'ES256', kid: 'k1' })
      .setIssuer(opts.iss ?? ISSUER)
      .setAudience(opts.aud ?? 'authenticated')
      .setSubject('user-1')
      .setIssuedAt()
      .setExpirationTime(opts.exp ?? '5m')
      .sign(opts.key ?? privateKey);

  it('accepts a valid token and reads sub, email and aal', async () => {
    const user = await verifier.verify(await sign({ email: 'a@example.com', aal: 'aal2' }));
    expect(user).toMatchObject({ id: 'user-1', email: 'a@example.com', aal: 'aal2' });
    expect(supabase.getUser).not.toHaveBeenCalled(); // no call to the provider
  });

  it('rejects a token signed with another key', async () => {
    expect(await verifier.verify(await sign({}, { key: otherKey }))).toBeNull();
  });

  it('rejects the wrong issuer', async () => {
    expect(await verifier.verify(await sign({}, { iss: 'https://evil.example/auth/v1' }))).toBeNull();
  });

  it('rejects the wrong audience', async () => {
    expect(await verifier.verify(await sign({}, { aud: 'someone-else' }))).toBeNull();
  });

  it('rejects an expired token', async () => {
    expect(await verifier.verify(await sign({}, { exp: '-1m' }))).toBeNull();
  });

  it('rejects garbage', async () => {
    expect(await verifier.verify('not-a-token')).toBeNull();
  });
});

describe('config', () => {
  it('defaults the issuer and key URL to Supabase Auth, overridable for another provider', () => {
    const base = {
      SUPABASE_URL: 'https://x.supabase.co',
      SUPABASE_PUBLISHABLE_KEY: 'k',
      DATABASE_URL: 'postgres://u@localhost/unused',
    };
    expect(loadConfig(base)).toMatchObject({
      tokenVerification: 'auto',
      jwtIssuer: 'https://x.supabase.co/auth/v1',
      jwksUrl: 'https://x.supabase.co/auth/v1/.well-known/jwks.json',
    });
    expect(
      loadConfig({ ...base, JWT_ISSUER: 'https://login.example.com', TOKEN_VERIFICATION: 'jwks' }),
    ).toMatchObject({ jwtIssuer: 'https://login.example.com', jwksUrl: 'https://login.example.com/.well-known/jwks.json' });
    expect(() => loadConfig({ ...base, TOKEN_VERIFICATION: 'maybe' })).toThrow();
  });
});
