-- Migration: Create notifications table
-- Purpose: Store all user notifications for persistence
-- Date: 2026-01-16
-- FIXED: Updated to use pengguna(nik) lowercase

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
