-- ============================================
-- MIGRATION: Add Skill Request Link to Barter Offers
-- ============================================
-- Phase 4: Barter Transaction System
-- Links barter offers to skill requests

USE skillbarter_db;

-- Add column to link skill requests
ALTER TABLE transaksi_barter 
ADD COLUMN id_skill_request INT NULL AFTER id_keahlian_diminta,
ADD CONSTRAINT fk_transaksi_skill_request 
    FOREIGN KEY (id_skill_request) 
    REFERENCES skill_requests(id) 
    ON DELETE SET NULL;

-- Add index for better query performance
CREATE INDEX idx_skill_request ON transaksi_barter(id_skill_request);

-- Verify changes
DESCRIBE transaksi_barter;

-- Show sample structure
SELECT 
    'Migration completed successfully!' as status,
    'transaksi_barter now linked to skill_requests' as description;
