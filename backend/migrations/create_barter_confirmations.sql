-- Migration: Create barter_confirmations table
-- Purpose: Track completion confirmations from both parties
-- Date: 2026-01-16
-- FIXED: Updated to use transaksi_barter(id) and pengguna(nik)

CREATE TABLE IF NOT EXISTS barter_confirmations (
  id_konfirmasi INT PRIMARY KEY AUTO_INCREMENT,
  id_barter INT NOT NULL,
  nik VARCHAR(16) NOT NULL,
  konfirmasi_selesai BOOLEAN DEFAULT FALSE,
  catatan TEXT,
  waktu_konfirmasi TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  
  FOREIGN KEY (id_barter) REFERENCES transaksi_barter(id) ON DELETE CASCADE,
  FOREIGN KEY (nik) REFERENCES pengguna(nik) ON DELETE CASCADE,
  
  UNIQUE KEY unique_confirmation (id_barter, nik),
  INDEX idx_barter (id_barter),
  INDEX idx_nik (nik)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
