import { DynamicModule, Global, Module } from '@nestjs/common';
import { API_CONFIG, ApiConfig } from '../config';
import { Database } from './database';
import { PostgresDatabase } from './postgres.database';

/** One connection pool for the whole API, available to every module. */
@Global()
@Module({})
export class DatabaseModule {
  static forRoot(config: ApiConfig): DynamicModule {
    return {
      module: DatabaseModule,
      providers: [
        { provide: API_CONFIG, useValue: config },
        { provide: Database, useClass: PostgresDatabase },
      ],
      exports: [Database],
    };
  }
}
