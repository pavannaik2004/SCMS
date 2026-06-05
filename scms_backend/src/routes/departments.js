const express = require('express');
const { PrismaClient } = require('@prisma/client');
const { sendSuccess } = require('../utils/responseHelper');
const authenticate = require('../middleware/authenticate');

const router = express.Router();
const prisma = new PrismaClient();

/**
 * GET /api/departments
 * Retrieves a list of all departments
 */
router.get('/', authenticate, async (req, res, next) => {
  try {
    const departments = await prisma.department.findMany({
      orderBy: { name: 'asc' }
    });
    return sendSuccess(res, departments);
  } catch (error) {
    next(error);
  }
});

module.exports = router;
