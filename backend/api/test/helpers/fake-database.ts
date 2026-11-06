import { VerifiedUser } from '../../src/auth/token-verifier';
import { Database, Queryable } from '../../src/db/database';

export interface QueryCall {
  user: VerifiedUser;
  sql: string;
  params: unknown[];
}

type Handler = (sql: string, params: unknown[], user: VerifiedUser) => unknown[];

/** Records every query and the user it ran as; answers from `handler`. */
export class FakeDatabase extends Database {
  readonly calls: QueryCall[] = [];
  handler: Handler = (sql) => {
    throw new Error(`unexpected query: ${sql}`);
  };

  async asUser<T>(user: VerifiedUser, work: (q: Queryable) => Promise<T>): Promise<T> {
    return work({
      query: async <R>(sql: string, params: unknown[] = []) => {
        this.calls.push({ user, sql, params });
        return this.handler(sql, params, user) as R[];
      },
    });
  }

  async close(): Promise<void> {}

  reset(): void {
    this.calls.length = 0;
    this.handler = (sql) => {
      throw new Error(`unexpected query: ${sql}`);
    };
  }
}
