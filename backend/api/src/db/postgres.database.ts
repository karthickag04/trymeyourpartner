import { Inject, Injectable, OnModuleDestroy } from '@nestjs/common';
import { DatabaseError as PgError, Pool, PoolClient, types } from 'pg';
import { VerifiedUser } from '../auth/token-verifier';
import { API_CONFIG, ApiConfig } from '../config';
import { Database, DatabaseError, Queryable } from './database';

// Return dates as 'YYYY-MM-DD' (not a JS Date at local midnight), and bigint
// counts as numbers; both are well within range for this data.
types.setTypeParser(types.builtins.DATE, (v) => v);
types.setTypeParser(types.builtins.INT8, (v) => Number(v));

/**
 * PostgreSQL on any host (Supabase, RDS, Cloud SQL, our own servers).
 *
 * Connect as a login role that holds no privileges of its own and may only
 * `set role` to the member role (see supabase/README.md, "API database role").
 * Each call is one transaction: the caller's claims are set locally and the
 * role is switched to the member role, so row-level security applies.
 * Works through a transaction-mode pooler, because nothing outlives the
 * transaction.
 */
@Injectable()
export class PostgresDatabase extends Database implements OnModuleDestroy {
  private readonly pool: Pool;

  constructor(@Inject(API_CONFIG) private readonly config: ApiConfig) {
    super();
    this.pool = new Pool({
      connectionString: config.databaseUrl,
      max: config.databasePoolSize,
      idleTimeoutMillis: 30_000,
      connectionTimeoutMillis: 10_000,
      statement_timeout: 15_000,
      application_name: 'tmyp-api',
    });
  }

  async asUser<T>(user: VerifiedUser, work: (q: Queryable) => Promise<T>): Promise<T> {
    let client: PoolClient;
    try {
      client = await this.pool.connect();
    } catch (e) {
      throw new DatabaseError(`Database unavailable: ${(e as Error).message}`, '08006');
    }
    try {
      await client.query('begin');
      await client.query(
        `select set_config('request.jwt.claims', $1, true),
                set_config('request.jwt.claim.sub', $2, true),
                set_config('role', $3, true)`,
        [JSON.stringify({ ...user.claims, sub: user.id }), user.id, this.config.databaseMemberRole],
      );
      const result = await work({
        query: async <R>(sql: string, params?: unknown[]) =>
          (await client.query(sql, params)).rows as R[],
      });
      await client.query('commit');
      return result;
    } catch (e) {
      await client.query('rollback').catch(() => undefined);
      throw toDatabaseError(e);
    } finally {
      client.release();
    }
  }

  close(): Promise<void> {
    return this.pool.end();
  }

  onModuleDestroy(): Promise<void> {
    return this.close();
  }
}

function toDatabaseError(e: unknown): unknown {
  if (e instanceof DatabaseError) return e;
  if (e instanceof PgError) return new DatabaseError(e.message, e.code);
  return e;
}
