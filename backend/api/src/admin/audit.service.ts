import { Injectable, ServiceUnavailableException } from '@nestjs/common';
import { SupabaseClient } from '../supabase/supabase.client';
import { StaffContext } from './staff.guard';

export interface AuditEntry {
  action: string;
  entity: string;
  entityId?: string | null;
  reason?: string | null;
  details?: Record<string, unknown>;
}

/**
 * Writes to the append-only audit log through public.log_audit, as the staff
 * member. Call it BEFORE returning member personal data: if the entry cannot
 * be written, the request fails and nothing is returned.
 */
@Injectable()
export class AuditService {
  constructor(private readonly supabase: SupabaseClient) {}

  async log(ctx: StaffContext, entry: AuditEntry): Promise<void> {
    try {
      await this.supabase.rpc<number>(ctx.token, 'log_audit', {
        p_action: entry.action,
        p_entity: entry.entity,
        p_entity_id: entry.entityId ?? null,
        p_before: null,
        p_after: { via: 'admin-api', client_ip: ctx.ip, ...(entry.details ?? {}) },
        p_reason: entry.reason ?? null,
      });
    } catch {
      throw new ServiceUnavailableException({
        code: 'AUDIT_UNAVAILABLE',
        message: 'The audit log could not be written, so the request was not completed',
      });
    }
  }
}
