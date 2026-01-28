const bcrypt = require('bcrypt');
const fs = require('fs');
const path = require('path');
const User = require('../models/User');
const UserDetail = require('../models/UserDetail');
const { success, error } = require('../utils/response');

/**
 * Profile Controller
 */

/**
 * Update user profile
 * PUT /api/profile
 */
exports.updateProfile = async (req, res) => {
  try {
    const { nik } = req.user;
    const updateData = req.body;
    
    // Separate main profile and detail data
    const mainProfileData = {
      nama_lengkap: updateData.nama_lengkap,
      nama_panggilan: updateData.nama_panggilan,
      jenis_kelamin: updateData.jenis_kelamin,
      tanggal_lahir: updateData.tanggal_lahir,
      alamat_lengkap: updateData.alamat_lengkap,
      kota: updateData.kota,
      bio: updateData.bio
    };
    
    const detailData = {
      pekerjaan: updateData.pekerjaan,
      nama_instansi: updateData.nama_instansi,
      pendidikan_terakhir: updateData.pendidikan_terakhir,
      keahlian_khusus: updateData.keahlian_khusus,
      media_sosial: updateData.media_sosial,
      preferensi_lokasi: updateData.preferensi_lokasi,
      zona_waktu: updateData.zona_waktu,
      bahasa: updateData.bahasa
    };
    
    // Update main profile
    await User.update(nik, mainProfileData);
    
    // Update detail if any detail data provided
    const hasDetailData = Object.values(detailData).some(val => val !== undefined);
    if (hasDetailData) {
      await UserDetail.update(nik, detailData);
    }
    
    // Get updated user
    const updatedUser = await User.findByNik(nik);
    delete updatedUser.kata_sandi;
    
    // Convert BLOB to base64 if exists
    if (updatedUser.foto_profil) {
      updatedUser.foto_profil = updatedUser.foto_profil.toString('base64');
    }
    
    return success(res, 'Profile berhasil diperbarui', updatedUser);
    
  } catch (err) {
    console.error('Update profile error:', err);
    return error(res, 'Gagal memperbarui profile: ' + err.message);
  }
};

/**
 * Change password
 * PUT /api/profile/change-password
 */
exports.changePassword = async (req, res) => {
  try {
    const { nik } = req.user;
    const { kata_sandi_lama, kata_sandi_baru } = req.body;
    
    // Get user
    const user = await User.findByNik(nik);
    if (!user) {
      return error(res, 'User tidak ditemukan', 404);
    }
    
    // Verify old password
    const isPasswordValid = await bcrypt.compare(kata_sandi_lama, user.kata_sandi);
    if (!isPasswordValid) {
      return error(res, 'Password lama salah', 400);
    }
    
    // Hash new password
    const hashedPassword = await bcrypt.hash(kata_sandi_baru, 10);
    
    // Update password
    await User.updatePassword(nik, hashedPassword);
    
    return success(res, 'Password berhasil diubah');
    
  } catch (err) {
    console.error('Change password error:', err);
    return error(res, 'Gagal mengubah password: ' + err.message);
  }
};

/**
 * Upload profile photo
 * POST /api/profile/upload-photo
 */
exports.uploadPhoto = async (req, res) => {
  try {
    const { nik } = req.user;
    
    if (!req.file) {
      return error(res, 'File tidak ditemukan', 400);
    }
    
    // Read file as buffer
    const filePath = req.file.path;
    const fileBuffer = fs.readFileSync(filePath);
    const fileType = path.extname(req.file.originalname).substring(1);
    const fileSize = req.file.size;
    
    // Update photo in database
    await User.updatePhoto(nik, {
      foto_profil: fileBuffer,
      jenis_foto: fileType,
      ukuran_foto: fileSize
    });
    
    // Delete temporary file
    fs.unlinkSync(filePath);
    
    // Get updated user
    const updatedUser = await User.findByNik(nik);
    delete updatedUser.kata_sandi;
    
    // Convert BLOB to base64
    if (updatedUser.foto_profil) {
      updatedUser.foto_profil = updatedUser.foto_profil.toString('base64');
    }
    
    return success(res, 'Foto profil berhasil diupload', updatedUser);
    
  } catch (err) {
    console.error('Upload photo error:', err);
    
    // Delete temporary file if exists
    if (req.file && req.file.path) {
      try {
        fs.unlinkSync(req.file.path);
      } catch (unlinkErr) {
        console.error('Failed to delete temp file:', unlinkErr);
      }
    }
    
    return error(res, 'Gagal mengupload foto: ' + err.message);
  }
};

/**
 * Upload profile photo using base64
 * POST /api/profile/upload-photo-base64
 */
exports.uploadPhotoBase64 = async (req, res) => {
  try {
    const { nik } = req.user;
    const { foto_profil, jenis_foto } = req.body;
    
    if (!foto_profil) {
      return error(res, 'Foto tidak ditemukan', 400);
    }
    
    // Convert base64 to buffer
    const fileBuffer = Buffer.from(foto_profil, 'base64');
    const fileSize = fileBuffer.length;
    
    // Validate file size (max 5MB)
    if (fileSize > 5 * 1024 * 1024) {
      return error(res, 'Ukuran file terlalu besar (max 5MB)', 400);
    }
    
    // Update photo in database
    await User.updatePhoto(nik, {
      foto_profil: fileBuffer,
      jenis_foto: jenis_foto || 'jpg',
      ukuran_foto: fileSize
    });
    
    // Get updated user
    const updatedUser = await User.findByNik(nik);
    delete updatedUser.kata_sandi;
    
    // Convert BLOB to base64
    if (updatedUser.foto_profil) {
      updatedUser.foto_profil = updatedUser.foto_profil.toString('base64');
    }
    
    return success(res, 'Foto profil berhasil diupload', updatedUser);
    
  } catch (err) {
    console.error('Upload photo base64 error:', err);
    return error(res, 'Gagal mengupload foto: ' + err.message);
  }
};

module.exports = exports;
