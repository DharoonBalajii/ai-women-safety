import type { Request, Response } from 'express';
import { guardianRepository } from '../repositories/guardian.repository.js';
import { userRepository } from '../repositories/user.repository.js';
import { inviteGuardianSchema, respondToInviteSchema } from '../validation/guardian.schemas.js';
import { HttpError } from '../middleware/error-handler.js';

async function requireProtectedProfile(clerkUserId: string) {
  const user = await userRepository.findByClerkUserId(clerkUserId);
  if (!user?.protectedProfile) {
    throw new HttpError(403, 'Only a Protected-role account can invite a guardian');
  }
  return user.protectedProfile;
}

async function requireGuardianProfile(clerkUserId: string) {
  const user = await userRepository.findByClerkUserId(clerkUserId);
  if (!user?.guardianProfile) {
    throw new HttpError(403, 'Only a Guardian-role account can view/respond to invites');
  }
  return user.guardianProfile;
}

/// A protected user can only invite a phone number that already has a
/// Guardian-role account — there is no way to invite someone into
/// existence. The 404 here deliberately doesn't distinguish "no account"
/// from "wrong role" beyond the message, since either way the answer is
/// the same: ask them to sign up as a Guardian first.
export async function inviteGuardian(req: Request, res: Response) {
  const { guardianPhoneNumber, label } = inviteGuardianSchema.parse(req.body);
  const protectedProfile = await requireProtectedProfile(req.clerkUserId!);

  const guardianUser = await userRepository.findByPhoneNumber(guardianPhoneNumber);
  if (!guardianUser?.guardianProfile) {
    throw new HttpError(
      404,
      'No Guardian account found for that number — ask them to sign up as a Guardian first.',
    );
  }

  const relationship = await guardianRepository.createPending({
    protectedUserId: protectedProfile.id,
    guardianId: guardianUser.guardianProfile.id,
    label,
  });
  res.status(201).json({ relationshipId: relationship.id, status: relationship.status });
}

export async function listMyRelationships(req: Request, res: Response) {
  const protectedProfile = await requireProtectedProfile(req.clerkUserId!);
  const relationships = await guardianRepository.findRelationshipsForProtectedUser(protectedProfile.id);

  res.status(200).json({
    relationships: relationships.map((r) => ({
      relationshipId: r.id,
      status: r.status,
      label: r.label,
      guardianPhoneNumber: r.guardian.user.phoneNumber,
      createdAt: r.createdAt,
    })),
  });
}

export async function listPendingInvites(req: Request, res: Response) {
  const guardianProfile = await requireGuardianProfile(req.clerkUserId!);
  const relationships = await guardianRepository.findRelationshipsForGuardian(guardianProfile.id);

  res.status(200).json({
    invites: relationships
      .filter((r) => r.status === 'PENDING')
      .map((r) => ({
        relationshipId: r.id,
        label: r.label,
        protectedPhoneNumber: r.protectedUser.user.phoneNumber,
        createdAt: r.createdAt,
      })),
  });
}

export async function respondToInvite(req: Request, res: Response) {
  const { accept } = respondToInviteSchema.parse(req.body);
  const guardianProfile = await requireGuardianProfile(req.clerkUserId!);

  const relationship = await guardianRepository.findById(req.params.id!);
  if (!relationship || relationship.guardianId !== guardianProfile.id) {
    throw new HttpError(404, 'Invite not found');
  }
  if (relationship.status !== 'PENDING') {
    throw new HttpError(409, 'This invite has already been responded to');
  }

  const updated = await guardianRepository.setStatus(relationship.id, accept ? 'ACTIVE' : 'REVOKED');
  res.status(200).json({ relationshipId: updated.id, status: updated.status });
}

export async function listMyProtectedUsers(req: Request, res: Response) {
  const guardianProfile = await requireGuardianProfile(req.clerkUserId!);
  const relationships = await guardianRepository.findRelationshipsForGuardian(guardianProfile.id);

  res.status(200).json({
    protectedUsers: relationships
      .filter((r) => r.status === 'ACTIVE')
      .map((r) => ({
        relationshipId: r.id,
        label: r.label,
        protectedPhoneNumber: r.protectedUser.user.phoneNumber,
      })),
  });
}
