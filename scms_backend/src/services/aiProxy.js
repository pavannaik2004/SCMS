const axios = require('axios');
const logger = require('../utils/logger');

const AI_BASE_URL = process.env.AI_SERVICE_URL || 'http://localhost:8000';

const client = axios.create({
  baseURL: AI_BASE_URL,
  timeout: 5000,
  headers: {
    'Content-Type': 'application/json'
  }
});

/**
 * Proxy grammar correction check to Python microservice
 * @param {string} text - User inputted description
 * @returns {Promise<object>} Grammar correction result with corrections and diffs
 */
const grammarCheck = async (text) => {
  try {
    const { data } = await client.post('/grammar-check', { text });
    return data;
  } catch (error) {
    logger.warn(`AI Proxy grammarCheck failed: ${error.message}. Returning safe defaults.`);
    return {
      hasCorrections: false,
      correctedText: text,
      diffs: []
    };
  }
};

/**
 * Proxy automatic category and urgency predictions
 * @param {string} text - User inputted description
 * @returns {Promise<object>} Category and severity suggestions
 */
const categorize = async (text) => {
  try {
    const { data } = await client.post('/categorize', { text });
    return data;
  } catch (error) {
    logger.warn(`AI Proxy categorize failed: ${error.message}. Returning safe defaults.`);
    return {
      suggestedCategory: 'Other',
      suggestedSeverity: 'MEDIUM',
      confidenceScore: 0.0,
      reasoning: 'AI service offline.'
    };
  }
};

/**
 * Proxy duplicate complaint search to pgvector similarity indexes
 * @param {string} text - Input text
 * @param {string} [zoneId] - Area filter
 * @param {string[]} [tags] - Tags filter
 * @returns {Promise<object>} List of duplicate match results
 */
const checkDuplicate = async (text, zoneId, tags = []) => {
  try {
    const { data } = await client.post('/check-duplicate', { text, zoneId, tags });
    return data;
  } catch (error) {
    logger.warn(`AI Proxy checkDuplicate failed: ${error.message}. Returning safe defaults.`);
    return {
      isDuplicate: false,
      similarCount: 0,
      topMatch: null,
      allMatches: []
    };
  }
};

/**
 * Trigger Python microservice to generate and update pgvector table
 * @param {string} text - Description
 * @param {string} complaintId - Target DB Primary Key
 * @returns {Promise<boolean>} Success status
 */
const generateAndStoreEmbedding = async (text, complaintId) => {
  try {
    const { data } = await client.post('/embed', { text, complaintId });
    return !!data.success;
  } catch (error) {
    logger.warn(`AI Proxy generateAndStoreEmbedding failed: ${error.message}.`);
    return false;
  }
};

module.exports = {
  grammarCheck,
  categorize,
  checkDuplicate,
  generateAndStoreEmbedding
};
