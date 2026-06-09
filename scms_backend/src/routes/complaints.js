const express = require('express');
const { z } = require('zod');
const { PrismaClient } = require('@prisma/client');
const { sendSuccess, sendError } = require('../utils/responseHelper');
const authenticate = require('../middleware/authenticate');
const requireRole = require('../middleware/requireRole');
const validateBody = require('../middleware/validateBody');
const upload = require('../middleware/upload');
const { getMediaUrl } = require('../services/storage');
const { generateComplaintNumber } = require('../services/complaintNumber');
const { generateAndStoreEmbedding } = require('../services/aiProxy');
const { sendPushNotification } = require('../services/fcm');
const logger = require('../utils/logger');

const router = express.Router();
const prisma = new PrismaClient();

// Schemas for validation
const statusUpdateSchema = z.object({
  status: z.enum(['ASSIGNED', 'IN_PROGRESS', 'RESOLVED', 'CLOSED', 'REJECTED']),
  notes: z.string().optional()
});

const assignSchema = z.object({
  assignedToId: z.string().uuid()
});

const ratingSchema = z.object({
  rating: z.number().min(1).max(5),
  ratingComment: z.string().optional()
});

// Guard all endpoints
router.use(authenticate);

/**
 * GET /api/complaints/my
 * Role-aware complaint listing endpoint feeding the dashboards
 */
router.get('/my', async (req, res, next) => {
  try {
    const { status, page = 1, limit = 10 } = req.query;
    const skip = (Number(page) - 1) * Number(limit);

    let whereClause = {};

    if (req.user.role === 'ROLE_USER') {
      whereClause.submittedById = req.user.id;
    } else if (req.user.role === 'ROLE_STAFF') {
      whereClause.assignedToId = req.user.id;
    } else if (req.user.role === 'ROLE_ADMIN' || req.user.role === 'ROLE_DEPT_HEAD') {
      // Admins/Dept Heads see everything by default
      whereClause = {};
    }

    if (status) {
      whereClause.status = status;
    }

    const complaints = await prisma.complaint.findMany({
      where: whereClause,
      include: {
        submittedBy: {
          select: { id: true, name: true, email: true, picture: true }
        },
        mediaItems: true
      },
      orderBy: { createdAt: 'desc' },
      skip: Number(skip),
      take: Number(limit)
    });

    const total = await prisma.complaint.count({ where: whereClause });

    return sendSuccess(res, {
      complaints,
      pagination: {
        page: Number(page),
        limit: Number(limit),
        total,
        totalPages: Math.ceil(total / Number(limit))
      }
    });

  } catch (error) {
    next(error);
  }
});

/**
 * GET /api/complaints
 * General listing endpoint (alternative for admin filters)
 */
router.get('/', async (req, res, next) => {
  try {
    const { status, departmentId, categoryId, page = 1, limit = 10 } = req.query;
    const skip = (Number(page) - 1) * Number(limit);

    // Default filters
    const whereClause = {};
    if (status) whereClause.status = status;
    if (departmentId) whereClause.departmentId = departmentId;
    if (categoryId) whereClause.categoryId = categoryId;

    // Restrict list to own entries if standard user
    if (req.user.role === 'ROLE_USER') {
      whereClause.submittedById = req.user.id;
    } else if (req.user.role === 'ROLE_STAFF') {
      whereClause.assignedToId = req.user.id;
    }

    const complaints = await prisma.complaint.findMany({
      where: whereClause,
      include: {
        submittedBy: {
          select: { id: true, name: true, email: true, picture: true }
        },
        mediaItems: true
      },
      orderBy: { createdAt: 'desc' },
      skip: Number(skip),
      take: Number(limit)
    });

    const total = await prisma.complaint.count({ where: whereClause });

    return sendSuccess(res, {
      complaints,
      pagination: {
        page: Number(page),
        limit: Number(limit),
        total,
        totalPages: Math.ceil(total / Number(limit))
      }
    });
  } catch (error) {
    next(error);
  }
});

/**
 * GET /api/complaints/:id
 * Retrieves a single complaint details by ID
 */
router.get('/:id', async (req, res, next) => {
  try {
    const { id } = req.params;

    const complaint = await prisma.complaint.findUnique({
      where: { id },
      include: {
        submittedBy: {
          select: { id: true, name: true, email: true, picture: true }
        },
        mediaItems: true,
        updates: {
          orderBy: { timestamp: 'desc' }
        }
      }
    });

    if (!complaint) {
      return sendError(res, 404, 'Complaint not found.');
    }

    // RBAC: Verify user has rights to view this ticket
    const isOwner = complaint.submittedById === req.user.id;
    const isAssigned = complaint.assignedToId === req.user.id;
    const isPrivileged = ['ROLE_ADMIN', 'ROLE_DEPT_HEAD', 'ROLE_SR'].includes(req.user.role);

    if (!isOwner && !isAssigned && !isPrivileged) {
      return sendError(res, 403, 'Forbidden: You do not have permission to view this complaint.');
    }

    return sendSuccess(res, complaint);
  } catch (error) {
    next(error);
  }
});

