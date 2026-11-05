import { DynamicModule, Module } from '@nestjs/common';
import { SupabaseAuthGuard } from '../auth/auth.guard';
import { API_CONFIG, ApiConfig } from '../config';
import { SupabaseClient } from '../supabase/supabase.client';
import { AdminController } from './admin.controller';
import { AuditService } from './audit.service';
import { StaffGuard } from './staff.guard';

/** Staff/admin API (/admin/v1): MFA-verified staff only; see docs/ADMIN_CONSOLE.md. */
@Module({})
export class AdminModule {
  static forRoot(config: ApiConfig): DynamicModule {
    return {
      module: AdminModule,
      controllers: [AdminController],
      providers: [
        { provide: API_CONFIG, useValue: config },
        SupabaseClient,
        SupabaseAuthGuard,
        StaffGuard,
        AuditService,
      ],
    };
  }
}
