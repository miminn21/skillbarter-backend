-- Check and fix the trigger issue
-- Run this in phpMyAdmin

USE skillbarter_db;

-- 1. Check if there are triggers on transaksi_barter
SHOW TRIGGERS WHERE `Table` = 'transaksi_barter';

-- 2. Check the pesan table structure
DESCRIBE pesan;

-- 3. Verify the NIK exists in pengguna table
SELECT nik, nama_lengkap FROM pengguna WHERE nik = '3206102104040002';
SELECT nik, nama_lengkap FROM pengguna WHERE nik = '3273010101010004';

-- 4. If trigger exists and causes issues, temporarily disable it
-- (We'll show the trigger first, then you can decide)

-- 5. Alternative: Fix the trigger to handle NULL or invalid NIK
-- This will be shown after we see the trigger code
