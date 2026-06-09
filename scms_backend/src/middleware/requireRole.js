const { sendError } = require('../utils/responseHelper');

/**
 * Higher-order middleware guarding routes by user roles
 * @param {...string} allowedRoles - List of authorized roles (e.g., 'ROLE_ADMIN', 'ROLE_STAFF')
 */
const requireRole = (...allowedRoles) => {
  return (req, res, next) => {
    if (!req.user) {
      return sendError(res, 401, 'Unauthorized: User is not authenticated.');
    }

    if (!allowedRoles.includes(req.user.role)) {
      return sendError(
        res,
        403,
        'Forbidden: You do not have permission to access this resource.'
      );
    }

    next();
  };
};

module.exports = requireRole;
