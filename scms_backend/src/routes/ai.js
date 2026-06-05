const express = require('express');
const { z } = require('zod');
const { sendSuccess } = require('../utils/responseHelper');
const authenticate = require('../middleware/authenticate');
const validateBody = require('../middleware/validateBody');
const { grammarCheck, categorize, checkDuplicate } = require('../services/aiProxy');

const router = express.Router();

const textSchema = z.object({
  text: z.string().min(1, 'Text parameter is required.')
});

const duplicateSchema = z.object({
  text: z.string().min(1, 'Text parameter is required.'),
  zoneId: z.string().optional()
});

/**
 * POST /api/ai/grammar-check
 * Requests grammatical corrections for draft complaints
 */
router.post('/grammar-check', authenticate, validateBody(textSchema), async (req, res, next) => {
  try {
    const result = await grammarCheck(req.body.text);
    return sendSuccess(res, result);
  } catch (error) {
    next(error);
  }
});

/**
 * POST /api/ai/categorize
 * Predicts category suggestions for draft complaints
 */
router.post('/categorize', authenticate, validateBody(textSchema), async (req, res, next) => {
  try {
    const result = await categorize(req.body.text);
    return sendSuccess(res, result);
  } catch (error) {
    next(error);
  }
});

/**
 * POST /api/ai/check-duplicate
 * Checks draft text against pgvector database similarity
 */
router.post('/check-duplicate', authenticate, validateBody(duplicateSchema), async (req, res, next) => {
  try {
    const { text, zoneId } = req.body;
    const result = await checkDuplicate(text, zoneId);
    return sendSuccess(res, result);
  } catch (error) {
    next(error);
  }
});

module.exports = router;
