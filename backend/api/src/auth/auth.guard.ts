import {
  CanActivate,
  ExecutionContext,
  Injectable,
  UnauthorizedException,
  createParamDecorator,
} from '@nestjs/common';
import { createHash } from 'node:crypto';
import { SupabaseClient, SupabaseUser } from '../supabase/supabase.client';

export interface AuthedRequest {
  headers: Record<string, string | string[] | undefined>;
  user?: SupabaseUser;
  accessToken?: string;
}

const CACHE_MS = 60_000;

/**
 * Accepts the member's existing Supabase access token (Authorization: Bearer).
 * The token is checked with Supabase Auth; results are cached briefly.
 */
@Injectable()
export class SupabaseAuthGuard implements CanActivate {
  private readonly cache = new Map<string, { user: SupabaseUser; until: number }>();

  constructor(private readonly supabase: SupabaseClient) {}

  async canActivate(context: ExecutionContext): Promise<boolean> {
    const req = context.switchToHttp().getRequest<AuthedRequest>();
    const header = req.headers['authorization'];
    const value = Array.isArray(header) ? header[0] : header;
    const token = value?.startsWith('Bearer ') ? value.slice(7).trim() : '';
    if (!token) throw new UnauthorizedException({ code: 'NO_TOKEN', message: 'Sign in required' });

    const key = createHash('sha256').update(token).digest('hex');
    const cached = this.cache.get(key);
    let user = cached && cached.until > Date.now() ? cached.user : null;
    if (!user) {
      user = await this.supabase.getUser(token);
      if (!user) throw new UnauthorizedException({ code: 'INVALID_TOKEN', message: 'Sign in required' });
      this.cache.set(key, { user, until: Date.now() + CACHE_MS });
      if (this.cache.size > 10_000) this.cache.clear();
    }
    req.user = user;
    req.accessToken = token;
    return true;
  }
}

/** The signed-in member and their token, for use in controllers. */
export const Member = createParamDecorator(
  (_: unknown, ctx: ExecutionContext) => {
    const req = ctx.switchToHttp().getRequest<AuthedRequest>();
    return { user: req.user!, token: req.accessToken! };
  },
);
export type MemberContext = { user: SupabaseUser; token: string };
