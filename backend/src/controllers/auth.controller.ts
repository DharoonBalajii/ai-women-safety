import type { Request, Response } from 'express';
import type { OtpPurpose } from '@prisma/client';
import { otpRepository } from '../repositories/otp.repository.js';
import { userRepository } from '../repositories/user.repository.js';
import { msg91Service } from '../services/msg91.service.js';
import { clerkAuthService } from '../services/clerk-auth.service.js';
import { sendOtpSchema, verifyOtpSchema, refreshSchema } from '../validation/auth.schemas.js';
import { HttpError } from '../middleware/error-handler.js';
import { logger } from '../lib/logger.js';

const SEND_OTP_WINDOW_MINUTES = 15;
const SEND_OTP_MAX_PER_WINDOW = 5;

/// A phone's purpose is derived from whether it already has a User row, never
/// taken from client input — the client's `role` field is only ever used
/// when that row doesn't exist yet (sign-up).
async function resolvePurpose(phoneNumber: string): Promise<OtpPurpose> {
  const existing = await userRepository.findByPhoneNumber(phoneNumber);
  return existing ? 'SIGN_IN' : 'SIGN_UP';
}

export async function sendOtp(req: Request, res: Response) {
  const { phoneNumber, role } = sendOtpSchema.parse(req.body);

  const recentRequests = await otpRepository.countRecentRequests(
    phoneNumber,
    SEND_OTP_WINDOW_MINUTES,
  );
  if (recentRequests >= SEND_OTP_MAX_PER_WINDOW) {
    throw new HttpError(429, 'Too many OTP requests for this phone number. Try again later.');
  }

  const purpose = await resolvePurpose(phoneNumber);

  if (purpose === 'SIGN_IN') {
    const existing = await userRepository.findByPhoneNumber(phoneNumber);
    if (existing && existing.role !== role) {
      throw new HttpError(409, 'This phone number is already registered with a different role');
    }
  }

  const result = await msg91Service.sendOtp(phoneNumber);
  if (!result.ok) {
    throw new HttpError(502, result.message);
  }

  await otpRepository.create({ phoneNumber, purpose, msg91RequestId: result.requestId });

  // Honest about mode: the client must never assume a real SMS went out.
  res.status(200).json({ purpose, mock: !msg91Service.isConfigured });
}

export async function verifyOtp(req: Request, res: Response) {
  const { phoneNumber, role, code } = verifyOtpSchema.parse(req.body);
  const purpose = await resolvePurpose(phoneNumber);

  const activeOtp = await otpRepository.findActive(phoneNumber, purpose);
  if (!activeOtp) {
    throw new HttpError(400, 'No active OTP request for this phone number. Request a new one.');
  }
  if (activeOtp.attempts >= activeOtp.maxAttempts) {
    throw new HttpError(429, 'Too many incorrect attempts. Request a new OTP.');
  }

  const result = await msg91Service.verifyOtp(phoneNumber, code);
  if (!result.ok) {
    await otpRepository.incrementAttempts(activeOtp.id);
    throw new HttpError(401, result.message);
  }

  // Consumed only after every downstream step below succeeds — MSG91 (or the
  // mock) has already confirmed the code is correct at this point, but if
  // Clerk/DB provisioning fails transiently we want the same code to still
  // be usable on retry rather than forcing the user to request a new SMS.
  let user = await userRepository.findByPhoneNumber(phoneNumber);

  if (!user) {
    const clerkUserId = await clerkAuthService.findOrCreateUserForVerifiedPhone(phoneNumber);
    user = await userRepository.createWithProfile({ clerkUserId, phoneNumber, role });
    logger.info({ userId: user.id, role }, 'auth: sign-up complete');
  } else if (user.role !== role) {
    throw new HttpError(409, 'This phone number is already registered with a different role');
  }

  const session = await clerkAuthService.createSessionForUser(user.clerkUserId);

  await otpRepository.markConsumed(activeOtp.id);

  res.status(200).json({
    sessionId: session.sessionId,
    jwt: session.jwt,
    user: { id: user.id, role: user.role, phoneNumber: user.phoneNumber },
  });
}

export async function refresh(req: Request, res: Response) {
  const { sessionId } = refreshSchema.parse(req.body);

  try {
    const jwt = await clerkAuthService.refreshSessionToken(sessionId);
    res.status(200).json({ jwt });
  } catch (error) {
    logger.warn({ err: error, sessionId }, 'auth: refresh failed');
    throw new HttpError(401, 'Session is no longer valid. Sign in again.');
  }
}

export async function signOut(req: Request, res: Response) {
  const { sessionId } = refreshSchema.parse(req.body);
  await clerkAuthService.revokeSession(sessionId);
  res.status(204).send();
}
