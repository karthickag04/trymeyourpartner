import {
  BadRequestException,
  Controller,
  ForbiddenException,
  HttpCode,
  NotFoundException,
  Param,
  ParseUUIDPipe,
  Post,
  UseGuards,
} from '@nestjs/common';
import { ApiBearerAuth, ApiOkResponse, ApiTags } from '@nestjs/swagger';
import { Member, MemberContext, SupabaseAuthGuard } from '../auth/auth.guard';
import { SupabaseClient, SupabaseError } from '../supabase/supabase.client';

interface RevealedContact {
  phone_number: string | null;
  whatsapp_number: string | null;
}

@ApiTags('contacts')
@ApiBearerAuth()
@UseGuards(SupabaseAuthGuard)
@Controller('v1/profiles')
export class ContactsController {
  constructor(private readonly supabase: SupabaseClient) {}

  /**
   * Reveals another member's phone numbers. The database decides: plan quota,
   * blocks and profile status (see reveal_contact in supabase/migrations).
   */
  @Post(':profileId/contact-reveal')
  @HttpCode(200)
  @ApiOkResponse({ description: 'Phone and WhatsApp numbers (never the address)' })
  async reveal(
    @Member() m: MemberContext,
    @Param('profileId', new ParseUUIDPipe()) profileId: string,
  ) {
    try {
      const r = await this.supabase.rpc<RevealedContact>(m.token, 'reveal_contact', {
        p_target_profile_id: profileId,
      });
      return {
        phoneNumber: r?.phone_number ?? null,
        whatsappNumber: r?.whatsapp_number ?? null,
      };
    } catch (e) {
      const code = e instanceof SupabaseError ? e.message : '';
      if (code.includes('CONTACT_LIMIT_REACHED'))
        throw new ForbiddenException({ code: 'CONTACT_LIMIT_REACHED', message: 'Contact reveal limit reached for your plan' });
      if (code.includes('PROFILE_NOT_AVAILABLE'))
        throw new NotFoundException({ code: 'PROFILE_NOT_AVAILABLE', message: 'This profile is not available' });
      if (code.includes('CANNOT_REVEAL_SELF'))
        throw new BadRequestException({ code: 'CANNOT_REVEAL_SELF', message: 'You cannot reveal your own contact' });
      if (code.includes('NO_PROFILE'))
        throw new NotFoundException({ code: 'NO_PROFILE', message: 'Create your profile first' });
      throw e;
    }
  }
}
