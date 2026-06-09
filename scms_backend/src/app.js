const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');
const path = require('path');

const errorHandler = require('./middleware/errorHandler');

// Route imports
const authRouter = require('./routes/auth');
const complaintsRouter = require('./routes/complaints');
const srRouter = require('./routes/sr');
const analyticsRouter = require('./routes/analytics');
const aiRouter = require('./routes/ai');
const departmentsRouter = require('./routes/departments');
const categoriesRouter = require('./routes/categories');
const tagsRouter = require('./routes/tags');
const zonesRouter = require('./routes/zones');
const usersRouter = require('./routes/users');

const app = express();

// Enable CORS and security headers
app.use(cors());
app.use(helmet({
  crossOriginResourcePolicy: false // Allow serving local Storage assets to cross-origin requests
}));

// HTTP Logger
app.use(morgan('dev'));

// Payload Parsers
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Static Media Folder serving
app.use('/Storage', express.static(path.join(__dirname, '../Storage')));

// Register API Routes
app.use('/api/auth', authRouter);
app.use('/api/complaints', complaintsRouter);
app.use('/api/sr', srRouter);
app.use('/api/analytics', analyticsRouter);
app.use('/api/ai', aiRouter);
app.use('/api/departments', departmentsRouter);
app.use('/api/categories', categoriesRouter);
app.use('/api/tags', tagsRouter);
app.use('/api/zones', zonesRouter);
app.use('/api/users', usersRouter);

// Global Error Handler (must be registered after routes)
app.use(errorHandler);

module.exports = app;
