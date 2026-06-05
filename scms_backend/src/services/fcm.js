const admin = require('firebase-admin');
const fs = require('fs');
const path = require('path');
const logger = require('../utils/logger');

const serviceAccountPath = process.env.FIREBASE_SERVICE_ACCOUNT_PATH || './firebase-service-account.json';
const resolvedPath = path.resolve(process.cwd(), serviceAccountPath);

let isInitialized = false;

try {
  if (fs.existsSync(resolvedPath)) {
    const serviceAccount = JSON.parse(fs.readFileSync(resolvedPath, 'utf8'));
    admin.initializeApp({
      credential: admin.credential.cert(serviceAccount)
    });
    isInitialized = true;
    logger.info('Firebase Admin successfully initialized.');
  } else {
    logger.warn(`Firebase service account not found at ${resolvedPath}. Running in FCM MOCK mode.`);
  }
} catch (error) {
  logger.error('Error initializing Firebase Admin:', error);
}

/**
 * Sends a push notification to a device token using Firebase Cloud Messaging
 * @param {string} token - Target device registration token
 * @param {string} title - Title of notification banner
 * @param {string} body - Message description text
 * @param {object} [dataPayload] - Optional string key-value payload deep-linking navigation
 * @returns {Promise<object>} Dispatch result status
 */
const sendPushNotification = async (token, title, body, dataPayload = {}) => {
  if (!token) {
    return { success: false, error: 'No device registration token provided.' };
  }

  // Convert all payload values to string as FCM data requires
  const stringifiedData = {};
  if (dataPayload) {
    for (const key of Object.keys(dataPayload)) {
      stringifiedData[key] = String(dataPayload[key]);
    }
  }

  if (!isInitialized) {
    logger.info(`[FCM MOCK DISPATCH] Token: "${token}" | Title: "${title}" | Body: "${body}"`, stringifiedData);
    return { success: true, mock: true };
  }

  try {
    const message = {
      notification: {
        title,
        body
      },
      data: stringifiedData,
      token
    };

    const messageId = await admin.messaging().send(message);
    logger.info(`FCM message dispatched successfully: ${messageId}`);
    return { success: true, messageId };
  } catch (error) {
    logger.error(`FCM message dispatch failed: ${error.message}`);
    return { success: false, error: error.message };
  }
};

module.exports = {
  sendPushNotification
};
