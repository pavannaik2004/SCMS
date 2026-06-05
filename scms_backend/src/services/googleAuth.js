const { OAuth2Client } = require('google-auth-library');
const { PrismaClient } = require('@prisma/client');

const prisma = new PrismaClient();
const client = new OAuth2Client(process.env.GOOGLE_CLIENT_ID);

/**
 * Verifies a Google idToken and ensures the domain matches allowed criteria
 * @param {string} idToken - Google-signed JWT
 * @returns {Promise<object>} Parsed Google profile containing { googleId, email, name, picture }
 */
const verifyGoogleToken = async (idToken) => {
  const ticket = await client.verifyIdToken({
    idToken,
    audience: process.env.GOOGLE_CLIENT_ID,
  });
  
  const payload = ticket.getPayload();
  if (!payload) {
    throw new Error('INVALID_TOKEN');
  }

  if (!payload.email_verified) {
    throw new Error('EMAIL_NOT_VERIFIED');
  }

  const email = payload.email;
  const domain = email.split('@')[1];

  // Layer 2 domain check: hardcoded default + PostgreSQL AllowedDomain overrides
  let isAllowed = domain === 'rvce.edu.in';

  if (!isAllowed) {
    const dbDomain = await prisma.allowedDomain.findUnique({
      where: { domain }
    });
    if (dbDomain) {
      isAllowed = true;
    }
  }

  if (!isAllowed) {
    throw new Error('DOMAIN_NOT_ALLOWED');
  }

  return {
    googleId: payload.sub,
    email: payload.email,
    name: payload.name,
    picture: payload.picture || null
  };
};

module.exports = {
  verifyGoogleToken
};
