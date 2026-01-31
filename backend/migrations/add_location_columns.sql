-- Add Location Columns to Pengguna Table
ALTER TABLE pengguna
ADD COLUMN latitude DECIMAL(10, 8) NULL,
ADD COLUMN longitude DECIMAL(11, 8) NULL,
ADD COLUMN last_location_update TIMESTAMP NULL;
