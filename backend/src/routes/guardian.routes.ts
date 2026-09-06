import { Router } from 'express';
import rateLimit from 'express-rate-limit';
import {
  inviteGuardian,
  listMyRelationships,
  listPendingInvites,
  respondToInvite,
  listMyProtectedUsers,
} from '../controllers/guardian.controller.js';
import { asyncHandler } from '../lib/async-handler.js';
import { requireAuth } from '../middleware/require-auth.js';

export const guardianRouter = Router();

guardianRouter.use(requireAuth);

const guardianRateLimit = rateLimit({
  windowMs: 60_000,
  limit: 30,
  standardHeaders: true,
  legacyHeaders: false,
});
guardianRouter.use(guardianRateLimit);

guardianRouter.post('/invite', asyncHandler(inviteGuardian));
guardianRouter.get('/relationships', asyncHandler(listMyRelationships));
guardianRouter.get('/invites', asyncHandler(listPendingInvites));
guardianRouter.post('/invites/:id/respond', asyncHandler(respondToInvite));
guardianRouter.get('/protected-users', asyncHandler(listMyProtectedUsers));
