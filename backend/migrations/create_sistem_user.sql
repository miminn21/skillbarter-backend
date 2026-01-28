-- Create SISTEM user to fix Foreign Key error in triggers
-- Run this in phpMyAdmin

USE skillbarter_db;

-- Insert 'SISTEM' user into pengguna table
-- This is required because the triggers refer to 'SISTEM' as nik_pengirim
INSERT INTO pengguna (
    nik, 
    nama_lengkap, 
    nama_panggilan, 
    kata_sandi, 
    jenis_kelamin, 
    tanggal_lahir, 
    alamat_lengkap, 
    kota, 
    bio
) VALUES (
    'SISTEM', 
    'System Notification', 
    'System', 
    '$2b$10$SYSTEMACCOUNTLOCKEDDONOTUSE99', -- Dummy hash
    'L', 
    '2000-01-01', 
    'System Internal', 
    'System', 
    'Official System Account'
);

-- Verify insertion
SELECT nik, nama_lengkap FROM pengguna WHERE nik = 'SISTEM';
