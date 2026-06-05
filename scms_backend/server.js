require('dotenv').config();
const app = require('./src/app');
const logger = require('./src/utils/logger');
const { PrismaClient } = require('@prisma/client');

const { startSlaScheduler } = require('./src/jobs/slaScheduler');
const { startSrAutoApprove } = require('./src/jobs/srAutoApprove');

const prisma = new PrismaClient();
const PORT = process.env.PORT || 3000;

async function bootstrap() {
  try {
    // 1. Verify PostgreSQL Database Connection on startup
    await prisma.$connect();
    logger.info('PostgreSQL connection verified successfully.');

    // 2. Start background cron jobs
    startSlaScheduler();
    startSrAutoApprove();

    // 3. Bind server listener
    app.listen(PORT, () => {
      logger.info(`SCMS Backend Server listening on port ${PORT} (NODE_ENV=${process.env.NODE_ENV || 'development'}).`);
    });
  } catch (error) {
    logger.error('Bootstrap failed: Could not establish server bindings.', error);
    process.exit(1);
  }
}

bootstrap();
