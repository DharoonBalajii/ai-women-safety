import { z } from 'zod';

export const reportIncidentSchema = z.object({
  threatType: z.string().min(1),
  aiSummary: z.string().max(2000).optional(),
  latitude: z.number().min(-90).max(90).optional(),
  longitude: z.number().min(-180).max(180).optional(),
  batteryPercent: z.number().int().min(0).max(100).optional(),
});
export type ReportIncidentInput = z.infer<typeof reportIncidentSchema>;

// Partial by design — a location ping and a new AI-analyzed summary happen
// at different moments and shouldn't require re-sending fields the caller
// doesn't have a fresh value for.
export const updateIncidentSchema = z
  .object({
    threatType: z.string().min(1).optional(),
    aiSummary: z.string().max(2000).optional(),
    latitude: z.number().min(-90).max(90).optional(),
    longitude: z.number().min(-180).max(180).optional(),
    batteryPercent: z.number().int().min(0).max(100).optional(),
  })
  .refine((v) => Object.keys(v).length > 0, { message: 'Provide at least one field to update' });
export type UpdateIncidentInput = z.infer<typeof updateIncidentSchema>;

// The protected user's own device may only ever move an incident to one of
// these two end states — never ACKNOWLEDGED/RESPONDING, which are a
// guardian's own claim about their response, not something the reporter
// can assert about themselves.
export const updateIncidentStatusSchema = z.object({
  status: z.enum(['RESOLVED', 'CANCELLED']),
});
export type UpdateIncidentStatusInput = z.infer<typeof updateIncidentStatusSchema>;

// A guardian may record their own response progress (ACKNOWLEDGED/
// RESPONDING), or close out the alert once they've made contact and
// confirmed the person is safe (RESOLVED) — but never CANCELLED, which
// only means "I triggered this by mistake" and only the reporter can
// truthfully say that about themselves.
export const respondToAlertSchema = z.object({
  status: z.enum(['ACKNOWLEDGED', 'RESPONDING', 'RESOLVED']),
});
export type RespondToAlertInput = z.infer<typeof respondToAlertSchema>;
