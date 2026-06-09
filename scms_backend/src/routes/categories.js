const express = require('express');
const { PrismaClient } = require('@prisma/client');
const { sendSuccess } = require('../utils/responseHelper');
const authenticate = require('../middleware/authenticate');

const router = express.Router();
const prisma = new PrismaClient();

/**
 * GET /api/categories
 * Retrieves a list of all categories
 */
router.get('/', authenticate, async (req, res, next) => {
  try {
    const categories = await prisma.category.findMany({
      orderBy: { name: 'asc' }
    });
    return sendSuccess(res, categories);
  } catch (error) {
    next(error);
  }
});

module.exports = router;
