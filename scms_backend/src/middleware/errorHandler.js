const logger = require('../utils/logger');
const { sendError } = require('../utils/responseHelper');

/**
 * Express error-handling middleware
 */
const errorHandler = (err, req, res, next) => {
  // Log the complete error stack trace
  logger.error(`${req.method} ${req.url} - Error: ${err.message}`, err);

  // Prisma error handling
  if (err.code && typeof err.code === 'string') {
    switch (err.code) {
      case 'P2002': // Unique constraint failure
        return sendError(res, 409, 'Conflict: A record with this unique value already exists.', err.meta);
      case 'P2025': // Record to update or delete not found
        return sendError(res, 404, 'Not Found: The requested record does not exist.');
      case 'P2003': // Foreign key constraint failure
        return sendError(res, 400, 'Bad Request: A foreign key constraint failed.', err.meta);
      default:
        return sendError(res, 500, `Database Error: ${err.message} (${err.code})`);
    }
  }

  // Zod validation errors
  if (err.name === 'ZodError') {
    return sendError(res, 400, 'Validation Error: Invalid input parameters.', err.errors);
  }

  const statusCode = err.status || err.statusCode || 500;
  const message = err.message || 'Internal Server Error';
  const details = process.env.NODE_ENV !== 'production' ? err.stack : null;

  return sendError(res, statusCode, message, details);
};

module.exports = errorHandler;
