-- ============================================
-- IMPROVED RECOMMENDATION MATCHING ALGORITHM
-- ============================================

USE skillbarter_db;

-- Drop old view if exists
DROP VIEW IF EXISTS rekomendasi_pencocokan;

-- Create improved view with scoring system
CREATE VIEW rekomendasi_pencocokan AS
SELECT 
    a.nik_pengguna AS pengguna_a,
    b.nik_pengguna AS pengguna_b,
    a.nama_keahlian AS keahlian_ditawarkan,
    b.nama_keahlian AS keahlian_dicari,
    k.nama_kategori,
    pa.nama_panggilan AS nama_a,
    pb.nama_panggilan AS nama_b,
    pa.kota AS kota_a,
    pb.kota AS kota_b,
    pa.rating_rata_rata AS rating_a,
    pb.rating_rata_rata AS rating_b,
    ABS(pa.rating_rata_rata - pb.rating_rata_rata) AS selisih_rating,
    
    -- SCORING SYSTEM (0-100)
    (
        -- Base score: kategori sama = 40 poin
        40 +
        
        -- Tingkat keahlian cocok = +30 poin
        CASE 
            WHEN a.tingkat = b.tingkat THEN 30
            WHEN (a.tingkat = 'mahir' AND b.tingkat = 'menengah') OR 
                 (a.tingkat = 'menengah' AND b.tingkat = 'mahir') THEN 20
            WHEN (a.tingkat = 'ahli' AND b.tingkat = 'mahir') OR 
                 (a.tingkat = 'mahir' AND b.tingkat = 'ahli') THEN 25
            ELSE 10
        END +
        
        -- Kota sama = +20 poin (lebih mudah ketemu)
        CASE WHEN LOWER(pa.kota) = LOWER(pb.kota) THEN 20 ELSE 0 END +
        
        -- Rating seimbang = +10 poin
        CASE 
            WHEN ABS(pa.rating_rata_rata - pb.rating_rata_rata) <= 0.5 THEN 10
            WHEN ABS(pa.rating_rata_rata - pb.rating_rata_rata) <= 1.0 THEN 5
            ELSE 0
        END
    ) AS skor_kecocokan,
    
    -- Status verifikasi
    a.status_verifikasi AS verifikasi_a,
    b.status_verifikasi AS verifikasi_b,
    
    -- Tingkat keahlian
    a.tingkat AS tingkat_a,
    b.tingkat AS tingkat_b
    
FROM keahlian a
INNER JOIN keahlian b ON a.id_kategori = b.id_kategori
INNER JOIN kategori_skill k ON a.id_kategori = k.id
INNER JOIN pengguna pa ON a.nik_pengguna = pa.nik
INNER JOIN pengguna pb ON b.nik_pengguna = pb.nik

WHERE 
    a.tipe = 'dikuasai' 
    AND b.tipe = 'dicari'
    AND a.nik_pengguna != b.nik_pengguna
    AND pa.status_aktif = TRUE
    AND pb.status_aktif = TRUE
    
ORDER BY skor_kecocokan DESC, selisih_rating ASC;

-- Test the view
SELECT * FROM rekomendasi_pencocokan LIMIT 5;

-- Show statistics
SELECT 
    COUNT(*) AS total_matches,
    AVG(skor_kecocokan) AS avg_score,
    MAX(skor_kecocokan) AS max_score,
    MIN(skor_kecocokan) AS min_score
FROM rekomendasi_pencocokan;
