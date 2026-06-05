const cron = require('node-cron');
const { PrismaClient } = require('@prisma/client');
const logger = require('../utils/logger');
const { sendPushNotification } = require('../services/fcm');

const prisma = new PrismaClient();

/**
 * Starts the SR auto-approve cron job (runs every hour)
 */
const startSrAutoApprove = () => {
  cron.schedule('0 * * * *', async () => {
    logger.info('SR Auto-Approve: Scanning for complaints pending > 24 hours...');
    
    try {
      const cutoff = new Date(Date.now() - 24 * 60 * 60 * 1000); // 24 hours ago
      
      const pending = await prisma.complaint.findMany({
        where: {
          status: 'PENDING_SR_REVIEW',
          createdAt: {
            lt: cutoff
          }
        },
        include: {
          submittedBy: true
        }
      });
      
      if (pending.length === 0) {
        logger.info('SR Auto-Approve: No tickets exceeded the 24-hour review threshold.');
        return;
      }
      
      logger.info(`SR Auto-Approve: Auto-approving ${pending.length} complaints.`);
      
      for (const complaint of pending) {
        // Set standard 48-hour resolution SLA from the time of auto-approval
        const defaultSlaDeadline = new Date(Date.now() + 48 * 60 * 60 * 1000);
        
        await prisma.$transaction(async (tx) => {
          // 1. Update status to OPEN and set SLA deadline
          await tx.complaint.update({
            where: { id: complaint.id },
            data: {
              status: 'OPEN',
              slaDeadline: defaultSlaDeadline
            }
          });
          
          // 2. Create history log
          await tx.complaintUpdate.create({
            data: {
              complaintId: complaint.id,
              updatedById: 'SYSTEM',
              updatedByName: 'SR Auto-Approve Engine',
              updatedByRole: 'SYSTEM',
              previousStatus: 'PENDING_SR_REVIEW',
              newStatus: 'OPEN',
              notes: 'Ticket auto-approved by system (SR response timeout exceeded 24 hours).'
            }
          });
        });

        // Notify Submitter
        if (complaint.submittedBy && complaint.submittedBy.fcmToken) {
          await sendPushNotification(
            complaint.submittedBy.fcmToken,
            'Ticket Opened',
            `Your complaint "${complaint.title}" has been automatically approved and is now open.`,
            {
              complaintId: complaint.id,
              type: 'STATUS_UPDATE'
            }
          );
        }
      }
    } catch (error) {
      logger.error('SR Auto-Approve: Critical error in cron job:', error);
    }
  });
};

module.exports = {
  startSrAutoApprove
};
