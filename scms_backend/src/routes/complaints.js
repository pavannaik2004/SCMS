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
const { enrichComplaints } = require('../utils/enrichComplaints');
const ExcelJS = require('exceljs');
const logger = require('../utils/logger');

const router = express.Router();
const prisma = new PrismaClient();

// Schemas for validation
// NOTE: 'RESOLVED' is intentionally NOT settable here — staff must resolve via
// POST /:id/resolve (which requires proof media). 'COMPLETED' is set only by the
// admin via POST /:id/verify-resolution. This endpoint covers the early staff
// step (ASSIGNED -> IN_PROGRESS) plus admin overrides.
const statusUpdateSchema = z.object({
  status: z.enum(['ASSIGNED', 'IN_PROGRESS', 'CLOSED', 'REJECTED']),
  notes: z.string().optional()
});

const assignSchema = z.object({
  // Not .uuid() — seeded/dev demo staff use readable ids (e.g. demo-staff-electrical),
  // while real Google users get UUIDs. Any non-empty id is accepted; existence +
  // ROLE_STAFF/ROLE_ADMIN are validated against the DB in the handler.
  assignedToId: z.string().min(1)
});

const verifyResolutionSchema = z.object({
  decision: z.enum(['APPROVE', 'REDO']),
  notes: z.string().optional()
});

const ratingSchema = z.object({
  rating: z.number().min(1).max(5),
  ratingComment: z.string().optional()
});

// Fields the submitter is allowed to edit on their own complaint.
const editComplaintSchema = z.object({
  title: z.string().min(1).optional(),
  description: z.string().min(1).optional(),
  location: z.string().min(1).optional(),
  categoryId: z.string().uuid().optional(),
  severity: z.enum(['LOW', 'MEDIUM', 'HIGH']).optional(),
  tags: z.array(z.string()).optional()
}).refine((data) => Object.keys(data).length > 0, {
  message: 'At least one field must be provided to update.'
});

// Guard all endpoints
router.use(authenticate);

/**
 * GET /api/complaints/my
 * Role-aware complaint listing endpoint feeding the dashboards
 */
