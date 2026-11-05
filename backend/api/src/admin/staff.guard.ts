import {
  CanActivate,
  ExecutionContext,
  ForbiddenException,
  Injectable,
  SetMetadata,
  UnauthorizedException,
  createParamDecorator,
} from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import { AuthedRequest, SupabaseAuthGuard } from '../auth/auth.guard';
import { SupabaseClient } from '../supabase/supabase.client';

/** What public.current_staff_profile() returns for an active staff member. */
export interface StaffProfile {
  user_id: string;
  role: string;
  display_name: string;
  branch_id: string | null;
  branch_name: string | null;
  team_id: string | null;
  team_name: string | null;
  mfa_verified: boolean;
  permissions: string[];
}

export interface StaffRequest extends AuthedRequest {
  staff?: StaffProfile;
  ip?: string;
}

const PERMISSION_KEY = 'tmyp:permission';

/** Requires the signed-in staff member to hold this permission (see public.permissions). */
export const RequirePermission = (permission: string) => SetMetadata(PERMISSION_KEY, permission);

/**
 * Staff/admin API access:
 *  1. a valid access token (checked by TokenVerifier: JWKS or the auth provider),
 *  2. an MFA-verified session (claim aal = aal2),
 *  3. an active staff account (public.current_staff_profile(), called as the user),
 *  4. the permission named by @RequirePermission, if any.
 * The database applies the same rules again through row-level security.
 */
@Injectable()
export class StaffGuard implements CanActivate {
  constructor(
    private readonly auth: SupabaseAuthGuard,
    private readonly supabase: SupabaseClient,
    private readonly reflector: Reflector,
  ) {}

  async canActivate(context: ExecutionContext): Promise<boolean> {
    await this.auth.canActivate(context);
    const req = context.switchToHttp().getRequest<StaffRequest>();
    const token = req.accessToken;
    if (!token || !req.user) {
      throw new UnauthorizedException({ code: 'NO_TOKEN', message: 'Sign in required' });
    }

    // Provider-neutral: the verified token's claims (TokenVerifier), not a provider user object.
    if (req.user.aal !== 'aal2') {
      throw new ForbiddenException({
        code: 'MFA_REQUIRED',
        message: 'Verify your sign-in with your authenticator app first',
      });
    }

    const staff = await this.supabase.rpc<StaffProfile | null>(token, 'current_staff_profile', {});
    if (!staff?.role) {
      throw new ForbiddenException({ code: 'NOT_STAFF', message: 'This account has no staff access' });
    }
    req.staff = staff;

    const needed = this.reflector.getAllAndOverride<string | undefined>(PERMISSION_KEY, [
      context.getHandler(),
      context.getClass(),
    ]);
    if (needed && !staff.permissions.includes(needed)) {
      throw new ForbiddenException({ code: 'FORBIDDEN', message: `Requires permission ${needed}` });
    }
    return true;
  }
}

/** The signed-in staff member, their token and client IP, for use in controllers. */
export const Staff = createParamDecorator((_: unknown, ctx: ExecutionContext) => {
  const req = ctx.switchToHttp().getRequest<StaffRequest>();
  return { staff: req.staff!, user: req.user!, token: req.accessToken!, ip: req.ip ?? null };
});
export type StaffContext = {
  staff: StaffProfile;
  user: { id: string; email?: string };
  token: string;
  ip: string | null;
};
