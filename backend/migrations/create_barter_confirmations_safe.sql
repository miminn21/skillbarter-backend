-- Migration: Create barter_confirmations table (SAFE VERSION)
-- Purpose: Track completion confirmations from both parties
-- Date: 2026-01-16
-- FIXED: Check table existence and use correct references

-- First, verify transaksi_barter exists
-- If not, this migration will fail with clear error

CREATE TABLE IF NOT EXISTS barter_confirmations (
  id_konfirmasi INT PRIMARY KEY AUTO_INCREMENT,
  id_barter INT NOT NULL,
  nik VARCHAR(16) NOT NULL,
  konfirmasi_selesai BOOLEAN DEFAULT FALSE,
  catatan TEXT,
  waktu_konfirmasi TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  
  INDEX idx_barter (id_barter),
  INDEX idx_nik (nik),
  UNIQUE KEY unique_confirmation (id_barter, nik)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Add foreign keys separately (safer approach)
ALTER TABLE barter_confirmations
ADD CONSTRAINT fk_barter_conf_barter 
  FOREIGN KEY (id_barter) REFERENCES transaksi_barter(id) ON DELETE CASCADE;

ALTER TABLE barter_confirmations
ADD CONSTRAINT fk_barter_conf_user 
  FOREIGN KEY (nik) REFERENCES pengguna(nik) ON DELETE CASCADE;