/**
 * POST /api/complaints
 * Submits a new complaint, handles photo/video uploads, AI proxies
 */
router.post('/', upload.array('media', 5), async (req, res, next) => {
  try {
    const {
      title,
      description,
      location,
      categoryId,
      departmentId,
      severity,
      gpsLatitude,
      gpsLongitude,
      gpsPlaceName
    } = req.body;

    // Validate main required text inputs manually since middleware is bypassed for multipart forms
    if (!title || !description || !location || !categoryId || !departmentId || !severity) {
      return sendError(res, 400, 'Bad Request: Missing required form fields.');
    }

    // Parse array parameters
    let tags = [];
    if (req.body.tags) {
      try {
        tags = JSON.parse(req.body.tags);
      } catch (e) {
        if (typeof req.body.tags === 'string') {
          tags = req.body.tags.split(',').map((t) => t.trim());
        }
      }
    }

    const files = req.files || [];
    
    // Perform file size validation
    for (const file of files) {
      const isImage = file.mimetype.startsWith('image/');
      const isVideo = file.mimetype.startsWith('video/');
      
      if (isImage && file.size > 10 * 1024 * 1024) {
        return sendError(res, 400, `Bad Request: Image ${file.originalname} exceeds the 10MB limit.`);
      }
      if (isVideo && file.size > 100 * 1024 * 1024) {
        return sendError(res, 400, `Bad Request: Video ${file.originalname} exceeds the 100MB limit.`);
      }
    }

    // Generate atomic complaint number
    const complaintNumber = await generateComplaintNumber();

    const lat = gpsLatitude ? parseFloat(gpsLatitude) : null;
    const lng = gpsLongitude ? parseFloat(gpsLongitude) : null;

    // Run database insert transaction
    const newComplaint = await prisma.$transaction(async (tx) => {
      // 1. Create Complaint
      const comp = await tx.complaint.create({
        data: {
          complaintNumber,
          title,
          description,
          location,
          categoryId,
          departmentId,
          severity,
          status: 'PENDING_SR_REVIEW',
          tags,
          submittedById: req.user.id,
          gpsLatitude: lat,
          gpsLongitude: lng,
          gpsPlaceName: gpsPlaceName || null
        }
      });

      // 2. Create Media Items
      if (files.length > 0) {
        await tx.mediaItem.createMany({
          data: files.map((file) => ({
            complaintId: comp.id,
            url: getMediaUrl(file.filename),
            mediaType: file.mimetype.startsWith('image/') ? 'IMAGE' : 'VIDEO',
            gpsLatitude: lat || 0.0,
            gpsLongitude: lng || 0.0,
            gpsPlaceName: gpsPlaceName || 'Unknown Location',
            capturedAt: new Date(),
            fileSizeBytes: file.size,
            isWatermarked: true // Flutter paints the watermark locally before upload
          }))
        });
      }

      // 3. Log Initial Update
      await tx.complaintUpdate.create({
        data: {
          complaintId: comp.id,
          updatedById: req.user.id,
          updatedByName: req.user.email,
          updatedByRole: req.user.role,
          previousStatus: 'SUBMITTED',
          newStatus: 'PENDING_SR_REVIEW',
          notes: 'Complaint submitted successfully. Pending Student Representative review.'
        }
      });

      return comp;
    });

    // Generate pgvector embedding in background (non-blocking)
    generateAndStoreEmbedding(description, newComplaint.id).catch((err) => {
      logger.error(`Failed to generate embeddings for complaint ${newComplaint.id}: ${err.message}`);
    });

    // Notify Student Representatives (ROLE_SR)
    const srs = await prisma.user.findMany({
      where: {
        role: 'ROLE_SR',
        fcmToken: { not: null }
      }
    });

    const notifTitle = 'New Complaint Review';
    const notifBody = `A new complaint has been submitted: ${complaintNumber}`;
    const notifPayload = {
      complaintId: newComplaint.id,
      type: 'ESCALATION'
    };

    for (const sr of srs) {
      sendPushNotification(sr.fcmToken, notifTitle, notifBody, notifPayload).catch((err) => {
        logger.error(`FCM SR dispatch failed for user ${sr.id}: ${err.message}`);
      });
    }

    return sendSuccess(res, newComplaint, 201);

  } catch (error) {
    next(error);
  }
});

/**
 * PATCH /api/complaints/:id/status
 * Updates ticket status (forward updates only, e.g. OPEN -> IN_PROGRESS -> RESOLVED)
 */
