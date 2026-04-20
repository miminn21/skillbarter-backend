const app = require('../src/app');
const { initializeFCM } = require('../src/services/fcmService');

// Initialize Firebase Cloud Messaging for Vercel
initializeFCM();

module.exports = app;
