import { Controller, Get, NotFoundException, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiOkResponse, ApiTags } from '@nestjs/swagger';
import { Member, MemberContext, SupabaseAuthGuard } from '../auth/auth.guard';
import { Database } from '../db/database';

const ME_SQL = `select id, profile_id, name, gender, date_of_birth, city, is_verified, is_profile_complete
  from public.matrimonial_profiles
  where auth_user_id = $1::uuid
  limit 1`;

@ApiTags('members')
@ApiBearerAuth()
@UseGuards(SupabaseAuthGuard)
@Controller('v1/me')
export class MeController {
  constructor(private readonly db: Database) {}

  @Get()
  @ApiOkResponse({ description: "The signed-in member's profile summary and email" })
  async me(@Member() m: MemberContext) {
    const rows = await this.db.asUser(m.user, (q) => q.query(ME_SQL, [m.user.id]));
    if (!rows.length) {
      throw new NotFoundException({ code: 'NO_PROFILE', message: 'No profile yet' });
    }
    return { email: m.user.email ?? null, profile: rows[0] };
  }
}
