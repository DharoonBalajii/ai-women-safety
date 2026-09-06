import pino from 'pino';
import { env } from '../config/env.js';

// Structured logging for security-relevant events. `redact` is a hard
// guardrail: even if a caller accidentally logs an object containing one of
// these keys, pino strips the value before it hits stdout.
export const logger = pino({
  level: env.NODE_ENV === 'production' ? 'info' : 'debug',
  redact: {
    paths: [
      'otp',
      'code',
      '*.otp',
      '*.code',
      'authKey',
      '*.authKey',
      'token',
      '*.token',
      'secret',
      '*.secret',
      'password',
      '*.password',
      'req.headers.authorization',
      'req.headers.cookie',
    ],
    censor: '[redacted]',
  },
  transport:
    env.NODE_ENV === 'development'
      ? { target: 'pino-pretty', options: { colorize: true, translateTime: 'HH:MM:ss' } }
      : undefined,
});
