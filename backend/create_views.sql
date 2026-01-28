-- ============================================
-- CREATE MISSING VIEWS FOR PHASE 3
-- ============================================

USE skillbarter_db;

-- View 1: rekomendasi_pencocokan
-- Matching skills dicari user dengan skills dikuasai others
CREATE OR REPLACE VIEW rekomendasi_pencocokan AS
SELECT 
    k_dicari.nik_pengguna AS nik_pencari,
    k_dikuasai.id AS id_keahlian_cocok,
    k_dikuasai.nik_pengguna AS nik_pemilik_keahlian,
    k_dikuasai.nama_keahlian,
    k_dikuasai.id_kategori,
    k_dikuasai.tingkat,
    k_dikuasai.harga_per_jam,
    k_dikuasai.status_verifikasi,
    ks.nama_kategori,
    -- Tingkat kecocokan berdasarkan kategori dan tingkat
    CASE 
        WHEN k_dicari.id_kategori = k_dikuasai.id_kategori AND k_dicari.tingkat = k_dikuasai.tingkat THEN 100
        WHEN k_dicari.id_kategori = k_dikuasai.id_kategori THEN 75
        ELSE 50
    END AS tingkat_kecocokan
FROM keahlian k_dicari
INNER JOIN keahlian k_dikuasai ON k_dicari.id_kategori = k_dikuasai.id_kategori
INNER JOIN kategori_skill ks ON k_dikuasai.id_kategori = ks.id
WHERE k_dicari.tipe = 'dicari'
  AND k_dikuasai.tipe = 'dikuasai'
  AND k_dicari.nik_pengguna != k_dikuasai.nik_pengguna;

-- View 2: peringkat_skillcoin
-- Leaderboard users by skillcoin balance
CREATE OR REPLACE VIEW peringkat_skillcoin AS
SELECT 
    ROW_NUMBER() OVER (ORDER BY p.saldo_skillcoin DESC, p.jumlah_transaksi DESC) AS peringkat,
    p.nik,
    p.nama_lengkap,
    p.nama_panggilan,
    p.foto_profil,
    p.saldo_skillcoin,
    p.jumlah_transaksi,
    p.total_jam_berkontribusi,
    p.rating_rata_rata
FROM pengguna p
WHERE p.status_aktif = TRUE
ORDER BY p.saldo_skillcoin DESC, p.jumlah_transaksi DESC;

-- Test views
SELECT 'View rekomendasi_pencocokan created' AS status;
SELECT 'View peringkat_skillcoin created' AS status;

-- Show sample data
SELECT * FROM peringkat_skillcoin LIMIT 10;
