import type { NextFunction, Request, Response } from 'express';
import { verifyToken } from '@clerk/backend';
import { env } from '../config/env.js';
import { HttpError } from './error-handler.js';

declare global {
  namespace Express {
    interface Request {
      clerkUserId?: string;
    }
  }
}

/// Verifies the Bearer JWT the Flutter app got from /auth/send-otp+verify-otp
/// (or a subsequent /auth/refresh) and attaches the Clerk user id it encodes.
/// Every route that reads or mutates a specific user's data must sit behind
/// this — it's the only place a request's identity is established.
export async function requireAuth(req: Request, _res: Response, next: NextFunction) {
  const header = req.headers.authorization;
  const token = header?.startsWith('Bearer ') ? header.slice('Bearer '.length) : undefined;

  if (!token) {
    next(new HttpError(401, 'Missing bearer token'));
    return;
  }

  const result = await verifyToken(token, { secretKey: env.CLERK_SECRET_KEY });
  if (result.errors) {
    next(new HttpError(401, 'Invalid or expired token'));
    return;
  }

  // @clerk/backend's JwtPayload re-exports through @clerk/shared/types, which
  // this project's moduleResolution doesn't fully resolve — `sub` is
  // documented and stable on every Clerk token regardless.
  req.clerkUserId = (result.data as { sub: string }).sub;
  next();
}
