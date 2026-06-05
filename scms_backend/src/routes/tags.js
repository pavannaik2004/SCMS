const express = require('express');
const { PrismaClient } = require('@prisma/client');
const { sendSuccess } = require('../utils/responseHelper');
const authenticate = require('../middleware/authenticate');

const router = express.Router();
const prisma = new PrismaClient();

/**
 * GET /api/tags
 * Retrieves a list of all tags
 */
router.get('/', authenticate, async (req, res, next) => {
  try {
    const tags = await prisma.tag.findMany({
      orderBy: { name: 'asc' }
    });
    return sendSuccess(res, tags);
  } catch (error) {
    next(error);
  }
});

module.exports = router;
