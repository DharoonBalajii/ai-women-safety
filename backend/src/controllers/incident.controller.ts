import type { Request, Response } from 'express';
import { incidentRepository } from '../repositories/incident.repository.js';
import { userRepository } from '../repositories/user.repository.js';
import {
  reportIncidentSchema,
  updateIncidentSchema,
  updateIncidentStatusSchema,
  respondToAlertSchema,
} from '../validation/incident.schemas.js';
import { HttpError } from '../middleware/error-handler.js';

async function requireProtectedProfile(clerkUserId: string) {
  const user = await userRepository.findByClerkUserId(clerkUserId);
  if (!user?.protectedProfile) {
    throw new HttpError(403, 'Only a Protected-role account can report an incident');
  }
  return user.protectedProfile;
}

async function requireGuardianProfile(clerkUserId: string) {
  const user = await userRepository.findByClerkUserId(clerkUserId);
  if (!user?.guardianProfile) {
    throw new HttpError(403, 'Only a Guardian-role account can respond to alerts');
  }
  return user.guardianProfile;
}

export async function reportIncident(req: Request, res: Response) {
  const input = reportIncidentSchema.parse(req.body);
  const protectedProfile = await requireProtectedProfile(req.clerkUserId!);

  const incident = await incidentRepository.create({
    protectedUserId: protectedProfile.id,
    ...input,
  });
  res.status(201).json({ incidentId: incident.id, status: incident.status });
}

export async function updateIncident(req: Request, res: Response) {
  const input = updateIncidentSchema.parse(req.body);
  const protectedProfile = await requireProtectedProfile(req.clerkUserId!);

  const incident = await incidentRepository.findById(req.params.id!);
  if (!incident || incident.protectedUserId !== protectedProfile.id) {
    throw new HttpError(404, 'Incident not found');
  }

  await incidentRepository.update(incident.id, input);
  res.status(204).send();
}

export async function updateIncidentStatus(req: Request, res: Response) {
  const { status } = updateIncidentStatusSchema.parse(req.body);
  const protectedProfile = await requireProtectedProfile(req.clerkUserId!);

  const incident = await incidentRepository.findById(req.params.id!);
  if (!incident || incident.protectedUserId !== protectedProfile.id) {
    throw new HttpError(404, 'Incident not found');
  }

  const updated = await incidentRepository.setOwnerStatus(incident.id, status);
  res.status(200).json({ incidentId: updated.id, status: updated.status });
}

export async function respondToAlert(req: Request, res: Response) {
  const { status } = respondToAlertSchema.parse(req.body);
  const guardianProfile = await requireGuardianProfile(req.clerkUserId!);

  const incident = await incidentRepository.findById(req.params.id!);
  if (!incident) {
    throw new HttpError(404, 'Incident not found');
  }

  // Re-derive authorization from the ACTIVE-relationship list rather than
  // trusting that the client only ever shows alerts it was actually given —
  // this is the one place that matters, since it's a write.
  const authorizedAlerts = await incidentRepository.findAlertsForGuardian(guardianProfile.id);
  if (!authorizedAlerts.some((alert) => alert.id === incident.id)) {
    throw new HttpError(403, 'Not authorized for this incident');
  }

  const updated = await incidentRepository.setGuardianResponse(incident.id, status, guardianProfile.id);
  res.status(200).json({ incidentId: updated.id, status: updated.status });
}

export async function listMyActiveIncident(req: Request, res: Response) {
  const protectedProfile = await requireProtectedProfile(req.clerkUserId!);
  const incident = await incidentRepository.findActiveOwnIncident(protectedProfile.id);
  res.status(200).json({ incident: incident ? { incidentId: incident.id, status: incident.status } : null });
}

export async function listAlerts(req: Request, res: Response) {
  const guardianProfile = await requireGuardianProfile(req.clerkUserId!);
  const alerts = await incidentRepository.findAlertsForGuardian(guardianProfile.id);

  res.status(200).json({
    alerts: alerts.map((alert) => ({
      incidentId: alert.id,
      status: alert.status,
      threatType: alert.threatType,
      aiSummary: alert.aiSummary,
      latitude: alert.latitude,
      longitude: alert.longitude,
      locationAt: alert.locationAt,
      batteryPercent: alert.batteryPercent,
      protectedPhoneNumber: alert.protectedUser.user.phoneNumber,
      protectedDisplayName: alert.protectedUser.displayName,
      createdAt: alert.createdAt,
      updatedAt: alert.updatedAt,
    })),
  });
}