router.patch('/:id/status', validateBody(statusUpdateSchema), async (req, res, next) => {
  try {
    const { id } = req.params;
    const { status, notes } = req.body;

    const complaint = await prisma.complaint.findUnique({
      where: { id },
      include: { submittedBy: true }
    });

    if (!complaint) {
      return sendError(res, 404, 'Complaint not found.');
    }

    // Authorization checks
    const isAssigned = complaint.assignedToId === req.user.id;
    const isAdmin = req.user.role === 'ROLE_ADMIN';

    if (!isAssigned && !isAdmin) {
      return sendError(res, 403, 'Forbidden: You are not authorized to update the status of this ticket.');
    }

    // Update complaint status in database
    const updated = await prisma.$transaction(async (tx) => {
      const updatedRecord = await tx.complaint.update({
        where: { id },
        data: { status }
      });

      await tx.complaintUpdate.create({
        data: {
          complaintId: id,
          updatedById: req.user.id,
          updatedByName: req.user.email,
          updatedByRole: req.user.role,
          previousStatus: complaint.status,
          newStatus: status,
          notes: notes || `Status updated to ${status}.`
        }
      });

      return updatedRecord;
    });

    // Notify Submitter
    if (complaint.submittedBy && complaint.submittedBy.fcmToken) {
      await sendPushNotification(
        complaint.submittedBy.fcmToken,
        'Ticket Status Updated',
        `Your complaint "${complaint.title}" has been updated to "${status}".`,
        { complaintId: id, type: 'STATUS_UPDATE' }
      );
    }

    return sendSuccess(res, updated);

  } catch (error) {
    next(error);
  }
});

/**
 * PATCH /api/complaints/:id/assign
 * Assigns a staff member to the complaint (restricted to Admin/Dept Head)
 */
router.patch('/:id/assign', requireRole('ROLE_ADMIN', 'ROLE_DEPT_HEAD'), validateBody(assignSchema), async (req, res, next) => {
  try {
    const { id } = req.params;
    const { assignedToId } = req.body;

    const complaint = await prisma.complaint.findUnique({
      where: { id },
      include: { submittedBy: true }
    });

    if (!complaint) {
      return sendError(res, 404, 'Complaint not found.');
    }

    // Verify staff exists and has valid role
    const staff = await prisma.user.findUnique({
      where: { id: assignedToId }
    });

    if (!staff || !['ROLE_STAFF', 'ROLE_ADMIN'].includes(staff.role)) {
      return sendError(res, 400, 'Bad Request: Assigned user must have ROLE_STAFF or ROLE_ADMIN privileges.');
    }

    const updated = await prisma.$transaction(async (tx) => {
      const updatedRecord = await tx.complaint.update({
        where: { id },
        data: {
          assignedToId,
          status: 'ASSIGNED'
        }
      });

      await tx.complaintUpdate.create({
        data: {
          complaintId: id,
          updatedById: req.user.id,
          updatedByName: req.user.email,
          updatedByRole: req.user.role,
          previousStatus: complaint.status,
          newStatus: 'ASSIGNED',
          notes: `Ticket assigned to staff member ${staff.name}.`
        }
      });

      return updatedRecord;
    });

    // Notify Assigned Staff
    if (staff.fcmToken) {
      sendPushNotification(
        staff.fcmToken,
        'New Task Assigned',
        `You have been assigned to task: ${complaint.complaintNumber}`,
        { complaintId: id, type: 'ASSIGNED' }
      ).catch((err) => logger.error(`FCM dispatch failed: ${err.message}`));
    }

    // Notify Submitter
    if (complaint.submittedBy && complaint.submittedBy.fcmToken) {
      sendPushNotification(
        complaint.submittedBy.fcmToken,
        'Staff Assigned',
        `Staff member "${staff.name}" has been assigned to resolve your complaint.`,
        { complaintId: id, type: 'STATUS_UPDATE' }
      ).catch((err) => logger.error(`FCM dispatch failed: ${err.message}`));
    }

    return sendSuccess(res, updated);

  } catch (error) {
    next(error);
  }
});

/**
 * POST /api/complaints/:id/rating
 * Rate and close a resolved complaint (only accessible by ticket owner)
 */
router.post('/:id/rating', validateBody(ratingSchema), async (req, res, next) => {
  try {
    const { id } = req.params;
    const { rating, ratingComment } = req.body;

    const complaint = await prisma.complaint.findUnique({
      where: { id }
    });

    if (!complaint) {
      return sendError(res, 404, 'Complaint not found.');
    }

    if (complaint.submittedById !== req.user.id) {
      return sendError(res, 403, 'Forbidden: Only the submitter can rate the complaint resolution.');
    }

    if (complaint.status !== 'RESOLVED') {
      return sendError(res, 400, 'Bad Request: Complaint must be in RESOLVED status to submit rating.');
    }

    const updated = await prisma.$transaction(async (tx) => {
      const updatedRecord = await tx.complaint.update({
        where: { id },
        data: {
          rating,
          ratingComment: ratingComment || null,
          status: 'CLOSED'
        }
      });

      await tx.complaintUpdate.create({
        data: {
          complaintId: id,
          updatedById: req.user.id,
          updatedByName: req.user.email,
          updatedByRole: req.user.role,
          previousStatus: 'RESOLVED',
          newStatus: 'CLOSED',
          notes: `User submitted a rating of ${rating}/5 stars.`
        }
      });

      return updatedRecord;
    });

    return sendSuccess(res, updated);

  } catch (error) {
    next(error);
  }
});

module.exports = router;
