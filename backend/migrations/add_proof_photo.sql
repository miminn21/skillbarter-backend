-- Add proof photo support to barter confirmations
-- This enables users to upload proof of completion before confirmation

ALTER TABLE barter_confirmations
ADD COLUMN foto_bukti LONGTEXT COMMENT 'Base64 encoded proof photo' AFTER catatan;

ALTER TABLE barter_confirmations
ADD COLUMN waktu_upload_foto TIMESTAMP NULL COMMENT 'When proof photo was uploaded' AFTER foto_bukti;

-- Add index for querying confirmations with photos
ALTER TABLE barter_confirmations
ADD INDEX idx_foto_uploaded (id_barter, foto_bukti(100));

-- Verify changes
SELECT 
  COLUMN_NAME,
  COLUMN_TYPE,
  IS_NULLABLE,
  COLUMN_COMMENT
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'skillbarter_db'
  AND TABLE_NAME = 'barter_confirmations'
  AND COLUMN_NAME IN ('foto_bukti', 'waktu_upload_foto');
