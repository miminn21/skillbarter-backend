-- Check table structures to debug foreign key issue
-- Run these queries in MariaDB to see the mismatch

-- 1. Check pengguna table structure
SHOW CREATE TABLE pengguna;

-- 2. Check barter_confirmations table structure
SHOW CREATE TABLE barter_confirmations;

-- 3. Check column details
SELECT 
    COLUMN_NAME, 
    COLUMN_TYPE, 
    CHARACTER_SET_NAME, 
    COLLATION_NAME 
FROM INFORMATION_SCHEMA.COLUMNS 
WHERE TABLE_SCHEMA = 'skillbarter_db' 
  AND TABLE_NAME = 'pengguna' 
  AND COLUMN_NAME = 'nik';

SELECT 
    COLUMN_NAME, 
    COLUMN_TYPE, 
    CHARACTER_SET_NAME, 
    COLLATION_NAME 
FROM INFORMATION_SCHEMA.COLUMNS 
WHERE TABLE_SCHEMA = 'skillbarter_db' 
  AND TABLE_NAME = 'barter_confirmations' 
  AND COLUMN_NAME = 'nik';
