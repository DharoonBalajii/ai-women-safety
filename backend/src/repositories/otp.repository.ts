import { prisma } from '../lib/prisma.js';
import type { OtpPurpose } from '@prisma/client';

const OTP_TTL_MINUTES = 10;

export class OtpRepository {
  /// Requests made for this phone number in the trailing window — used by
  /// the rate limiter to cap send-otp abuse independent of IP (a phone
  /// number is the scarce resource being protected, not just the caller).
  async countRecentRequests(phoneNumber: string, sinceMinutesAgo: number): Promise<number> {
    return prisma.otpVerification.count({
      where: {
        phoneNumber,
        createdAt: { gte: new Date(Date.now() - sinceMinutesAgo * 60_000) },
      },
    });
  }

  async create(params: { phoneNumber: string; purpose: OtpPurpose; msg91RequestId?: string }) {
    return prisma.otpVerification.create({
      data: {
        phoneNumber: params.phoneNumber,
        purpose: params.purpose,
        msg91RequestId: params.msg91RequestId,
        expiresAt: new Date(Date.now() + OTP_TTL_MINUTES * 60_000),
      },
    });
  }

  /// Latest unconsumed, unexpired OTP request for this phone/purpose.
  findActive(phoneNumber: string, purpose: OtpPurpose) {
    return prisma.otpVerification.findFirst({
      where: { phoneNumber, purpose, consumedAt: null, expiresAt: { gt: new Date() } },
      orderBy: { createdAt: 'desc' },
    });
  }

  incrementAttempts(id: string) {
    return prisma.otpVerification.update({ where: { id }, data: { attempts: { increment: 1 } } });
  }

  markConsumed(id: string) {
    return prisma.otpVerification.update({ where: { id }, data: { consumedAt: new Date() } });
  }
}

export const otpRepository = new OtpRepository();
