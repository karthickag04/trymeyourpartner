/** Settings read from the environment. */
export interface ApiConfig {
  /** postgres://api_service:<password>@<host>:<port>/postgres (a secret; never commit it). */
  databaseUrl: string;
  /** Connections kept open by this API instance. */
  databasePoolSize: number;
  /** The role requests run as, so row-level security applies (Supabase: authenticated). */
  databaseMemberRole: string;
  /** e.g. https://<project-ref>.supabase.co */
  supabaseUrl: string;
  /** The publishable key (sb_publishable_...). Never the secret key. */
  supabasePublishableKey: string;
  port: number;
  /** Comma-separated origins allowed to call the API from a browser. */
  corsOrigins: string[];
  /** How access tokens are verified: auto | jwks | provider (see TokenVerifier). */
  tokenVerification: 'auto' | 'jwks' | 'provider';
  /** Expected token issuer; defaults to Supabase Auth's issuer. */
  jwtIssuer: string;
  /** Expected token audience. */
  jwtAudience: string;
  /** Where the issuer publishes its public keys. */
  jwksUrl: string;
}

export const API_CONFIG = Symbol('API_CONFIG');

export function loadConfig(env: NodeJS.ProcessEnv = process.env): ApiConfig {
  const supabaseUrl = env.SUPABASE_URL?.replace(/\/+$/, '');
  const supabasePublishableKey = env.SUPABASE_PUBLISHABLE_KEY;
  if (!supabaseUrl || !supabasePublishableKey) {
    throw new Error(
      'SUPABASE_URL and SUPABASE_PUBLISHABLE_KEY must be set (see backend/api/.env.example)',
    );
  }
  const mode = (env.TOKEN_VERIFICATION ?? 'auto').toLowerCase();
  if (!['auto', 'jwks', 'provider'].includes(mode)) {
    throw new Error('TOKEN_VERIFICATION must be auto, jwks or provider');
  }
  const databaseUrl = env.DATABASE_URL;
  if (!databaseUrl) {
    throw new Error('DATABASE_URL must be set (see backend/api/.env.example)');
  }
  const databaseMemberRole = env.DATABASE_MEMBER_ROLE ?? 'authenticated';
  if (!/^[a-z_][a-z0-9_]*$/.test(databaseMemberRole)) {
    throw new Error('DATABASE_MEMBER_ROLE must be a plain role name');
  }
  const databasePoolSize = Number(env.DATABASE_POOL_SIZE ?? 5);
  if (!Number.isInteger(databasePoolSize) || databasePoolSize < 1) {
    throw new Error('DATABASE_POOL_SIZE must be a positive whole number');
  }
  const jwtIssuer = env.JWT_ISSUER ?? `${supabaseUrl}/auth/v1`;
  return {
    databaseUrl,
    databasePoolSize,
    databaseMemberRole,
    tokenVerification: mode as ApiConfig['tokenVerification'],
    jwtIssuer,
    jwtAudience: env.JWT_AUDIENCE ?? 'authenticated',
    jwksUrl: env.JWKS_URL ?? `${jwtIssuer}/.well-known/jwks.json`,
    supabaseUrl,
    supabasePublishableKey,
    port: Number(env.PORT ?? 8080),
    corsOrigins: (env.CORS_ORIGINS ?? '')
      .split(',')
      .map((s) => s.trim())
      .filter(Boolean),
  };
}
