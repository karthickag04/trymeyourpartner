import { Controller, Get, NotFoundException, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiOkResponse, ApiTags } from '@nestjs/swagger';
import { Member, MemberContext, SupabaseAuthGuard } from '../auth/auth.guard';
import { SupabaseClient } from '../supabase/supabase.client';

const ME_COLUMNS =
  'id,profile_id,name,gender,date_of_birth,city,is_verified,is_profile_complete';

@ApiTags('members')
@ApiBearerAuth()
@UseGuards(SupabaseAuthGuard)
@Controller('v1/me')
export class MeController {
  constructor(private readonly supabase: SupabaseClient) {}

  @Get()
  @ApiOkResponse({ description: "The signed-in member's profile summary and email" })
  async me(@Member() m: MemberContext) {
    const rows = await this.supabase.select<Record<string, unknown>[]>(
      m.token,
      `matrimonial_profiles?auth_user_id=eq.${encodeURIComponent(m.user.id)}&select=${ME_COLUMNS}&limit=1`,
    );
    if (!rows.length) {
      throw new NotFoundException({ code: 'NO_PROFILE', message: 'No profile yet' });
    }
    return { email: m.user.email ?? null, profile: rows[0] };
  }
}
