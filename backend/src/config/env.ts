import 'dotenv/config';
import { z } from 'zod';

const envSchema = z.object({
  PORT: z.coerce.number().default(4000),
  NODE_ENV: z.enum(['development', 'production', 'test']).default('development'),
  CORS_ORIGINS: z
    .string()
    .default('')
    .transform((value) => value.split(',').map((origin) => origin.trim()).filter(Boolean)),

  CLERK_SECRET_KEY: z.string().min(1, 'CLERK_SECRET_KEY is required'),
  CLERK_PUBLISHABLE_KEY: z.string().min(1, 'CLERK_PUBLISHABLE_KEY is required'),

  // Admin-provisioned Sarvam AI key. Lives only here — the app never sees
  // it, so it can't be extracted from the client or its network traffic.
  SARVAM_API_KEY: z.string().min(1, 'SARVAM_API_KEY is required'),

  DATABASE_URL: z.string().min(1, 'DATABASE_URL is required'),
});

const parsed = envSchema.safeParse(process.env);

if (!parsed.success) {
  console.error('Invalid environment configuration:');
  console.error(parsed.error.flatten().fieldErrors);
  throw new Error('Invalid environment configuration. See errors above.');
}

export const env = parsed.data;
