const express = require('express');
const { z } = require('zod');
const { PrismaClient } = require('@prisma/client');
const { sendSuccess } = require('../utils/responseHelper');
const authenticate = require('../middleware/authenticate');
const validateBody = require('../middleware/validateBody');

const router = express.Router();
const prisma = new PrismaClient();

const fcmTokenSchema = z.object({
  fcmToken: z.string().nullable()
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
