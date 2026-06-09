/**
 * Standardized API response wrappers
 */

const sendSuccess = (res, data, status = 200) => {
  return res.status(status).json({
    success: true,
    data: data || null
  });
};

const sendError = (res, statusCode = 500, message = 'Internal Server Error', errorDetails = null) => {
  return res.status(statusCode).json({
    success: false,
    error: {
      message,
      code: statusCode,
      details: errorDetails
    }
  });
};

module.exports = {
  sendSuccess,
  sendError
};
