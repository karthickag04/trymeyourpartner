import { Controller, Get, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiForbiddenResponse, ApiOkResponse, ApiTags } from '@nestjs/swagger';
import { Database } from '../db/database';
import { AuditService } from './audit.service';
import { RequirePermission, Staff, StaffContext, StaffGuard } from './staff.guard';

interface StaffRow {
  id: string;
  user_id: string;
  role: string;
  display_name: string;
  work_email: string | null;
  status: string;
  created_at: Date | string;
  branch_id: string | null;
  team_id: string | null;
  branch: { code: string; name: string } | null;
  team: { name: string } | null;
}

// Joined rows the caller may not see (row-level security) come back as null.
const STAFF_SQL = `select s.id, s.user_id, s.role, s.display_name, s.work_email, s.status,
       s.created_at, s.branch_id, s.team_id,
       case when b.id is null then null else json_build_object('code', b.code, 'name', b.name) end as branch,
       case when t.id is null then null else json_build_object('name', t.name) end as team
  from public.staff_accounts s
  left join public.branches b on b.id = s.branch_id
  left join public.teams t on t.id = s.team_id
  order by s.display_name asc`;

@ApiTags('admin')
@ApiBearerAuth()
@ApiForbiddenResponse({ description: 'MFA_REQUIRED, NOT_STAFF or FORBIDDEN' })
@UseGuards(StaffGuard)
@Controller('admin/v1')
export class AdminController {
  constructor(
    private readonly db: Database,
    private readonly audit: AuditService,
  ) {}

  @Get('me')
  @ApiOkResponse({ description: "The signed-in staff member's role, branch, team and permissions" })
  me(@Staff() s: StaffContext) {
    return {
      userId: s.staff.user_id,
      email: s.user.email ?? null,
      displayName: s.staff.display_name,
      role: s.staff.role,
      branch: s.staff.branch_id ? { id: s.staff.branch_id, name: s.staff.branch_name } : null,
      team: s.staff.team_id ? { id: s.staff.team_id, name: s.staff.team_name } : null,
      permissions: s.staff.permissions,
    };
  }

  /**
   * Staff accounts in the caller's scope. Scope is decided by the database
   * (row-level security): admins see every branch, a branch manager only
   * their own branch. The view is recorded in the audit log.
   */
  @Get('staff')
  @RequirePermission('staff.view')
  @ApiOkResponse({ description: 'Staff accounts in scope' })
  async staff(@Staff() s: StaffContext) {
    const rows = await this.db.asUser(s.user, (q) => q.query<StaffRow>(STAFF_SQL));
    await this.audit.log(s, {
      action: 'staff.list',
      entity: 'staff_accounts',
      details: { count: rows.length },
    });
    return rows.map((r) => ({
      id: r.id,
      userId: r.user_id,
      displayName: r.display_name,
      workEmail: r.work_email,
      role: r.role,
      status: r.status,
      createdAt: r.created_at,
      branch: r.branch_id ? { id: r.branch_id, code: r.branch?.code ?? null, name: r.branch?.name ?? null } : null,
      team: r.team_id ? { id: r.team_id, name: r.team?.name ?? null } : null,
    }));
  }
}
