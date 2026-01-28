-- Fix isi_pesan column issue in transaksi_barter table
-- Option 1: Make it nullable (RECOMMENDED)
-- Option 2: Remove it if not needed

USE skillbarter_db;

-- Check if column exists
SELECT COLUMN_NAME, IS_NULLABLE, COLUMN_DEFAULT, COLUMN_TYPE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'skillbarter_db'
  AND TABLE_NAME = 'transaksi_barter'
  AND COLUMN_NAME = 'isi_pesan';

-- If column exists and is NOT NULL, make it nullable:
ALTER TABLE transaksi_barter 
MODIFY COLUMN isi_pesan TEXT NULL;

-- Verify
DESCRIBE transaksi_barter;
