-- ============================================
-- ADD KATEGORI_SKILL TABLE IF NOT EXISTS
-- ============================================

USE skillbarter_db;

-- Create kategori_skill table
CREATE TABLE IF NOT EXISTS kategori_skill (
    id INT PRIMARY KEY AUTO_INCREMENT,
    nama_kategori VARCHAR(50) NOT NULL UNIQUE,
    ikon VARCHAR(50),
    deskripsi TEXT,
    urutan_tampil INT DEFAULT 0,
    status_aktif BOOLEAN DEFAULT TRUE,
    dibuat_pada TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    diperbarui_pada TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_status_aktif (status_aktif),
    INDEX idx_urutan (urutan_tampil)
);

-- Insert default categories if table is empty
INSERT IGNORE INTO kategori_skill (id, nama_kategori, ikon, deskripsi, urutan_tampil) VALUES
(1, 'Teknologi & IT', 'computer', 'Pemrograman, desain web, database, dan teknologi informasi', 1),
(2, 'Desain Grafis', 'palette', 'Desain UI/UX, ilustrasi, branding, dan desain visual', 2),
(3, 'Bahasa', 'language', 'Bahasa asing, penerjemahan, dan komunikasi', 3),
(4, 'Musik & Seni', 'music_note', 'Musik, seni rupa, fotografi, dan kreativitas', 4),
(5, 'Bisnis & Marketing', 'business_center', 'Pemasaran, penjualan, dan strategi bisnis', 5),
(6, 'Pendidikan', 'school', 'Mengajar, tutoring, dan pengembangan kurikulum', 6),
(7, 'Kesehatan & Olahraga', 'fitness_center', 'Fitness, yoga, nutrisi, dan kesehatan', 7),
(8, 'Masak & Kuliner', 'restaurant', 'Memasak, baking, dan seni kuliner', 8),
(9, 'Kerajinan Tangan', 'handyman', 'Kerajinan, DIY, dan keterampilan manual', 9),
(10, 'Lainnya', 'category', 'Kategori skill lainnya', 10);

-- Verify data
SELECT * FROM kategori_skill ORDER BY urutan_tampil;
