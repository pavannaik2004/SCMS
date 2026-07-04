const express = require('express');
const { z } = require('zod');
const { PrismaClient } = require('@prisma/client');
const { verifyGoogleToken } = require('../services/googleAuth');
const { signAccessToken, signRefreshToken, verifyToken } = require('../utils/jwtHelper');
const { sendSuccess, sendError } = require('../utils/responseHelper');
const authenticate = require('../middleware/authenticate');
const validateBody = require('../middleware/validateBody');
const logger = require('../utils/logger');

const router = express.Router();
const prisma = new PrismaClient();

// Zod schemas for request validation
const googleLoginSchema = z.object({
  idToken: z.string().min(1, 'Google ID token is required.'),
  fcmToken: z.string().nullish()
});

const refreshSchema = z.object({
  refreshToken: z.string().min(1, 'Refresh token is required.')
});

const logoutSchema = z.object({
  refreshToken: z.string().min(1, 'Refresh token is required.')
});

/**
 * POST /api/auth/google
 * Authenticates user via Google OAuth 2.0 idToken
 */
router.post('/google', validateBody(googleLoginSchema), async (req, res, next) => {
  try {
    const { idToken, fcmToken } = req.body;
    let googleProfile;

    try {
      googleProfile = await verifyGoogleToken(idToken);
    } catch (error) {
      logger.warn(`Google token validation failed: ${error.message}`);
      if (error.message === 'EMAIL_NOT_VERIFIED') {
        return sendError(res, 403, 'Google account email is not verified.');
      }
      if (error.message === 'DOMAIN_NOT_ALLOWED') {
        return sendError(res, 403, 'Access denied: Only accounts from authorized domains (e.g., @rvce.edu.in) are permitted.');
      }
      return sendError(res, 400, 'Invalid Google ID token supplied.');
    }

    // Check if user exists in the database
    let user = await prisma.user.findUnique({
      where: { email: googleProfile.email }
    });

    let isNewUser = false;

    if (!user) {
      isNewUser = true;
      // Configure default roles. Let's make the first user or specific patterns admin, otherwise standard ROLE_USER
      let defaultRole = 'ROLE_USER';

      // Example rule: specific administrative emails or seed parameters
      if (googleProfile.email.startsWith('admin@')) {
        defaultRole = 'ROLE_ADMIN';
      }

      user = await prisma.user.create({
        data: {
          googleId: googleProfile.googleId,
          email: googleProfile.email,
          name: googleProfile.name,
          picture: googleProfile.picture,
          role: defaultRole,
          fcmToken: fcmToken || null,
          lastLogin: new Date()
        }
      });
      logger.info(`Registered new user: ${user.email} as ${user.role}`);
    } else {
      // User exists, update login statistics and active push token
      user = await prisma.user.update({
        where: { id: user.id },
        data: {
          name: googleProfile.name,
          picture: googleProfile.picture,
          fcmToken: fcmToken || user.fcmToken,
          lastLogin: new Date()
        }
      });
      logger.info(`Authenticated returning user: ${user.email}`);
    }

    if (!user.isApproved) {
      return sendError(res, 403, 'Your account has been deactivated by administrators.');
    }

    // Generate JWT access and refresh tokens
    const tokenPayload = {
      userId: user.id,
      role: user.role,
      email: user.email,
      departmentId: user.departmentId
    };

    const accessToken = signAccessToken(tokenPayload);
    const refreshToken = signRefreshToken({ userId: user.id });

    // Store refresh token in db
    const expiry = new Date(Date.now() + 30 * 24 * 60 * 60 * 1000); // 30 days
    await prisma.refreshToken.create({
      data: {
        token: refreshToken,
        userId: user.id,
        expiresAt: expiry
      }
    });

    return sendSuccess(res, {
      accessToken,
      refreshToken,
      isNewUser,
      user: {
        id: user.id,
        email: user.email,
        name: user.name,
        picture: user.picture,
        role: user.role,
        departmentId: user.departmentId,
        zoneId: user.zoneId,
        createdAt: user.createdAt
      }
    });

  } catch (error) {
    next(error);
  }
});

/**
 * POST /api/auth/refresh
 * Rotates access token using a valid refresh token
 */
router.post('/refresh', validateBody(refreshSchema), async (req, res, next) => {
  try {
    const { refreshToken } = req.body;
    
    // Verify token validity
    const decoded = verifyToken(refreshToken);
    if (!decoded) {
      return sendError(res, 401, 'Invalid or expired refresh token.');
    }

    // Verify token exists in database
    const tokenRecord = await prisma.refreshToken.findUnique({
      where: { token: refreshToken }
    });

    if (!tokenRecord || tokenRecord.expiresAt < new Date()) {
      if (tokenRecord) {
        await prisma.refreshToken.delete({ where: { id: tokenRecord.id } });
      }
      return sendError(res, 401, 'Session has expired. Please log in again.');
    }

    // Get user details
    const user = await prisma.user.findUnique({
      where: { id: tokenRecord.userId }
    });

    if (!user || !user.isApproved) {
      return sendError(res, 401, 'Access denied: User account is inactive or not found.');
    }

    // Sign new access and refresh tokens
    const tokenPayload = {
      userId: user.id,
      role: user.role,
      email: user.email,
      departmentId: user.departmentId
    };

    const newAccessToken = signAccessToken(tokenPayload);
    const newRefreshToken = signRefreshToken({ userId: user.id });

    // Rotate refresh token in database
    await prisma.$transaction(async (tx) => {
      await tx.refreshToken.delete({ where: { id: tokenRecord.id } });
      await tx.refreshToken.create({
        data: {
          token: newRefreshToken,
          userId: user.id,
          expiresAt: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000)
        }
      });
    });

    return sendSuccess(res, {
      accessToken: newAccessToken,
      refreshToken: newRefreshToken
    });

  } catch (error) {
    next(error);
  }
});

/**
 * GET /api/auth/me
 * Retrieves current active user profile details
 */
router.get('/me', authenticate, async (req, res, next) => {
  try {
    const user = await prisma.user.findUnique({
      where: { id: req.user.id }
    });

    if (!user) {
      return sendError(res, 404, 'User profile not found.');
    }

    return sendSuccess(res, {
      id: user.id,
      email: user.email,
      name: user.name,
      picture: user.picture,
      role: user.role,
      departmentId: user.departmentId,
      zoneId: user.zoneId,
      createdAt: user.createdAt
    });
  } catch (error) {
    next(error);
  }
});

/**
 * POST /api/auth/logout
 * Revokes refresh token and clears push notification bindings
 */
router.post('/logout', authenticate, validateBody(logoutSchema), async (req, res, next) => {
  try {
    const { refreshToken } = req.body;

    // Delete refresh token from DB
    await prisma.refreshToken.deleteMany({
      where: {
        token: refreshToken,
        userId: req.user.id
      }
    });

    // Clear active FCM token to stop sending alerts to this device
    await prisma.user.update({
      where: { id: req.user.id },
      data: { fcmToken: null }
    });

    logger.info(`User ${req.user.email} logged out.`);
    return sendSuccess(res, { message: 'Successfully logged out.' });
  } catch (error) {
    next(error);
  }
});

module.exports = router;
