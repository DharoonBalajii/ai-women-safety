import { createHash } from 'node:crypto';
import { clerkClient, frontendApiUrl, isDevInstance } from '../lib/clerkClient.js';
import { logger } from '../lib/logger.js';

/// A Clerk *development* instance (pk_test_...) gates every Frontend API
/// call behind a "dev browser" token — there is no real domain/cookie to
/// prove the caller is a legitimate browser, so Clerk substitutes this
/// token instead. A production instance has no such endpoint or gate.
/// Cached in memory since it's a per-instance credential, not per-request.
let cachedDevBrowserJwt: string | null = null;

async function devBrowserJwt(forceRefresh = false): Promise<string | null> {
  if (!isDevInstance()) return null;
  if (cachedDevBrowserJwt && !forceRefresh) return cachedDevBrowserJwt;

  const response = await fetch(`${frontendApiUrl()}/v1/dev_browser`, { method: 'POST' });
  if (!response.ok) {
    logger.warn({ status: response.status }, 'clerk: failed to obtain dev browser token');
    return null;
  }
  const { token } = (await response.json()) as { token: string };
  cachedDevBrowserJwt = token;
  return token;
}

function withDevBrowserParam(url: string, jwt: string | null): string {
  if (!jwt) return url;
  const withParam = new URL(url);
  withParam.searchParams.set('__clerk_db_jwt', jwt);
  return withParam.toString();
}

/// This Clerk instance's sign-up requirements are configured to require both
/// an email and a phone number identifier, and its phone country allow-list
/// doesn't (yet) include India — an instance-level dashboard setting, not
/// something this call can or should change on the user's behalf. Since our
/// own MSG91 verification (not Clerk's) is the real proof of phone
/// ownership, and our own Postgres `User.phoneNumber` is the source of
/// truth, we satisfy Clerk's two required fields with synthetic, internal
/// values derived deterministically from the real number — never shown to
/// the user and never used to actually contact anyone.
function syntheticClerkIdentifiers(phoneNumber: string): { email: string; usPhone: string } {
  const digest = createHash('sha256').update(phoneNumber).digest();

  // A "555" exchange (the digits right after the area code) is reserved for
  // fictional use only in the narrow 555-0100..0199 block — anything else in
  // it, or a real N11-pattern exchange like 211/911, fails Clerk's E.164
  // validation. Area code 202 + a non-555, non-N11 exchange stays inside
  // syntactically-valid NANP shape without needing a real assigned number.
  let exchange = 200 + (digest.readUInt16BE(0) % 800); // 200-999
  if (exchange % 100 === 11) exchange += 1; // dodge N11 patterns (211, 311, ... 911)
  const line = digest.readUInt16BE(2) % 10_000; // 0000-9999

  return {
    email: `phone-${digest.toString('hex').slice(0, 24)}@users.rakshathunai.internal.example.com`,
    usPhone: `+1202${String(exchange).padStart(3, '0')}${String(line).padStart(4, '0')}`,
  };
}

export interface ClerkSession {
  clerkUserId: string;
  sessionId: string;
  jwt: string;
}

/// Brokers 100% of the Clerk interaction on the backend so the Flutter app
/// never needs to speak Clerk's own protocol (there is no official Clerk
/// Flutter SDK). Flutter only ever holds an opaque `sessionId` (functions
/// like a refresh token — must be kept in secure on-device storage) and a
/// short-lived `jwt` it sends as a normal Bearer token.
export class ClerkAuthService {
  /// Finds the Clerk user for a phone number that MSG91 has just verified,
  /// or creates one. Identifiers attached via the Backend API are trusted
  /// automatically — this call is only ever reachable after our own
  /// server-side MSG91 verification succeeds, never from user input alone.
  ///
  /// Looks up/keys the user by `externalId`, never by Clerk's own
  /// `phoneNumber`/`emailAddress` fields (see `syntheticClerkIdentifiers`).
  async findOrCreateUserForVerifiedPhone(phoneNumber: string): Promise<string> {
    const existing = await clerkClient.users.getUserList({ externalId: [phoneNumber] });
    if (existing.data.length > 0) {
      return existing.data[0]!.id;
    }

    const { email, usPhone } = syntheticClerkIdentifiers(phoneNumber);
    const created = await clerkClient.users.createUser({
      externalId: phoneNumber,
      emailAddress: [email],
      phoneNumber: [usPhone],
      skipPasswordChecks: true,
      skipPasswordRequirement: true,
    });
    logger.info({ clerkUserId: created.id }, 'clerk: created user');
    return created.id;
  }

