const express = require('express');
const cors = require('cors');
const path = require('path');
require('dotenv').config();

// Import database to test connection
require('./config/database');

// Import routes
const authRoutes = require('./routes/auth');
const profileRoutes = require('./routes/profile');
const skillRoutes = require('./routes/skill');
const barterRoutes = require('./routes/barter');
const exploreRoutes = require('./routes/explore');
const categoryRoutes = require('./routes/category');
const skillcoinRoutes = require('./routes/skillcoin');
const reviewRoutes = require('./routes/review');
const notificationRoutes = require('./routes/notification');
const chatRoutes = require('./routes/chat');
const helpRoutes = require('./routes/help');
const locationRoutes = require('./routes/location');

// Create Express app
const app = express();

// Middleware
app.use(cors());
// Increase limit for base64 images (default 100kb is too small)
app.use(express.json({ limit: '50mb' }));
app.use(express.urlencoded({ extended: true, limit: '50mb' }));

// Static files (for uploaded images if needed)
app.use('/uploads', express.static(path.join(__dirname, '../uploads')));

// API Routes
app.use('/api/auth', authRoutes);
app.use('/api/profile', profileRoutes);
app.use('/api', skillRoutes);
app.use('/api/barter', barterRoutes);
app.use('/api', exploreRoutes);
app.use('/api/categories', categoryRoutes);
app.use('/api/skillcoin', skillcoinRoutes);
app.use('/api/location', locationRoutes);
app.use('/api/reviews', reviewRoutes);
app.use('/api/notifications', notificationRoutes);
app.use('/api/chat', chatRoutes);
app.use('/api/help', helpRoutes);

// Health check
app.get('/health', (req, res) => {
  res.json({
    success: true,
    message: 'SkillBarter API is running',
    timestamp: new Date().toISOString()
  });
});

// 404 handler
app.use((req, res) => {
  res.status(404).json({
    success: false,
    message: 'Endpoint not found'
  });
});

// Error handler
app.use((err, req, res, next) => {
  console.error('Error:', err);
  
  // Multer error
  if (err.name === 'MulterError') {
    if (err.code === 'LIMIT_FILE_SIZE') {
      return res.status(400).json({
        success: false,
        message: 'File terlalu besar. Maksimal 5MB'
      });
    }
    return res.status(400).json({
      success: false,
      message: err.message
    });
  }
  
  res.status(500).json({
    success: false,
    message: err.message || 'Internal server error'
  });
});

module.exports = app;
