/**
 * Middleware validating request bodies using Zod schemas
 * @param {import('zod').ZodSchema} schema 
 */
const validateBody = (schema) => {
  return (req, res, next) => {
    try {
      req.body = schema.parse(req.body);
      next();
    } catch (error) {
      // Pass validation failures to global errorHandler middleware
      next(error);
    }
  };
};

module.exports = validateBody;
