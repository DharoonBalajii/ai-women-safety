import type { Request, Response } from 'express';
import { z } from 'zod';
import { sarvamService } from '../services/sarvam.service.js';
import { HttpError } from '../middleware/error-handler.js';

const textSchema = z.object({ message: z.string().min(1).max(2000) });

export async function analyzeVoice(req: Request, res: Response) {
  const file = req.file;
  if (!file) {
    throw new HttpError(400, 'No audio file provided (field name: "audio")');
  }
  const result = await sarvamService.analyzeVoice(file.buffer, file.originalname, file.mimetype);
  res.status(200).json(result);
}

export async function analyzeText(req: Request, res: Response) {
  const { message } = textSchema.parse(req.body);
  const result = await sarvamService.analyzeText(message);
  res.status(200).json(result);
}

export async function assessAmbient(req: Request, res: Response) {
  const file = req.file;
  if (!file) {
    throw new HttpError(400, 'No audio file provided (field name: "audio")');
  }
  const result = await sarvamService.assessAmbient(file.buffer, file.originalname, file.mimetype);
  res.status(200).json(result);
}
