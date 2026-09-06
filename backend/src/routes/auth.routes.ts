import { Router } from 'express';
import rateLimit from 'express-rate-limit';
import { sendOtp, verifyOtp, refresh, signOut } from '../controllers/auth.controller.js';
import { asyncHandler } from '../lib/async-handler.js';

export const authRouter = Router();

// IP-level backstop on top of the per-phone DB check inside sendOtp itself.
// /refresh alone can legitimately fire many times a minute — every
// authenticated screen with a polling loop (e.g. the guardian dashboard)
// re-mints its short-lived Clerk JWT this way — so this needs real headroom
// beyond what send-otp/verify-otp abuse-prevention alone would want.
const authRateLimit = rateLimit({
  windowMs: 15 * 60_000,
  limit: 300,
  standardHeaders: true,
  legacyHeaders: false,
});

authRouter.use(authRateLimit);

authRouter.post('/send-otp', asyncHandler(sendOtp));
authRouter.post('/verify-otp', asyncHandler(verifyOtp));
authRouter.post('/refresh', asyncHandler(refresh));
authRouter.post('/sign-out', asyncHandler(signOut));
