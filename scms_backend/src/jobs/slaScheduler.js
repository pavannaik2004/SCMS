const cron = require('node-cron');
const { PrismaClient } = require('@prisma/client');
const logger = require('../utils/logger');
const { sendPushNotification } = require('../services/fcm');

const prisma = new PrismaClient();

/**
 * Starts the SLA scheduler cron job (runs every 15 minutes)
 */
const startSlaScheduler = () => {
  cron.schedule('*/15 * * * *', async () => {
    logger.info('SLA Scheduler: Running breach detection scan...');
    
    try {
      const now = new Date();
      
      // Select active complaints where deadline has expired
      const breached = await prisma.complaint.findMany({
        where: {
          slaDeadline: {
            lte: now
          },
          isSlaBreached: false,
          status: {
            notIn: ['RESOLVED', 'CLOSED', 'REJECTED']
          }
        }
      });
      
      if (breached.length === 0) {
        logger.info('SLA Scheduler: No new breaches detected.');
        return;
      }
      
      logger.warn(`SLA Scheduler: Detected ${breached.length} newly breached complaints.`);
      
      for (const complaint of breached) {
        await prisma.$transaction(async (tx) => {
          // 1. Mark as breached
          await tx.complaint.update({
            where: { id: complaint.id },
            data: { isSlaBreached: true }
          });
          
          // 2. Create status update record
          await tx.complaintUpdate.create({
            data: {
              complaintId: complaint.id,
              updatedById: 'SYSTEM',
              updatedByName: 'SLA Engine',
              updatedByRole: 'SYSTEM',
              previousStatus: complaint.status,
              newStatus: complaint.status,
              notes: 'SLA Deadline Breached. Ticket automatically escalated.'
            }
          });
        });

        // Prepare notifications
        const title = `SLA Breach: ${complaint.complaintNumber}`;
        const body = `Ticket "${complaint.title}" has exceeded its SLA resolution deadline.`;
        const payload = {
          complaintId: complaint.id,
          type: 'SLA_BREACHED'
        };

        // Notify Admins
        const admins = await prisma.user.findMany({
          where: {
            role: 'ROLE_ADMIN',
            fcmToken: { not: null }
          }
        });
        
        for (const admin of admins) {
          await sendPushNotification(admin.fcmToken, title, body, payload);
        }

        // Notify Assigned Staff
        if (complaint.assignedToId) {
          const staff = await prisma.user.findUnique({
            where: { id: complaint.assignedToId }
          });
          if (staff && staff.fcmToken) {
            await sendPushNotification(
              staff.fcmToken,
              title,
              'Your assigned ticket has breached its resolution timeframe. Action required.',
              payload
            );
          }
        }
      }
    } catch (error) {
      logger.error('SLA Scheduler: Critical error during scan:', error);
    }
  });
};

module.exports = {
  startSlaScheduler
};
