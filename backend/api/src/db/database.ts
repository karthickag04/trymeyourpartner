import { VerifiedUser } from '../auth/token-verifier';

/** Runs SQL inside the current transaction. */
export interface Queryable {
  query<T = Record<string, unknown>>(sql: string, params?: unknown[]): Promise<T[]>;
}

/** An error raised by the database, e.g. by `raise exception 'CONTACT_LIMIT_REACHED'`. */
export class DatabaseError extends Error {
  constructor(
    message: string,
    /** SQLSTATE, e.g. 42501 for "permission denied". */
    readonly code?: string,
  ) {
    super(message);
  }
}

/**
 * The API's only door to data (docs/adr/0001-vendor-portability.md, rule 2).
 *
 * `asUser` runs `work` in one transaction as the signed-in user: row-level
 * security and the database functions see that user's id and claims through
 * public.app_current_user_id(), exactly as they do for the app. The API never
 * bypasses row-level security.
 */
export abstract class Database {
  abstract asUser<T>(user: VerifiedUser, work: (q: Queryable) => Promise<T>): Promise<T>;
  abstract close(): Promise<void>;
}