router.get('/my', async (req, res, next) => {
  try {
    const page = req.query.page !== undefined ? Number(req.query.page) : 0;
    const limit = req.query.limit !== undefined ? Number(req.query.limit) : (req.query.size !== undefined ? Number(req.query.size) : 10);
    const skip = page * limit;

    const { status } = req.query;
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

    await enrichComplaints(complaints);

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
    const page = req.query.page !== undefined ? Number(req.query.page) : 0;
    const limit = req.query.limit !== undefined ? Number(req.query.limit) : (req.query.size !== undefined ? Number(req.query.size) : 10);
    const skip = page * limit;

    const { status, departmentId, categoryId, severity, q, scope } = req.query;

    // Default filters
    const whereClause = {};
    if (status) whereClause.status = status;
    if (departmentId) whereClause.departmentId = departmentId;
    if (categoryId) whereClause.categoryId = categoryId;
    if (severity) whereClause.severity = severity;
    if (q) {
      whereClause.OR = [
        { title: { contains: q, mode: 'insensitive' } },
        { description: { contains: q, mode: 'insensitive' } },
        { complaintNumber: { contains: q, mode: 'insensitive' } }
      ];
    }

    // `scope=all` exposes the read-only, system-wide explore feed to ANY
    // authenticated role. Without it, the list stays role-scoped (students see
    // their own, staff see assigned) so existing screens are unaffected.
    if (scope !== 'all') {
      if (req.user.role === 'ROLE_USER') {
        whereClause.submittedById = req.user.id;
      } else if (req.user.role === 'ROLE_STAFF') {
        whereClause.assignedToId = req.user.id;
      }
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

    await enrichComplaints(complaints);

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
 * GET /api/complaints/export
 * Admin-only Excel (.xlsx) export of complaints with optional filters
 * (status, departmentId, categoryId, severity, from/to on createdAt).
 * Streams a spreadsheet the Flutter app saves to the device.
 */
router.get('/export', requireRole('ROLE_ADMIN', 'ROLE_DEPT_HEAD'), async (req, res, next) => {
  try {
    const { status, departmentId, categoryId, severity, from, to } = req.query;

    const whereClause = {};
    if (status) whereClause.status = status;
    if (departmentId) whereClause.departmentId = departmentId;
    if (categoryId) whereClause.categoryId = categoryId;
    if (severity) whereClause.severity = severity;
    if (from || to) {
      whereClause.createdAt = {};
      if (from) whereClause.createdAt.gte = new Date(from);
      if (to) whereClause.createdAt.lte = new Date(to);
    }

    const complaints = await prisma.complaint.findMany({
      where: whereClause,
      include: {
        submittedBy: { select: { id: true, name: true, email: true } },
        mediaItems: true
      },
      orderBy: { createdAt: 'desc' }
    });

    await enrichComplaints(complaints);

    const workbook = new ExcelJS.Workbook();
    workbook.creator = 'SCMS';
    workbook.created = new Date();
    const sheet = workbook.addWorksheet('Complaints');

    sheet.columns = [
      { header: 'Complaint No.', key: 'complaintNumber', width: 20 },
      { header: 'Title', key: 'title', width: 34 },
      { header: 'Category', key: 'categoryName', width: 16 },
      { header: 'Department', key: 'departmentName', width: 24 },
      { header: 'Location', key: 'location', width: 30 },
      { header: 'Severity', key: 'severity', width: 12 },
      { header: 'Status', key: 'status', width: 18 },
      { header: 'Submitted By', key: 'submittedByName', width: 20 },
      { header: 'Assigned To', key: 'assignedToName', width: 20 },
      { header: 'Created At', key: 'createdAt', width: 22 },
      { header: 'Resolved At', key: 'resolvedAt', width: 22 },
      { header: 'Completed At', key: 'completedAt', width: 22 },
      { header: 'SLA Breached', key: 'isSlaBreached', width: 14 },
      { header: 'Rating', key: 'rating', width: 10 },
      { header: 'Rating Comment', key: 'ratingComment', width: 36 }
    ];
    sheet.getRow(1).font = { bold: true };

    const fmt = (d) => (d ? new Date(d).toISOString().replace('T', ' ').slice(0, 16) : '');

    for (const c of complaints) {
      sheet.addRow({
        complaintNumber: c.complaintNumber,
        title: c.title,
        categoryName: c.categoryName || '',
        departmentName: c.departmentName || '',
        location: c.location,
        severity: c.severity,
        status: c.status,
        submittedByName: c.submittedByName || '',
        assignedToName: c.assignedToName || '',
        createdAt: fmt(c.createdAt),
        resolvedAt: fmt(c.resolvedAt),
        completedAt: fmt(c.completedAt),
        isSlaBreached: c.isSlaBreached ? 'Yes' : 'No',
        rating: c.rating != null ? c.rating : '',
        ratingComment: c.ratingComment || ''
      });
    }

    const stamp = new Date().toISOString().slice(0, 10);
    res.setHeader('Content-Type', 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
    res.setHeader('Content-Disposition', `attachment; filename="complaints-${stamp}.xlsx"`);
    await workbook.xlsx.write(res);
    res.end();
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

    // Read access is open to any authenticated user — every role can browse the
    // system-wide complaint feed and open a complaint's details (read-only).
    // Write actions (status/assign/rating/SR approve-reject) stay guarded on
    // their own routes, so opening a ticket never grants the ability to mutate it.

    await enrichComplaints(complaint);

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

    // Auto-resolve departmentId from the category's default if not explicitly provided
    let resolvedDepartmentId = departmentId || null;
    if (!resolvedDepartmentId && categoryId) {
      const category = await prisma.category.findUnique({
        where: { id: categoryId },
        select: { defaultDepartmentId: true }
      });
      resolvedDepartmentId = category?.defaultDepartmentId || null;
    }

    // Validate main required text inputs manually since middleware is bypassed for multipart forms
    if (!title || !description || !location || !categoryId || !resolvedDepartmentId || !severity) {
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
          departmentId: resolvedDepartmentId,
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
 * POST /api/complaints/:id/resolve
 * Staff submits proof-of-resolution (photos/videos + notes). Moves the ticket to
 * RESOLVED and hands it to the admin for verification. Only the assigned staff may
 * call this, and only while the ticket is ASSIGNED or IN_PROGRESS.
 */
router.post('/:id/resolve', upload.array('media', 5), async (req, res, next) => {
  try {
    const { id } = req.params;
    const { notes } = req.body;

    const complaint = await prisma.complaint.findUnique({ where: { id } });
    if (!complaint) {
      return sendError(res, 404, 'Complaint not found.');
    }

    const isAssigned = complaint.assignedToId === req.user.id;
    if (!isAssigned) {
      return sendError(res, 403, 'Forbidden: Only the assigned staff member can submit a resolution.');
    }

    if (!['ASSIGNED', 'IN_PROGRESS'].includes(complaint.status)) {
      return sendError(res, 400, `Bad Request: Cannot submit a resolution while the ticket is ${complaint.status}.`);
    }

    const files = req.files || [];
    if (files.length === 0) {
      return sendError(res, 400, 'Bad Request: At least one proof photo/video is required to resolve.');
    }

    // Validate file sizes (mirrors the create endpoint)
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

    const updated = await prisma.$transaction(async (tx) => {
      // Store the proof media, tagged so the admin review can isolate them.
      await tx.mediaItem.createMany({
        data: files.map((file) => ({
          complaintId: id,
          url: getMediaUrl(file.filename),
          mediaType: file.mimetype.startsWith('image/') ? 'IMAGE' : 'VIDEO',
          purpose: 'PROOF',
          gpsLatitude: 0.0,
          gpsLongitude: 0.0,
          gpsPlaceName: 'Resolution Proof',
          capturedAt: new Date(),
          fileSizeBytes: file.size,
          isWatermarked: true
        }))
      });

      const updatedRecord = await tx.complaint.update({
        where: { id },
        data: { status: 'RESOLVED', resolvedAt: new Date() }
      });

      await tx.complaintUpdate.create({
        data: {
          complaintId: id,
          updatedById: req.user.id,
          updatedByName: req.user.email,
          updatedByRole: req.user.role,
          previousStatus: complaint.status,
          newStatus: 'RESOLVED',
          notes: notes || 'Staff submitted proof of resolution. Awaiting admin verification.'
        }
      });

      return updatedRecord;
    });

    // Notify all admins that a resolution is awaiting their verification.
    const admins = await prisma.user.findMany({
      where: { role: 'ROLE_ADMIN', fcmToken: { not: null } }
    });
    for (const adm of admins) {
      sendPushNotification(
        adm.fcmToken,
        'Resolution Submitted',
        `Proof submitted for ${complaint.complaintNumber}. Please verify.`,
        { complaintId: id, type: 'RESOLUTION_REVIEW' }
      ).catch((err) => logger.error(`FCM admin dispatch failed: ${err.message}`));
    }

    return sendSuccess(res, updated);
  } catch (error) {
    next(error);
  }
});

/**
 * POST /api/complaints/:id/verify-resolution
 * Admin reviews the staff proof and either APPROVEs (-> COMPLETED, submitter is
 * asked to rate) or sends it back for REDO (-> IN_PROGRESS, same staff re-notified).
 * Only valid while the ticket is RESOLVED.
 */
router.post('/:id/verify-resolution', requireRole('ROLE_ADMIN', 'ROLE_DEPT_HEAD'), validateBody(verifyResolutionSchema), async (req, res, next) => {
  try {
    const { id } = req.params;
    const { decision, notes } = req.body;

    const complaint = await prisma.complaint.findUnique({
      where: { id },
      include: { submittedBy: true }
    });
    if (!complaint) {
      return sendError(res, 404, 'Complaint not found.');
    }

    if (complaint.status !== 'RESOLVED') {
      return sendError(res, 400, 'Bad Request: Only a RESOLVED complaint awaiting verification can be reviewed.');
    }

    const approve = decision === 'APPROVE';
    const newStatus = approve ? 'COMPLETED' : 'IN_PROGRESS';

    const updated = await prisma.$transaction(async (tx) => {
      const updatedRecord = await tx.complaint.update({
        where: { id },
        data: approve
          ? { status: 'COMPLETED', completedAt: new Date() }
          : { status: 'IN_PROGRESS' }
      });

      await tx.complaintUpdate.create({
        data: {
          complaintId: id,
          updatedById: req.user.id,
          updatedByName: req.user.email,
          updatedByRole: req.user.role,
          previousStatus: 'RESOLVED',
          newStatus,
          notes: notes || (approve
            ? 'Admin verified the resolution. Complaint completed.'
            : 'Admin sent the resolution back for rework.')
        }
      });

      return updatedRecord;
    });

    if (approve) {
      // Ask the submitter to rate.
      if (complaint.submittedBy && complaint.submittedBy.fcmToken) {
        sendPushNotification(
          complaint.submittedBy.fcmToken,
          'Complaint Completed',
          `Your complaint "${complaint.title}" has been resolved. Please leave a rating.`,
          { complaintId: id, type: 'STATUS_UPDATE' }
        ).catch((err) => logger.error(`FCM submitter dispatch failed: ${err.message}`));
      }
    } else {
      // Tell the same staff member to redo the work.
      if (complaint.assignedToId) {
        const staff = await prisma.user.findUnique({ where: { id: complaint.assignedToId } });
        if (staff && staff.fcmToken) {
          sendPushNotification(
            staff.fcmToken,
            'Resolution Needs Rework',
            `${complaint.complaintNumber} was sent back for rework.`,
            { complaintId: id, type: 'ASSIGNED' }
          ).catch((err) => logger.error(`FCM staff dispatch failed: ${err.message}`));
        }
      }
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

    // Rating happens after the admin has verified the resolution (COMPLETED).
    if (complaint.status !== 'COMPLETED') {
      return sendError(res, 400, 'Bad Request: Complaint must be in COMPLETED status to submit rating.');
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
          previousStatus: 'COMPLETED',
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

/**
 * PATCH /api/complaints/:id
 * Edit a complaint's own content. Restricted to the submitter (owner-only).
 * Other roles mutate via their dedicated routes (status/assign/rating).
 */
router.patch('/:id', validateBody(editComplaintSchema), async (req, res, next) => {
  try {
    const { id } = req.params;
    const { title, description, location, categoryId, severity, tags } = req.body;

    const complaint = await prisma.complaint.findUnique({ where: { id } });
    if (!complaint) {
      return sendError(res, 404, 'Complaint not found.');
    }

    // Only the person who filed the complaint may edit it.
    if (complaint.submittedById !== req.user.id) {
      return sendError(res, 403, 'Forbidden: Only the submitter can edit this complaint.');
    }

    // Build the update payload from provided fields only.
    const data = {};
    if (title !== undefined) data.title = title;
    if (description !== undefined) data.description = description;
    if (location !== undefined) data.location = location;
    if (severity !== undefined) data.severity = severity;
    if (tags !== undefined) data.tags = tags;

    // If the category changes, re-resolve the default department for it.
    if (categoryId !== undefined && categoryId !== complaint.categoryId) {
      const category = await prisma.category.findUnique({
        where: { id: categoryId },
        select: { defaultDepartmentId: true }
      });
      if (!category) {
        return sendError(res, 400, 'Bad Request: Unknown category.');
      }
      data.categoryId = categoryId;
      data.departmentId = category.defaultDepartmentId;
    }

    const updated = await prisma.$transaction(async (tx) => {
      const updatedRecord = await tx.complaint.update({ where: { id }, data });

      await tx.complaintUpdate.create({
        data: {
          complaintId: id,
          updatedById: req.user.id,
          updatedByName: req.user.email,
          updatedByRole: req.user.role,
          previousStatus: complaint.status,
          newStatus: complaint.status,
          notes: 'Complaint details edited by the submitter.'
        }
      });

      return updatedRecord;
    });

    // Refresh the duplicate-detection embedding if the description changed.
    if (data.description) {
      generateAndStoreEmbedding(data.description, id).catch((err) => {
        logger.error(`Failed to refresh embedding for complaint ${id}: ${err.message}`);
      });
    }

    await enrichComplaints(updated);

    return sendSuccess(res, updated);
  } catch (error) {
    next(error);
  }
});

/**
 * DELETE /api/complaints/:id
 * Delete a complaint. Restricted to the submitter (owner-only). Child rows
 * (media + timeline) are removed first since the schema has no cascade.
 */
router.delete('/:id', async (req, res, next) => {
  try {
    const { id } = req.params;

    const complaint = await prisma.complaint.findUnique({ where: { id } });
    if (!complaint) {
      return sendError(res, 404, 'Complaint not found.');
    }

    if (complaint.submittedById !== req.user.id) {
      return sendError(res, 403, 'Forbidden: Only the submitter can delete this complaint.');
    }

    await prisma.$transaction(async (tx) => {
      await tx.mediaItem.deleteMany({ where: { complaintId: id } });
      await tx.complaintUpdate.deleteMany({ where: { complaintId: id } });
      await tx.complaint.delete({ where: { id } });
    });

    return sendSuccess(res, { id, deleted: true });
  } catch (error) {
    next(error);
  }
});

module.exports = router;
