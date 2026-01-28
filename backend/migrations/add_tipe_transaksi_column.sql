-- Add tipe_transaksi column to transaksi_barter table
-- Run this in phpMyAdmin

USE skillbarter_db;

-- Check if column exists first
SET @col_exists = 0;
SELECT COUNT(*) INTO @col_exists 
FROM information_schema.COLUMNS 
WHERE TABLE_SCHEMA = 'skillbarter_db' 
  AND TABLE_NAME = 'transaksi_barter' 
  AND COLUMN_NAME = 'tipe_transaksi';

-- Add column if it doesn't exist
SET @query = IF(@col_exists = 0,
  'ALTER TABLE transaksi_barter ADD COLUMN tipe_transaksi ENUM(''barter'', ''bantuan'') NOT NULL DEFAULT ''barter'' AFTER id_keahlian_diminta',
  'SELECT ''Column tipe_transaksi already exists'' AS message'
);

PREPARE stmt FROM @query;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- Verify the column was added
DESCRIBE transaksi_barter;

SELECT 'Migration completed successfully!' AS status;
