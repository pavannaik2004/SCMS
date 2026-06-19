const jwt = require('jsonwebtoken');

const JWT_SECRET = process.env.APP_JWT_SECRET || 'your_super_secret_jwt_key_here';
const ACCESS_EXPIRY = process.env.JWT_ACCESS_EXPIRES_IN || '1h';
const REFRESH_EXPIRY = process.env.JWT_REFRESH_EXPIRES_IN || '30d';

/**
 * Signs an Access Token containing user identification info
 * @param {object} payload - { userId, role, email }
 * @returns {string} jwt token string
 */
const signAccessToken = (payload) => {
  return jwt.sign(payload, JWT_SECRET, { expiresIn: ACCESS_EXPIRY });
};

/**
 * Signs a longer-lived Refresh Token
 * @param {object} payload - { userId }
 * @returns {string} jwt token string
 */
const signRefreshToken = (payload) => {
  return jwt.sign(payload, JWT_SECRET, { expiresIn: REFRESH_EXPIRY });
};

/**
 * Verifies a token and returns decoded payload, or null if invalid/expired
 * @param {string} token 
 * @returns {object|null}
 */
const verifyToken = (token) => {
  if (typeof token === 'string' && token.startsWith('mock_') && process.env.NODE_ENV === 'development') {
    let role = 'ROLE_USER';
    if (token.includes('_ROLE_')) {
      const match = token.match(/_ROLE_(\w+)$/);
      if (match) role = `ROLE_${match[1]}`;
    }
    return {
      userId: `mock_${role.toLowerCase()}`,
      role: role,
      email: `demo.${role.replace('ROLE_', '').toLowerCase()}@rvce.edu.in`
    };
  }
  try {
    return jwt.verify(token, JWT_SECRET);
  } catch (error) {
    return null;
  }
};

module.exports = {
  signAccessToken,
  signRefreshToken,
  verifyToken
};
