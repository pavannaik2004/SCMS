const { verifyToken } = require('../utils/jwtHelper');
const { sendError } = require('../utils/responseHelper');
const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

/**
 * Middleware protecting routes by validating Bearer JWT
 */
const authenticate = async (req, res, next) => {
  const authHeader = req.headers.authorization || req.headers.Authorization;

  if (!authHeader || typeof authHeader !== 'string' || !authHeader.startsWith('Bearer ')) {
    return sendError(res, 401, 'Unauthorized: Access token is missing or malformed.');
  }

  const token = authHeader.split(' ')[1];

  if (token.startsWith('mock_') && process.env.NODE_ENV === 'development') {
    const decoded = verifyToken(token);
    if (!decoded) {
      return sendError(res, 401, 'Unauthorized: Access token is invalid.');
    }

    try {
      let user = await prisma.user.findUnique({
        where: { email: decoded.email }
      });

      if (!user) {
        user = await prisma.user.create({
          data: {
            id: decoded.userId,
            googleId: `google_${decoded.userId}`,
            email: decoded.email,
            name: `Demo ${decoded.role.replace('ROLE_', '')}`,
            role: decoded.role,
            isApproved: true
          }
        });
      }

      req.user = {
        id: user.id,
        role: user.role,
        email: user.email,
        departmentId: user.departmentId || null
      };

      return next();
    } catch (error) {
      return next(error);
    }
  }

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
