import { Router } from 'express';
import multer from 'multer';
import rateLimit from 'express-rate-limit';
import { analyzeVoice, analyzeText, assessAmbient } from '../controllers/ai.controller.js';
import { asyncHandler } from '../lib/async-handler.js';

export const aiRouter = Router();

// Ambient monitoring alone can call this every ~8s per active incident;
// generous enough for real use, still bounded against abuse.
const aiRateLimit = rateLimit({
  windowMs: 60_000,
  limit: 30,
  standardHeaders: true,
  legacyHeaders: false,
});
aiRouter.use(aiRateLimit);

// In-memory storage: clips are short (a few seconds) and only ever held
// long enough to forward to Sarvam, never written to disk.
const upload = multer({ storage: multer.memoryStorage(), limits: { fileSize: 10 * 1024 * 1024 } });

aiRouter.post('/voice', upload.single('audio'), asyncHandler(analyzeVoice));
aiRouter.post('/text', asyncHandler(analyzeText));
aiRouter.post('/ambient', upload.single('audio'), asyncHandler(assessAmbient));
