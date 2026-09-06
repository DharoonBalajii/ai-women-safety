import { Router } from 'express';
import rateLimit from 'express-rate-limit';
import {
  reportIncident,
  updateIncident,
  updateIncidentStatus,
  respondToAlert,
  listMyActiveIncident,
  listAlerts,
} from '../controllers/incident.controller.js';
import { asyncHandler } from '../lib/async-handler.js';
import { requireAuth } from '../middleware/require-auth.js';

export const incidentRouter = Router();

incidentRouter.use(requireAuth);

// A live incident's location update can fire every few seconds; the
// guardian dashboard's own poll is separately bounded on its own path.
const incidentRateLimit = rateLimit({
  windowMs: 60_000,
  limit: 60,
  standardHeaders: true,
  legacyHeaders: false,
});
incidentRouter.use(incidentRateLimit);

incidentRouter.post('/', asyncHandler(reportIncident));
incidentRouter.get('/mine', asyncHandler(listMyActiveIncident));
incidentRouter.patch('/:id', asyncHandler(updateIncident));
incidentRouter.patch('/:id/status', asyncHandler(updateIncidentStatus));
incidentRouter.patch('/:id/response', asyncHandler(respondToAlert));
incidentRouter.get('/alerts', asyncHandler(listAlerts));
