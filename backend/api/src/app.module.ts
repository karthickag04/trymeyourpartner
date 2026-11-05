import { DynamicModule, Module } from '@nestjs/common';
import { AdminModule } from './admin/admin.module';
import { SupabaseAuthGuard } from './auth/auth.guard';
import { TokenVerifier } from './auth/token-verifier';
import { API_CONFIG, ApiConfig } from './config';
import { ContactsController } from './contacts/contacts.controller';
import { HealthController } from './health/health.controller';
import { MeController } from './members/me.controller';
import { SupabaseClient } from './supabase/supabase.client';

@Module({})
export class AppModule {
  static forRoot(config: ApiConfig): DynamicModule {
    return {
      module: AppModule,
      imports: [AdminModule.forRoot(config)],
      controllers: [HealthController, MeController, ContactsController],
      providers: [
        { provide: API_CONFIG, useValue: config },
        SupabaseClient,
        TokenVerifier,
        SupabaseAuthGuard,
      ],
    };
  }
}
