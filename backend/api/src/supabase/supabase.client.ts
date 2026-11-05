import { Inject, Injectable } from '@nestjs/common';
import { API_CONFIG, ApiConfig } from '../config';

/** An error returned by Supabase (PostgREST or Auth). */
export class SupabaseError extends Error {
  constructor(
    readonly status: number,
    readonly body: { code?: string; message?: string } | string,
  ) {
    super(typeof body === 'string' ? body : (body.message ?? `HTTP ${status}`));
  }
}

export interface SupabaseUser {
  id: string;
  email?: string;
}

/**
 * Calls Supabase on behalf of the signed-in member, with their own access
 * token. Row-level security therefore applies exactly as in the app; the API
 * never bypasses it.
 */
@Injectable()
export class SupabaseClient {
  constructor(@Inject(API_CONFIG) private readonly config: ApiConfig) {}

  /** Returns the user for a valid access token, or null. */
  async getUser(accessToken: string): Promise<SupabaseUser | null> {
    const res = await this.request('GET', '/auth/v1/user', accessToken);
    if (res.status === 401 || res.status === 403) return null;
    if (!res.ok) throw new SupabaseError(res.status, await this.body(res));
    const user = (await res.json()) as SupabaseUser;
    return user?.id ? user : null;
  }

  /** GET /rest/v1/<path> as the member. */
  async select<T>(accessToken: string, path: string): Promise<T> {
    const res = await this.request('GET', `/rest/v1/${path}`, accessToken);
    if (!res.ok) throw new SupabaseError(res.status, await this.body(res));
    return (await res.json()) as T;
  }

  /** POST /rest/v1/rpc/<fn> as the member. */
  async rpc<T>(accessToken: string, fn: string, args: object): Promise<T> {
    const res = await this.request(
      'POST',
      `/rest/v1/rpc/${fn}`,
      accessToken,
      args,
    );
    if (!res.ok) throw new SupabaseError(res.status, await this.body(res));
    const text = await res.text();
    return (text ? JSON.parse(text) : null) as T;
  }

  private request(
    method: string,
    path: string,
    accessToken: string,
    body?: object,
  ): Promise<Response> {
    return fetch(`${this.config.supabaseUrl}${path}`, {
      method,
      headers: {
        apikey: this.config.supabasePublishableKey,
        Authorization: `Bearer ${accessToken}`,
        'Content-Type': 'application/json',
        Accept: 'application/json',
      },
      body: body === undefined ? undefined : JSON.stringify(body),
    });
  }

  private async body(res: Response) {
    const text = await res.text();
    try {
      return JSON.parse(text) as { code?: string; message?: string };
    } catch {
      return text;
    }
  }
}
