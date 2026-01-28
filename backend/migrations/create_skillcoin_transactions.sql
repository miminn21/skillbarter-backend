-- Migration: Create skillcoin_transactions table
-- Purpose: Track all SkillCoin transfers between users
-- Date: 2026-01-16
-- FIXED: Updated to use transaksi_barter(id) and pengguna(nik)

CREATE TABLE IF NOT EXISTS skillcoin_transactions (
  id_transaksi INT PRIMARY KEY AUTO_INCREMENT,
  nik_pengirim VARCHAR(16),
  nik_penerima VARCHAR(16),
  id_barter INT,
  jumlah INT NOT NULL,
  tipe ENUM('transfer', 'reward', 'penalty', 'adjustment') NOT NULL DEFAULT 'transfer',
  keterangan TEXT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  
  FOREIGN KEY (nik_pengirim) REFERENCES pengguna(nik) ON DELETE SET NULL,
  FOREIGN KEY (nik_penerima) REFERENCES pengguna(nik) ON DELETE SET NULL,
  FOREIGN KEY (id_barter) REFERENCES transaksi_barter(id) ON DELETE SET NULL,
  
  INDEX idx_pengirim (nik_pengirim),
  INDEX idx_penerima (nik_penerima),
  INDEX idx_barter (id_barter),
  INDEX idx_created (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- Add initial SkillCoin to all existing users if they don't have any
UPDATE pengguna 
SET saldo_skillcoin = 100 
WHERE saldo_skillcoin IS NULL OR saldo_skillcoin < 10;
