import { DynamicModule, Module } from '@nestjs/common';
import { SupabaseAuthGuard } from './auth/auth.guard';
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
      controllers: [HealthController, MeController, ContactsController],
      providers: [
        { provide: API_CONFIG, useValue: config },
        SupabaseClient,
        SupabaseAuthGuard,
      ],
    };
  }
}
