-- ============================================
-- MIGRATION: Add Skill Requests Table
-- ============================================
-- Run this to add skill request functionality to existing database

USE skillbarter_db;

-- Create skill_requests table
CREATE TABLE IF NOT EXISTS skill_requests (
    id INT PRIMARY KEY AUTO_INCREMENT,
    nik_pengguna VARCHAR(16) NOT NULL,
    id_kategori INT NOT NULL,
    nama_keahlian VARCHAR(100) NOT NULL,
    deskripsi_kebutuhan TEXT,
    tingkat_keahlian_diinginkan ENUM('pemula', 'menengah', 'mahir') DEFAULT 'menengah',
    durasi_estimasi VARCHAR(50),
    lokasi_preferensi VARCHAR(100),
    catatan_tambahan TEXT,
    status ENUM('terbuka', 'dipenuhi', 'dibatalkan') DEFAULT 'terbuka',
    dibuat_pada TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    diperbarui_pada TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    FOREIGN KEY (nik_pengguna) REFERENCES pengguna(nik) ON DELETE CASCADE,
    FOREIGN KEY (id_kategori) REFERENCES kategori_skill(id),
    
    INDEX idx_status (status),
    INDEX idx_kategori (id_kategori),
    INDEX idx_pengguna (nik_pengguna),
    INDEX idx_dibuat (dibuat_pada DESC)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Verify table created
SELECT 'skill_requests table created successfully!' as status;

-- Show table structure
DESCRIBE skill_requests;
