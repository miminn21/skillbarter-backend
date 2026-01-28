-- Migration: Create reviews table
-- Purpose: Store ratings and reviews after barter completion
-- Date: 2026-01-16
-- FIXED: Updated to use transaksi_barter(id) and pengguna(nik)

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
