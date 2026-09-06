import { z } from 'zod';

// E.164: + followed by 8-15 digits.
const phoneNumber = z
  .string()
  .regex(/^\+[1-9]\d{7,14}$/, 'Phone number must be in E.164 format, e.g. +919876543210');

export const sendOtpSchema = z.object({
  phoneNumber,
  role: z.enum(['PROTECTED', 'GUARDIAN']),
});
export type SendOtpInput = z.infer<typeof sendOtpSchema>;

export const verifyOtpSchema = z.object({
  phoneNumber,
  role: z.enum(['PROTECTED', 'GUARDIAN']),
  code: z.string().regex(/^\d{4,8}$/, 'OTP code must be 4-8 digits'),
});
export type VerifyOtpInput = z.infer<typeof verifyOtpSchema>;

export const refreshSchema = z.object({
  sessionId: z.string().min(1),
});
export type RefreshInput = z.infer<typeof refreshSchema>;
