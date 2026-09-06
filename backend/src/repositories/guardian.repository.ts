import { prisma } from '../lib/prisma.js';

export class GuardianRepository {
  findRelationshipsForProtectedUser(protectedProfileId: string) {
    return prisma.guardianRelationship.findMany({
      where: { protectedUserId: protectedProfileId },
      include: { guardian: { include: { user: true } } },
      orderBy: { createdAt: 'desc' },
    });
  }

  findRelationshipsForGuardian(guardianProfileId: string) {
    return prisma.guardianRelationship.findMany({
      where: { guardianId: guardianProfileId },
      include: { protectedUser: { include: { user: true } } },
      orderBy: { createdAt: 'desc' },
    });
  }

  findById(id: string) {
    return prisma.guardianRelationship.findUnique({
      where: { id },
      include: {
        protectedUser: { include: { user: true } },
        guardian: { include: { user: true } },
      },
    });
  }

  createPending(params: { protectedUserId: string; guardianId: string; label?: string }) {
    return prisma.guardianRelationship.upsert({
      where: {
        protectedUserId_guardianId: {
          protectedUserId: params.protectedUserId,
          guardianId: params.guardianId,
        },
      },
      create: {
        protectedUserId: params.protectedUserId,
        guardianId: params.guardianId,
        label: params.label,
        status: 'PENDING',
      },
      // Re-inviting a previously revoked relationship resets it to pending
      // rather than silently reactivating it.
      update: { status: 'PENDING', label: params.label },
    });
  }

  setStatus(id: string, status: 'ACTIVE' | 'REVOKED') {
    return prisma.guardianRelationship.update({ where: { id }, data: { status } });
  }

  /// The set of guardians a Protected User's active SOS alert must reach —
  /// derived only from ACTIVE, explicit-authorization rows. This is the
  /// query the SOS system will call; a client can never pass guardian ids
  /// directly into an alert-send call.
  findActiveGuardiansFor(protectedProfileId: string) {
    return prisma.guardianRelationship.findMany({
      where: { protectedUserId: protectedProfileId, status: 'ACTIVE' },
      include: { guardian: { include: { user: true } } },
    });
  }
}

export const guardianRepository = new GuardianRepository();
