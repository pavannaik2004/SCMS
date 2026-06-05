const express = require('express');
const { z } = require('zod');
const { PrismaClient } = require('@prisma/client');
const { sendSuccess, sendError } = require('../utils/responseHelper');
const authenticate = require('../middleware/authenticate');
const requireRole = require('../middleware/requireRole');
const validateBody = require('../middleware/validateBody');
const { sendPushNotification } = require('../services/fcm');

const router = express.Router();
const prisma = new PrismaClient();

const approveSchema = z.object({
  departmentId: z.string().optional(),
  categoryId: z.string().optional(),
  severity: z.string().optional()
});

const rejectSchema = z.object({
  rejectionCause: z.string().min(3, 'Rejection cause must be at least 3 characters long.')
});

// Guard router to authenticated ROLE_SR profiles only
router.use(authenticate);
router.use(requireRole('ROLE_SR'));

/**
 * GET /api/sr/pending
 * Lists all complaints waiting for SR approval
 */
router.get('/pending', async (req, res, next) => {
  try {
    const complaints = await prisma.complaint.findMany({
      where: { status: 'PENDING_SR_REVIEW' },
      include: {
        submittedBy: {
          select: { id: true, name: true, email: true, picture: true }
        },
        mediaItems: true
      },
      orderBy: { createdAt: 'desc' }
    });
    return sendSuccess(res, complaints);
  } catch (error) {
    next(error);
  }
});

/**
 * POST /api/sr/:id/approve
 * Approves a complaint and moves it to OPEN status with a set SLA deadline
 */
router.post('/:id/approve', validateBody(approveSchema), async (req, res, next) => {
  try {
    const { id } = req.params;
    const { departmentId, categoryId, severity } = req.body;

    const complaint = await prisma.complaint.findUnique({
      where: { id },
      include: { submittedBy: true }
    });

    if (!complaint) {
      return sendError(res, 404, 'Complaint not found.');
    }

    if (complaint.status !== 'PENDING_SR_REVIEW') {
      return sendError(res, 400, 'Bad Request: Complaint is not pending review.');
    }

    // Set default SLA deadline of 48 hours from approval
    const slaDeadline = new Date(Date.now() + 48 * 60 * 60 * 1000);

    const updateData = {
      status: 'OPEN',
      slaDeadline
    };

    if (departmentId) updateData.departmentId = departmentId;
    if (categoryId) updateData.categoryId = categoryId;
    if (severity) updateData.severity = severity;

    const updated = await prisma.$transaction(async (tx) => {
      const updatedRecord = await tx.complaint.update({
        where: { id },
        data: updateData
      });

      await tx.complaintUpdate.create({
        data: {
          complaintId: id,
          updatedById: req.user.id,
          updatedByName: req.user.email,
          updatedByRole: 'ROLE_SR',
          previousStatus: 'PENDING_SR_REVIEW',
          newStatus: 'OPEN',
          notes: 'Complaint approved by Student Representative.'
        }
      });

      return updatedRecord;
    });

    // Notify Submitter
    if (complaint.submittedBy && complaint.submittedBy.fcmToken) {
      await sendPushNotification(
        complaint.submittedBy.fcmToken,
        'Complaint Approved',
        `Your complaint "${complaint.title}" has been approved and is now open for resolution.`,
        { complaintId: id, type: 'STATUS_UPDATE' }
      );
    }

    return sendSuccess(res, updated);
  } catch (error) {
    next(error);
  }
});

/**
 * POST /api/sr/:id/reject
 * Rejects a complaint and closes it with a rejection cause
 */
router.post('/:id/reject', validateBody(rejectSchema), async (req, res, next) => {
  try {
    const { id } = req.params;
    const { rejectionCause } = req.body;

    const complaint = await prisma.complaint.findUnique({
      where: { id },
      include: { submittedBy: true }
    });

    if (!complaint) {
      return sendError(res, 404, 'Complaint not found.');
    }

    if (complaint.status !== 'PENDING_SR_REVIEW') {
      return sendError(res, 400, 'Bad Request: Complaint is not pending review.');
    }

    const updated = await prisma.$transaction(async (tx) => {
      const updatedRecord = await tx.complaint.update({
        where: { id },
        data: {
          status: 'REJECTED',
          srRejectionCause: rejectionCause
        }
      });

      await tx.complaintUpdate.create({
        data: {
          complaintId: id,
          updatedById: req.user.id,
          updatedByName: req.user.email,
          updatedByRole: 'ROLE_SR',
          previousStatus: 'PENDING_SR_REVIEW',
          newStatus: 'REJECTED',
          notes: `Complaint rejected: ${rejectionCause}`
        }
      });

      return updatedRecord;
    });

    // Notify Submitter
    if (complaint.submittedBy && complaint.submittedBy.fcmToken) {
      await sendPushNotification(
        complaint.submittedBy.fcmToken,
        'Complaint Rejected',
        `Your complaint "${complaint.title}" has been rejected. Reason: ${rejectionCause}`,
        { complaintId: id, type: 'STATUS_UPDATE' }
      );
    }

    return sendSuccess(res, updated);
  } catch (error) {
    next(error);
  }
});

module.exports = router;
