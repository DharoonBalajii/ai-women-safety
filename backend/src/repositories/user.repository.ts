import { prisma } from '../lib/prisma.js';
import type { UserRole } from '@prisma/client';

export class UserRepository {
  findByPhoneNumber(phoneNumber: string) {
    return prisma.user.findUnique({
      where: { phoneNumber },
      include: { protectedProfile: true, guardianProfile: true },
    });
  }

  findByClerkUserId(clerkUserId: string) {
    return prisma.user.findUnique({
      where: { clerkUserId },
      include: { protectedProfile: true, guardianProfile: true },
    });
  }

  /// Creates the User row plus its role-specific profile in one transaction.
  /// Only ever called from the sign-up path, immediately after MSG91 has
  /// verified the phone number and a Clerk user id has been minted for it.
  async createWithProfile(params: {
    clerkUserId: string;
    phoneNumber: string;
    role: UserRole;
  }) {
    return prisma.user.create({
      data: {
        clerkUserId: params.clerkUserId,
        phoneNumber: params.phoneNumber,
        role: params.role,
        ...(params.role === 'PROTECTED'
          ? { protectedProfile: { create: {} } }
          : { guardianProfile: { create: {} } }),
      },
      include: { protectedProfile: true, guardianProfile: true },
    });
  }
}

export const userRepository = new UserRepository();
