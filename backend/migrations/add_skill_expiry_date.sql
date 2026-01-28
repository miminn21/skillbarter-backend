-- Add expiry date field for dicari skills
-- This allows users to set an expiration date for skills they're looking for

ALTER TABLE keahlian 
ADD COLUMN tanggal_berakhir DATE NULL 
COMMENT 'Tanggal berakhir untuk skill dicari (opsional)';

-- Add index for faster queries on expiry date
CREATE INDEX idx_tanggal_berakhir ON keahlian(tanggal_berakhir);

-- Verify the change
DESCRIBE keahlian;
