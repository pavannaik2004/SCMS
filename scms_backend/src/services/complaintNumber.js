const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

/**
 * Generates a unique, incremental complaint number
 * Format: SCMS-YYYY-XXXXX (e.g., SCMS-2026-00042)
 * @returns {Promise<string>} Unique complaint number
 */
const generateComplaintNumber = async () => {
  const currentYear = new Date().getFullYear();
  
  // Count complaints matching the current year
  const count = await prisma.complaint.count({
    where: {
      complaintNumber: {
        startsWith: `SCMS-${currentYear}-`
      }
    }
  });

  const nextSequence = count + 1;
  const paddedSequence = String(nextSequence).padStart(5, '0');
  
  return `SCMS-${currentYear}-${paddedSequence}`;
};

module.exports = {
  generateComplaintNumber
};
