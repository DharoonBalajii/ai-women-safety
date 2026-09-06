import { z } from 'zod';

export const inviteGuardianSchema = z.object({
  guardianPhoneNumber: z.string().regex(/^\+[1-9]\d{7,14}$/, 'Use E.164 format, e.g. +919876543210'),
  label: z.string().max(50).optional(),
});
export type InviteGuardianInput = z.infer<typeof inviteGuardianSchema>;

export const respondToInviteSchema = z.object({
  accept: z.boolean(),
});
export type RespondToInviteInput = z.infer<typeof respondToInviteSchema>;
