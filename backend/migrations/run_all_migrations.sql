-- Quick fix script: Run all migrations in correct order
-- All collations fixed to utf8mb4_general_ci to match pengguna table

USE skillbarter_db;

-- 1. SkillCoin Transactions
DROP TABLE IF EXISTS skillcoin_transactions;
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

-- 2. Barter Confirmations (already created successfully)
-- DROP TABLE IF EXISTS barter_confirmations;
-- Already exists with correct collation

-- 3. Reviews
DROP TABLE IF EXISTS reviews;
CREATE TABLE IF NOT EXISTS reviews (
  id_review INT PRIMARY KEY AUTO_INCREMENT,
  id_barter INT NOT NULL,
  nik_reviewer VARCHAR(16) NOT NULL,
  nik_reviewed VARCHAR(16) NOT NULL,
  rating INT NOT NULL CHECK (rating BETWEEN 1 AND 5),
  komentar TEXT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  
  FOREIGN KEY (id_barter) REFERENCES transaksi_barter(id) ON DELETE CASCADE,
  FOREIGN KEY (nik_reviewer) REFERENCES pengguna(nik) ON DELETE CASCADE,
  FOREIGN KEY (nik_reviewed) REFERENCES pengguna(nik) ON DELETE CASCADE,
  
  UNIQUE KEY unique_review (id_barter, nik_reviewer),
  INDEX idx_barter (id_barter),
  INDEX idx_reviewer (nik_reviewer),
  INDEX idx_reviewed (nik_reviewed),
  INDEX idx_rating (rating)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- 4. Notifications
DROP TABLE IF EXISTS notifications;
CREATE TABLE IF NOT EXISTS notifications (
  id_notifikasi INT PRIMARY KEY AUTO_INCREMENT,
  nik VARCHAR(16) NOT NULL,
  tipe ENUM(
    'offer_received', 
    'offer_accepted', 
    'offer_rejected', 
    'offer_cancelled', 
    'confirmation_needed', 
    'barter_completed',
    'review_received', 
    'skillcoin_received',
    'skillcoin_sent',
    'barter_started'
  ) NOT NULL,
  judul VARCHAR(255) NOT NULL,
  pesan TEXT NOT NULL,
  data JSON,
  is_read BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  
  FOREIGN KEY (nik) REFERENCES pengguna(nik) ON DELETE CASCADE,
  
  INDEX idx_nik_read (nik, is_read),
  INDEX idx_created (created_at),
  INDEX idx_tipe (tipe)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- 5. Update transaksi_barter table
ALTER TABLE transaksi_barter
ADD COLUMN IF NOT EXISTS konfirmasi_penawar BOOLEAN DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS konfirmasi_ditawar BOOLEAN DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS waktu_mulai TIMESTAMP NULL,
ADD COLUMN IF NOT EXISTS waktu_selesai TIMESTAMP NULL,
ADD COLUMN IF NOT EXISTS total_skillcoin_transfer INT DEFAULT 0;

CREATE INDEX IF NOT EXISTS idx_konfirmasi ON transaksi_barter(konfirmasi_penawar, konfirmasi_ditawar);
CREATE INDEX IF NOT EXISTS idx_waktu_selesai ON transaksi_barter(waktu_selesai);

-- 6. Initial SkillCoin for existing users
UPDATE pengguna 
SET saldo_skillcoin = 100 
WHERE saldo_skillcoin IS NULL OR saldo_skillcoin < 10;

SELECT 'All migrations completed successfully!' as status;