  /// Mints a Clerk session for a user without a password/OTP challenge,
  /// using Clerk's documented "sign-in token" (ticket strategy) mechanism:
  /// 1. Backend API mints a single-use token for the user.
  /// 2. Backend redeems it via the Frontend API's ticket strategy — this
  ///    step normally happens in a browser/official SDK; we do it
  ///    server-side since no Flutter SDK exists to do it on-device.
  /// 3. Backend mints the actual session JWT for that session.
  ///
  /// Two undocumented-but-required quirks confirmed by hand against this
  /// instance: the body must be `application/x-www-form-urlencoded` (a JSON
  /// body is silently ignored — Clerk creates a blank `needs_identifier`
  /// attempt instead of consuming the ticket), and a dev instance rejects
  /// the call outright without a dev-browser token attached.
  async createSessionForUser(clerkUserId: string): Promise<ClerkSession> {
    const { token } = await clerkClient.signInTokens.createSignInToken({
      userId: clerkUserId,
      expiresInSeconds: 60,
    });

    const signInResponse = await fetch(
      withDevBrowserParam(`${frontendApiUrl()}/v1/client/sign_ins`, await devBrowserJwt()),
      {
        method: 'POST',
        headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
        body: new URLSearchParams({ strategy: 'ticket', ticket: token }).toString(),
      },
    );

    if (!signInResponse.ok) {
      const body = await signInResponse.text();
      logger.error({ status: signInResponse.status, body }, 'clerk: ticket sign-in failed');
      throw new Error('Failed to establish Clerk session');
    }

    const signInBody = (await signInResponse.json()) as {
      response?: { created_session_id?: string };
      client?: {
        sessions?: Array<{ id: string; last_active_token?: { jwt?: string } }>;
      };
    };
    const sessionId =
      signInBody.response?.created_session_id ?? signInBody.client?.sessions?.[0]?.id;
    const session = signInBody.client?.sessions?.find((s) => s.id === sessionId);
    const jwt = session?.last_active_token?.jwt;

    if (!sessionId || !jwt) {
      logger.error({ signInBody }, 'clerk: no session/token in ticket sign-in response');
      throw new Error('Failed to establish Clerk session');
    }

    return { clerkUserId, sessionId, jwt };
  }

  /// Mints a fresh short-lived JWT for an existing (still-valid) session, via
  /// the same Frontend API the official web SDK calls under the hood for
  /// "session.getToken()" — there is no Backend API equivalent for the
  /// default (non-JWT-template) session token. Throws if the session was
  /// revoked or expired, which the caller treats as "sign in again".
  async refreshSessionToken(sessionId: string): Promise<string> {
    const response = await fetch(
      withDevBrowserParam(
        `${frontendApiUrl()}/v1/client/sessions/${sessionId}/tokens`,
        await devBrowserJwt(),
      ),
      { method: 'POST' },
    );

    if (!response.ok) {
      const body = await response.text();
      logger.warn({ status: response.status, body, sessionId }, 'clerk: refresh failed');
      throw new Error('Session is no longer valid');
    }

    const { jwt } = (await response.json()) as { jwt: string };
    return jwt;
  }

  async revokeSession(sessionId: string): Promise<void> {
    await clerkClient.sessions.revokeSession(sessionId);
  }
}

export const clerkAuthService = new ClerkAuthService();
