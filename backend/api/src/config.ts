/** Settings read from the environment. Only public values are needed today. */
export interface ApiConfig {
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
  const jwtIssuer = env.JWT_ISSUER ?? `${supabaseUrl}/auth/v1`;
  return {
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
