import { app } from './app.js';
import { env, isMsg91Configured } from './config/env.js';
import { logger } from './lib/logger.js';

app.listen(env.PORT, () => {
  logger.info(
    { port: env.PORT, msg91: isMsg91Configured ? 'live' : 'mock' },
    'raksha-thunai-backend listening',
  );
});
