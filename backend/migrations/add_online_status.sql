ALTER TABLE pengguna
ADD COLUMN status_online ENUM('online', 'offline') DEFAULT 'offline',
ADD COLUMN terakhir_aktif TIMESTAMP DEFAULT CURRENT_TIMESTAMP;

-- Set default values for existing users
UPDATE pengguna SET status_online = 'offline', terakhir_aktif = CURRENT_TIMESTAMP;
