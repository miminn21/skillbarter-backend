-- Add tipe_transaksi column to support both barter and help request modes
-- This allows users to request help without offering their own skill

ALTER TABLE transaksi_barter 
ADD COLUMN tipe_transaksi ENUM('barter', 'bantuan') DEFAULT 'barter' 
COMMENT 'Tipe transaksi: barter (tukar skill) atau bantuan (minta bantuan dengan SkillCoin)';

-- Make id_keahlian_penawar nullable for help requests
ALTER TABLE transaksi_barter 
MODIFY COLUMN id_keahlian_penawar INT NULL 
COMMENT 'Skill yang ditawarkan (NULL untuk tipe bantuan)';

-- Add index for faster queries
CREATE INDEX idx_tipe_transaksi ON transaksi_barter(tipe_transaksi);

-- Verify changes
DESCRIBE transaksi_barter;
