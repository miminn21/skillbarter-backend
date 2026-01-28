const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');
const User = require('../models/User');
const UserDetail = require('../models/UserDetail');
const { success, error, validationError } = require('../utils/response');

/**
 * Authentication Controller
 */

/**
 * Register new user
 * POST /api/auth/register
 */
exports.register = async (req, res) => {
  try {
    const {
      nik, nama_lengkap, nama_panggilan, kata_sandi,
      jenis_kelamin, tanggal_lahir, alamat_lengkap, kota, bio
    } = req.body;
    
    // Check if user already exists
    const existingUser = await User.findByNik(nik);
    if (existingUser) {
      return error(res, 'NIK sudah terdaftar', 400);
    }
    
    // Hash password
    const hashedPassword = await bcrypt.hash(kata_sandi, 10);
    
    // Create user
    await User.create({
      nik,
      nama_lengkap,
      nama_panggilan,
      kata_sandi: hashedPassword,
      jenis_kelamin,
      tanggal_lahir,
      alamat_lengkap,
      kota,
      bio
    });
    
    // Create user detail (empty)
    await UserDetail.create(nik);
    
    // Get created user (trigger akan otomatis beri bonus 10 skillcoin)
    const newUser = await User.findByNik(nik);
    
    // Remove password from response
    delete newUser.kata_sandi;
    
    // Generate JWT token
    const token = jwt.sign(
      { nik: newUser.nik, nama_panggilan: newUser.nama_panggilan },
      process.env.JWT_SECRET,
      { expiresIn: process.env.JWT_EXPIRES_IN || '24h' }
    );
    
    return success(res, 'Registrasi berhasil', {
      user: newUser,
      token
    }, 201);
    
  } catch (err) {
    console.error('Register error:', err);
    return error(res, 'Registrasi gagal: ' + err.message);
  }
};

/**
 * Login user
 * POST /api/auth/login
 */
exports.login = async (req, res) => {
  try {
    const { nik, kata_sandi } = req.body;
    
    // Find user
    const user = await User.findByNik(nik);
    console.log(`[Login Debug] Login attempt for NIK: ${nik}`);
    
    if (!user) {
      console.log('[Login Debug] User not found');
      return error(res, 'NIK atau password salah', 401);
    }
    
    console.log('[Login Debug] User found:', user.nama_lengkap);
    // console.log('[Login Debug] Stored Hash:', user.kata_sandi); // Caution with logs
    
    // Check if account is active
    if (!user.status_aktif) {
      console.log('[Login Debug] Account inactive');
      return error(res, 'Akun Anda tidak aktif. Hubungi admin', 403);
    }
    
    // Verify password
    const isPasswordValid = await bcrypt.compare(kata_sandi, user.kata_sandi);
    console.log(`[Login Debug] Password valid: ${isPasswordValid}`);
    
    if (!isPasswordValid) {
      console.log('[Login Debug] Password mismatch');
      return error(res, 'NIK atau password salah', 401);
    }
    
    // Update last login and set online
    await User.updateLastLogin(nik);
    await User.updateOnlineStatus(nik, 'online');
    
    // Remove password from response
    delete user.kata_sandi;
    
    // Convert BLOB to base64 if exists
    if (user.foto_profil) {
      user.foto_profil = user.foto_profil.toString('base64');
    }
    
    // Generate JWT token
    const token = jwt.sign(
      { nik: user.nik, nama_panggilan: user.nama_panggilan },
      process.env.JWT_SECRET,
      { expiresIn: process.env.JWT_EXPIRES_IN || '24h' }
    );
    
    return success(res, 'Login berhasil', {
      user,
      token
    });
    
  } catch (err) {
    console.error('Login error:', err);
    return error(res, 'Login gagal: ' + err.message);
  }
};

/**
 * Get user profile
 * GET /api/auth/profile
 */
exports.getProfile = async (req, res) => {
  try {
    const { nik } = req.user;
    
    // Get user data
    const user = await User.findByNik(nik);
    if (!user) {
      return error(res, 'User tidak ditemukan', 404);
    }
    
    // Remove password
    delete user.kata_sandi;
    
    // Convert BLOB to base64 if exists
    if (user.foto_profil) {
      user.foto_profil = user.foto_profil.toString('base64');
    }
    
    return success(res, 'Profile berhasil diambil', user);
    
  } catch (err) {
    console.error('Get profile error:', err);
    return error(res, 'Gagal mengambil profile: ' + err.message);
  }
};

/**
 * Logout user
 * POST /api/auth/logout
 */
exports.logout = async (req, res) => {
  try {
    // In JWT, logout is handled on client side by removing token
    // But we update status to offline
    if (req.user && req.user.nik) {
      await User.updateOnlineStatus(req.user.nik, 'offline');
    } else if (req.body.nik) {
      // Fallback if auth middleware not used but NIK provided
      await User.updateOnlineStatus(req.body.nik, 'offline');
    }
    
    return success(res, 'Logout berhasil');
  } catch (err) {
    console.error('Logout error:', err);
    return error(res, 'Logout gagal: ' + err.message);
  }
};

/**
 * Heartbeat (Keep Active)
 * POST /api/auth/heartbeat
 */
exports.heartbeat = async (req, res) => {
  try {
    const { nik } = req.user;
    await User.updateOnlineStatus(nik, 'online');
    return success(res, 'Heartbeat received');
  } catch (err) {
    // Silent error for heartbeat
    console.error('Heartbeat error:', err.message);
    return error(res, 'Heartbeat failed', 500);
  }
};

/**
 * Update Status
 * POST /api/auth/status
 */
exports.updateStatus = async (req, res) => {
  try {
    const nik = req.user.nik;
    const { status } = req.body; // 'online' or 'offline'
    
    if (status !== 'online' && status !== 'offline') {
       return error(res, 'Status tidak valid', 400);
    }

    await User.updateOnlineStatus(nik, status);

    return success(res, 'Status updated');
  } catch (err) {
    console.error('Update status error:', err);
    return error(res, 'Terjadi kesalahan server: ' + err.message);
  }
};

module.exports = exports;
