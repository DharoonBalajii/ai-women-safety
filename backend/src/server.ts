import { app } from './app.js';
import { env } from './config/env.js';
import { logger } from './lib/logger.js';

// Last-resort net: a bug in any one request handler (like the expired-JWT
// crash this caught) must not take down every other in-flight and future
// request. Each of these means a real bug went uncaught somewhere and
// still needs fixing — this only stops one request's mistake from becoming
// a full outage.
process.on('uncaughtException', (err) => {
  logger.error({ err }, 'uncaughtException — process kept alive, but this must be fixed');
});
process.on('unhandledRejection', (err) => {
  logger.error({ err }, 'unhandledRejection — process kept alive, but this must be fixed');
});

app.listen(env.PORT, () => {
  logger.info({ port: env.PORT }, 'raksha-thunai-backend listening');
});
