-- Migration: Update transaksi_barter table with confirmation fields
-- Purpose: Add fields for tracking confirmations and completion
-- Date: 2026-01-16
-- FIXED: Updated to use transaksi_barter table name

ALTER TABLE transaksi_barter
ADD COLUMN IF NOT EXISTS konfirmasi_penawar BOOLEAN DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS konfirmasi_ditawar BOOLEAN DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS waktu_mulai TIMESTAMP NULL,
ADD COLUMN IF NOT EXISTS waktu_selesai TIMESTAMP NULL,
ADD COLUMN IF NOT EXISTS total_skillcoin_transfer INT DEFAULT 0;

-- Add index for confirmation queries
CREATE INDEX IF NOT EXISTS idx_konfirmasi ON transaksi_barter(konfirmasi_penawar, konfirmasi_ditawar);
CREATE INDEX IF NOT EXISTS idx_waktu_selesai ON transaksi_barter(waktu_selesai);
