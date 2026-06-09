const { verifyToken } = require('../utils/jwtHelper');
const { sendError } = require('../utils/responseHelper');

/**
 * Middleware protecting routes by validating Bearer JWT
 */
const authenticate = (req, res, next) => {
  const authHeader = req.headers.authorization || req.headers.Authorization;

  if (!authHeader || typeof authHeader !== 'string' || !authHeader.startsWith('Bearer ')) {
    return sendError(res, 401, 'Unauthorized: Access token is missing or malformed.');
  }

  const token = authHeader.split(' ')[1];
  const decoded = verifyToken(token);

  if (!decoded) {
    return sendError(res, 401, 'Unauthorized: Access token has expired or is invalid.');
  }

  // Inject user info into request context
  req.user = {
    id: decoded.userId,
    role: decoded.role,
    email: decoded.email,
    departmentId: decoded.departmentId || null
  };

  next();
};

module.exports = authenticate;
