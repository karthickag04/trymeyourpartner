import { Inject, Injectable, Optional } from '@nestjs/common';
import { createRemoteJWKSet, JWTPayload, jwtVerify, JWTVerifyGetKey } from 'jose';

/** Optional override of where public keys come from (tests use a local set). */
export const JWKS_KEY_SET = Symbol('JWKS_KEY_SET');
import { API_CONFIG, ApiConfig } from '../config';
import { SupabaseClient } from '../supabase/supabase.client';

/** The signed-in user, as the API sees it (provider-neutral). */
export interface VerifiedUser {
  id: string;
  email?: string;
  /** Authentication assurance level, e.g. "aal2" after MFA. */
  aal?: string;
  claims: Record<string, unknown>;
}

/**
 * Verifies access tokens (docs/adr/0001-vendor-portability.md, P1-17).
 *
 * - "jwks": checks the signature against the issuer's public keys (JWKS) plus
 *   issuer, audience and expiry. Works with any OIDC provider; no network call
 *   per request after the keys are cached.
 * - "provider": asks the auth provider (today Supabase /auth/v1/user). Needed
 *   while a project still signs tokens with a shared secret.
 * - "auto" (default): JWKS when the issuer publishes keys, otherwise provider.
 */
@Injectable()
export class TokenVerifier {
  private jwks?: JWTVerifyGetKey;
  private jwksAvailable?: { value: boolean; until: number };

  constructor(
    @Inject(API_CONFIG) private readonly config: ApiConfig,
    private readonly supabase: SupabaseClient,
    @Optional() @Inject(JWKS_KEY_SET) keySet?: JWTVerifyGetKey,
  ) {
    this.jwks = keySet;
  }

  async verify(token: string): Promise<VerifiedUser | null> {
    const mode = this.config.tokenVerification;
    if (mode === 'jwks' || (mode === 'auto' && (await this.issuerPublishesKeys()))) {
      return this.verifyWithJwks(token);
    }
    const user = await this.supabase.getUser(token);
    if (!user) return null;
    // The provider confirmed the token; read the remaining claims from it.
    const claims = decodeClaims(token);
    return { id: user.id, email: user.email, aal: claims.aal as string | undefined, claims };
  }

  private async verifyWithJwks(token: string): Promise<VerifiedUser | null> {
    this.jwks ??= createRemoteJWKSet(new URL(this.config.jwksUrl));
    try {
      const { payload } = await jwtVerify(token, this.jwks, {
        issuer: this.config.jwtIssuer,
        audience: this.config.jwtAudience,
      });
      return toUser(payload);
    } catch {
      return null;
    }
  }

  /** Cached for 10 minutes so "auto" switches over soon after keys appear. */
  private async issuerPublishesKeys(): Promise<boolean> {
    const now = Date.now();
    if (this.jwksAvailable && this.jwksAvailable.until > now) return this.jwksAvailable.value;
    let value = false;
    try {
      const res = await fetch(this.config.jwksUrl, {
        headers: { apikey: this.config.supabasePublishableKey },
      });
      if (res.ok) {
        const body = (await res.json()) as { keys?: unknown[] };
        value = Array.isArray(body.keys) && body.keys.length > 0;
      }
    } catch {
      value = false;
    }
    this.jwksAvailable = { value, until: now + 10 * 60_000 };
    return value;
  }
}

function toUser(payload: JWTPayload): VerifiedUser | null {
  if (!payload.sub) return null;
  return {
    id: payload.sub,
    email: typeof payload.email === 'string' ? payload.email : undefined,
    aal: typeof payload.aal === 'string' ? payload.aal : undefined,
    claims: payload as Record<string, unknown>,
  };
}

/** Reads claims without verifying; only used after the provider verified the token. */
function decodeClaims(token: string): Record<string, unknown> {
  try {
    const part = token.split('.')[1] ?? '';
    return JSON.parse(Buffer.from(part, 'base64url').toString('utf8')) as Record<string, unknown>;
  } catch {
    return {};
  }
}
