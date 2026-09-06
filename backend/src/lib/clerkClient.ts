import { createClerkClient } from '@clerk/backend';
import { env } from '../config/env.js';

// Server-only. CLERK_SECRET_KEY must never reach the Flutter app.
export const clerkClient = createClerkClient({
  secretKey: env.CLERK_SECRET_KEY,
  publishableKey: env.CLERK_PUBLISHABLE_KEY,
});

/// Derived from the publishable key (pk_test_... / pk_live_...): Clerk
/// encodes "<frontend-api-host>$" as base64 after the environment prefix.
export function frontendApiUrl(): string {
  const key = env.CLERK_PUBLISHABLE_KEY;
  const encoded = key.replace(/^pk_(test|live)_/, '');
  const host = Buffer.from(encoded, 'base64').toString('utf8').replace(/\$$/, '');
  return `https://${host}`;
}

/// A `pk_test_...` key is a Clerk development instance, which gates its
/// Frontend API behind a "dev browser" token (see `fetchDevBrowserJwt`) that
/// a production (`pk_live_...`) instance neither needs nor exposes.
export function isDevInstance(): boolean {
  return env.CLERK_PUBLISHABLE_KEY.startsWith('pk_test_');
}
