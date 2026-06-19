const express = require('express');
const { z } = require('zod');
const { PrismaClient } = require('@prisma/client');
const { sendSuccess } = require('../utils/responseHelper');
const authenticate = require('../middleware/authenticate');
const requireRole = require('../middleware/requireRole');
const validateBody = require('../middleware/validateBody');

const router = express.Router();
const prisma = new PrismaClient();

const fcmTokenSchema = z.object({
  fcmToken: z.string().nullable()
});

/**
 * GET /api/users?role=ROLE_STAFF
 * Lists users (optionally filtered by role) for the admin assignment picker.
 * Restricted to Admin / Dept Head.
 */
router.get('/', authenticate, requireRole('ROLE_ADMIN', 'ROLE_DEPT_HEAD'), async (req, res, next) => {
  try {
    const { role } = req.query;
    const where = {};
    if (role) where.role = role;

    const users = await prisma.user.findMany({
      where,
      select: {
        id: true,
        name: true,
        email: true,
        picture: true,
        role: true,
        departmentId: true,
        createdAt: true,
        lastLogin: true
      },
      orderBy: { name: 'asc' }
    });

    const departments = await prisma.department.findMany();
    const deptMap = {};
    departments.forEach((d) => { deptMap[d.id] = d.name; });

    const result = users.map((u) => ({
      ...u,
      departmentName: u.departmentId ? (deptMap[u.departmentId] || null) : null
    }));

    return sendSuccess(res, { users: result });
  } catch (error) {
    next(error);
  }
});

/**
 * PATCH /api/users/fcm-token
 * Updates the active user's push token
 */
router.patch('/fcm-token', authenticate, validateBody(fcmTokenSchema), async (req, res, next) => {
  try {
    const { fcmToken } = req.body;
    await prisma.user.update({
      where: { id: req.user.id },
      data: { fcmToken }
    });
    return sendSuccess(res, { message: 'FCM token successfully registered.' });
  } catch (error) {
    next(error);
  }
});

module.exports = router;
