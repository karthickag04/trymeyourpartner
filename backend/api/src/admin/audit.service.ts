import { Injectable, ServiceUnavailableException } from '@nestjs/common';
import { Database } from '../db/database';
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
  constructor(private readonly db: Database) {}

  async log(ctx: StaffContext, entry: AuditEntry): Promise<void> {
    try {
      await this.db.asUser(ctx.user, (q) =>
        q.query('select public.log_audit($1, $2, $3, $4::jsonb, $5::jsonb, $6)', [
          entry.action,
          entry.entity,
          entry.entityId ?? null,
          null,
          JSON.stringify({ via: 'admin-api', client_ip: ctx.ip, ...(entry.details ?? {}) }),
          entry.reason ?? null,
        ]),
      );
    } catch {
      throw new ServiceUnavailableException({
        code: 'AUDIT_UNAVAILABLE',
        message: 'The audit log could not be written, so the request was not completed',
      });
    }
  }
}
