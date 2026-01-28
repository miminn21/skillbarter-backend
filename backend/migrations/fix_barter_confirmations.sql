-- FIX: Drop and recreate barter_confirmations with matching column specs
-- The issue is likely VARCHAR case sensitivity or collation mismatch

-- Drop existing table
DROP TABLE IF EXISTS barter_confirmations;

-- Recreate with exact same specs as pengguna.nik
-- pengguna.nik is likely VARCHAR(16) with utf8mb4_general_ci or similar
CREATE TABLE barter_confirmations (
  id_konfirmasi INT PRIMARY KEY AUTO_INCREMENT,
  id_barter INT NOT NULL,
  nik VARCHAR(16) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  konfirmasi_selesai BOOLEAN DEFAULT FALSE,
  catatan TEXT,
  waktu_konfirmasi TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  
  FOREIGN KEY (id_barter) REFERENCES transaksi_barter(id) ON DELETE CASCADE,
  FOREIGN KEY (nik) REFERENCES pengguna(nik) ON DELETE CASCADE,
  
  UNIQUE KEY unique_confirmation (id_barter, nik),
  INDEX idx_barter (id_barter),
  INDEX idx_nik (nik)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- Note: Changed from utf8mb4_unicode_ci to utf8mb4_general_ci to match pengguna table
