import { prisma } from '../lib/prisma.js';
import type { IncidentStatus } from '@prisma/client';

export class IncidentRepository {
  create(params: {
    protectedUserId: string;
    threatType: string;
    aiSummary?: string;
    latitude?: number;
    longitude?: number;
    batteryPercent?: number;
  }) {
    return prisma.incident.create({
      data: {
        protectedUserId: params.protectedUserId,
        threatType: params.threatType,
        aiSummary: params.aiSummary,
        latitude: params.latitude,
        longitude: params.longitude,
        locationAt: params.latitude !== undefined ? new Date() : undefined,
        batteryPercent: params.batteryPercent,
      },
    });
  }

  findById(id: string) {
    return prisma.incident.findUnique({ where: { id } });
  }

  update(
    id: string,
    params: {
      threatType?: string;
      aiSummary?: string;
      latitude?: number;
      longitude?: number;
      batteryPercent?: number;
    },
  ) {
    const hasLocation = params.latitude !== undefined && params.longitude !== undefined;
    return prisma.incident.update({
      where: { id },
      data: {
        threatType: params.threatType,
        aiSummary: params.aiSummary,
        latitude: params.latitude,
        longitude: params.longitude,
        locationAt: hasLocation ? new Date() : undefined,
        batteryPercent: params.batteryPercent,
      },
    });
  }

  /// Only callable by the reporting protected user, and only to RESOLVED/
  /// CANCELLED — see `updateIncidentStatusSchema`.
  setOwnerStatus(id: string, status: 'RESOLVED' | 'CANCELLED') {
    return prisma.incident.update({
      where: { id },
      data: { status, resolvedAt: new Date() },
    });
  }

  /// Only callable by a guardian with an ACTIVE relationship to the
  /// reporting protected user — see `respondToAlertSchema`. Records which
  /// guardian responded so a dashboard with multiple guardians doesn't show
  /// conflicting "who's handling this" state.
  setGuardianResponse(
    id: string,
    status: 'ACKNOWLEDGED' | 'RESPONDING' | 'RESOLVED',
    guardianProfileId: string,
  ) {
    return prisma.incident.update({
      where: { id },
      data: {
        status,
        respondedByGuardianId: guardianProfileId,
        resolvedAt: status === 'RESOLVED' ? new Date() : undefined,
      },
    });
  }

  findActiveOwnIncident(protectedProfileId: string) {
    return prisma.incident.findFirst({
      where: {
        protectedUserId: protectedProfileId,
        status: { in: ['ACTIVE', 'ACKNOWLEDGED', 'RESPONDING'] as IncidentStatus[] },
      },
      orderBy: { createdAt: 'desc' },
    });
  }

  /// The set of incidents a guardian is authorized to see — restricted to
  /// protected users who have an ACTIVE (not pending/revoked) relationship
  /// with this guardian. A guardian can never see a resolved incident older
  /// than this window; the dashboard is for live response, not history.
  findAlertsForGuardian(guardianProfileId: string) {
    return prisma.incident.findMany({
      where: {
        status: { in: ['ACTIVE', 'ACKNOWLEDGED', 'RESPONDING'] as IncidentStatus[] },
        protectedUser: {
          guardianRelationships: {
            some: { guardianId: guardianProfileId, status: 'ACTIVE' },
          },
        },
      },
      include: { protectedUser: { include: { user: true } } },
      orderBy: { createdAt: 'desc' },
    });
  }
}

export const incidentRepository = new IncidentRepository();
