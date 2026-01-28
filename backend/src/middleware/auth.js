const jwt = require('jsonwebtoken');
const { unauthorized } = require('../utils/response');

/**
 * JWT Authentication Middleware
 */
const authenticate = (req, res, next) => {
  try {
    // Get token from header
    const authHeader = req.headers.authorization;
    
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return unauthorized(res, 'Token tidak ditemukan');
    }
    
    const token = authHeader.substring(7); // Remove 'Bearer ' prefix
    
    // Verify token
    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    
    // Attach user data to request
    req.user = {
      nik: decoded.nik,
      nama_panggilan: decoded.nama_panggilan
    };
    
    next();
  } catch (error) {
    if (error.name === 'TokenExpiredError') {
      return unauthorized(res, 'Token sudah kadaluarsa');
    }
    if (error.name === 'JsonWebTokenError') {
      return unauthorized(res, 'Token tidak valid');
    }
    return unauthorized(res, 'Autentikasi gagal');
  }
};

module.exports = { authenticate };
