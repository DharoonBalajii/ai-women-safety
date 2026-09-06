import { PrismaClient } from '@prisma/client';

// One client per process (Prisma's own recommendation) — avoids exhausting
// Supabase's connection pool under `tsx watch` hot-reloads in dev.
declare global {
  // eslint-disable-next-line no-var
  var __prisma: PrismaClient | undefined;
}

export const prisma = globalThis.__prisma ?? new PrismaClient();

if (process.env.NODE_ENV !== 'production') {
  globalThis.__prisma = prisma;
}
