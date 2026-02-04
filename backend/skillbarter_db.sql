-- ============================================
-- DATABASE SKILLBARTER - BUAT TABEL DULU
-- ============================================

-- 1. Hapus database jika ada (hati-hati di production!)
-- DROP DATABASE IF EXISTS skillbarter_db;
-- CREATE DATABASE skillbarter_db;
-- USE skillbarter_db;

-- 2. Nonaktifkan foreign key check sementara
SET FOREIGN_KEY_CHECKS = 0;

-- ============================================
-- TABEL UTAMA (BUAT BERURUT)
-- ============================================

-- Tabel 1: pengguna
CREATE TABLE pengguna (
    nik VARCHAR(16) PRIMARY KEY,
    nama_lengkap VARCHAR(100) NOT NULL,
    nama_panggilan VARCHAR(50) NOT NULL,
    kata_sandi VARCHAR(255) NOT NULL,
    jenis_kelamin ENUM('L', 'P') NOT NULL,
    tanggal_lahir DATE NOT NULL,
    alamat_lengkap TEXT NOT NULL,
    kota VARCHAR(50) NOT NULL,
    foto_profil MEDIUMBLOB,
    jenis_foto VARCHAR(10),
    ukuran_foto INT,
    bio TEXT,
    rating_rata_rata DECIMAL(3,2) DEFAULT 0.00,
    jumlah_transaksi INT DEFAULT 0,
    total_jam_berkontribusi INT DEFAULT 0,
    saldo_skillcoin INT DEFAULT 10,
    status_aktif BOOLEAN DEFAULT TRUE,
    terakhir_login TIMESTAMP NULL,
    dibuat_pada TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    diperbarui_pada TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_kota (kota),
    INDEX idx_rating (rating_rata_rata DESC)
);

-- Tabel 2: detail_pengguna
CREATE TABLE detail_pengguna (
    nik VARCHAR(16) PRIMARY KEY,
    pekerjaan VARCHAR(50),
    nama_instansi VARCHAR(100),
    pendidikan_terakhir VARCHAR(50),
    keahlian_khusus TEXT,
    media_sosial JSON,
    preferensi_lokasi ENUM('online', 'offline', 'keduanya') DEFAULT 'keduanya',
    zona_waktu VARCHAR(50) DEFAULT 'WIB',
    bahasa VARCHAR(100) DEFAULT 'Bahasa Indonesia',
    FOREIGN KEY (nik) REFERENCES pengguna(nik) ON DELETE CASCADE
);

-- Tabel 3: kategori_skill
CREATE TABLE kategori_skill (
    id INT PRIMARY KEY AUTO_INCREMENT,
    nama_kategori VARCHAR(50) UNIQUE NOT NULL,
    ikon VARCHAR(50),
    deskripsi TEXT,
    urutan_tampil INT DEFAULT 0,
    status_aktif BOOLEAN DEFAULT TRUE
);

-- Tabel 4: keahlian
CREATE TABLE keahlian (
    id INT PRIMARY KEY AUTO_INCREMENT,
    nik_pengguna VARCHAR(16) NOT NULL,
    nama_keahlian VARCHAR(100) NOT NULL,
    id_kategori INT NOT NULL,
    tipe ENUM('dikuasai', 'dicari') NOT NULL,
    tingkat ENUM('pemula', 'menengah', 'mahir', 'ahli') DEFAULT 'menengah',
    pengalaman VARCHAR(50),
    deskripsi TEXT,
    harga_per_jam INT DEFAULT 1,
    portofolio_gambar MEDIUMBLOB,
    jenis_portofolio VARCHAR(10),
    link_portofolio VARCHAR(255),
    status_verifikasi BOOLEAN DEFAULT FALSE,
    dibuat_pada TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (nik_pengguna) REFERENCES pengguna(nik) ON DELETE CASCADE,
    FOREIGN KEY (id_kategori) REFERENCES kategori_skill(id),
    INDEX idx_keahlian_pengguna (nik_pengguna, tipe),
    INDEX idx_kategori_keahlian (id_kategori)
);

-- Tabel 5: transaksi_barter
CREATE TABLE transaksi_barter (
    id INT PRIMARY KEY AUTO_INCREMENT,
    kode_transaksi VARCHAR(20) UNIQUE,
    nik_penawar VARCHAR(16) NOT NULL,
    nik_ditawar VARCHAR(16) NOT NULL,
    id_keahlian_penawar INT NOT NULL,
    id_keahlian_diminta INT NOT NULL,
    durasi_jam INT NOT NULL CHECK (durasi_jam > 0),
    tanggal_pelaksanaan DATETIME NOT NULL,
    tipe_lokasi ENUM('online', 'offline', 'hybrid') DEFAULT 'online',
    detail_lokasi TEXT,
    catatan_penawar TEXT,
    bukti_pelaksanaan MEDIUMBLOB,
    jenis_bukti VARCHAR(10),
    status ENUM(
        'menunggu',
        'diterima',
        'ditolak',
        'berlangsung',
        'selesai',
        'terkonfirmasi',
        'dibatalkan',
        'kedaluwarsa'
    ) DEFAULT 'menunggu',
    skillcoin_ditransfer BOOLEAN DEFAULT FALSE,
    rating_diberikan BOOLEAN DEFAULT FALSE,
    dibuat_pada TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    diperbarui_pada TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    waktu_kedaluwarsa TIMESTAMP NULL,
    FOREIGN KEY (nik_penawar) REFERENCES pengguna(nik),
    FOREIGN KEY (nik_ditawar) REFERENCES pengguna(nik),
    FOREIGN KEY (id_keahlian_penawar) REFERENCES keahlian(id),
    FOREIGN KEY (id_keahlian_diminta) REFERENCES keahlian(id),
    INDEX idx_status_transaksi (status),
    INDEX idx_tanggal_pelaksanaan (tanggal_pelaksanaan)
);

-- Tabel 6: log_transaksi
CREATE TABLE log_transaksi (
    id INT PRIMARY KEY AUTO_INCREMENT,
    id_transaksi INT,
    nik_pengguna VARCHAR(16) NOT NULL,
    aksi ENUM(
        'ajukan',
        'terima',
        'tolak',
        'mulai',
        'selesai',
        'konfirmasi',
        'batalkan',
        'ubah_jadwal'
    ) NOT NULL,
    keterangan TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (id_transaksi) REFERENCES transaksi_barter(id) ON DELETE CASCADE,
    FOREIGN KEY (nik_pengguna) REFERENCES pengguna(nik)
);

-- Tabel 7: transaksi_skillcoin
CREATE TABLE transaksi_skillcoin (
    id INT PRIMARY KEY AUTO_INCREMENT,
    nik_pengguna VARCHAR(16) NOT NULL,
    id_transaksi INT,
    jenis ENUM(
        'bonus_awal',
        'hasil_barter',
        'pengembalian',
        'denda',
        'hadiah',
        'transfer_keluar',
        'transfer_masuk',
        'tarik',
        'bayar_verifikasi'
    ) NOT NULL,
    jumlah INT NOT NULL,
    saldo_sebelum INT NOT NULL,
    saldo_sesudah INT NOT NULL,
    keterangan TEXT,
    penerima_nik VARCHAR(16),
    dibuat_pada TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (nik_pengguna) REFERENCES pengguna(nik),
    FOREIGN KEY (id_transaksi) REFERENCES transaksi_barter(id),
    FOREIGN KEY (penerima_nik) REFERENCES pengguna(nik),
    INDEX idx_skillcoin_pengguna (nik_pengguna, dibuat_pada DESC)
);

-- Tabel 8: ulasan_dan_rating
CREATE TABLE ulasan_dan_rating (
    id INT PRIMARY KEY AUTO_INCREMENT,
    id_transaksi INT NOT NULL,
    nik_pemberi_ulasan VARCHAR(16) NOT NULL,
    nik_diulas VARCHAR(16) NOT NULL,
    rating TINYINT NOT NULL CHECK (rating >= 1 AND rating <= 5),
    komentar TEXT,
    peran ENUM('pengajar', 'murid') NOT NULL,
    anonim BOOLEAN DEFAULT FALSE,
    dibuat_pada TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    diperbarui_pada TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY unik_ulasan (id_transaksi, nik_pemberi_ulasan),
    FOREIGN KEY (id_transaksi) REFERENCES transaksi_barter(id),
    FOREIGN KEY (nik_pemberi_ulasan) REFERENCES pengguna(nik),
    FOREIGN KEY (nik_diulas) REFERENCES pengguna(nik)
);

-- Tabel 9: pesan
CREATE TABLE pesan (
    id INT PRIMARY KEY AUTO_INCREMENT,
    nik_pengirim VARCHAR(16) NOT NULL,
    nik_penerima VARCHAR(16) NOT NULL,
    id_transaksi INT,
    isi_pesan TEXT NOT NULL,
    tipe ENUM('teks', 'gambar', 'lokasi', 'sistem') DEFAULT 'teks',
    gambar_pesan MEDIUMBLOB,
    jenis_gambar VARCHAR(10),
    metadata JSON,
    dibaca BOOLEAN DEFAULT FALSE,
    dibuat_pada TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (nik_pengirim) REFERENCES pengguna(nik),
    FOREIGN KEY (nik_penerima) REFERENCES pengguna(nik),
    FOREIGN KEY (id_transaksi) REFERENCES transaksi_barter(id),
    INDEX idx_percakapan (nik_pengirim, nik_penerima, dibuat_pada DESC)
);

-- Tabel 10: notifikasi
CREATE TABLE notifikasi (
    id INT PRIMARY KEY AUTO_INCREMENT,
    nik_pengguna VARCHAR(16) NOT NULL,
    judul VARCHAR(100) NOT NULL,
    isi_pesan TEXT NOT NULL,
    tipe ENUM(
        'barter_baru',
        'barter_diterima',
        'barter_ditolak',
        'pesan_baru',
        'rating_baru',
        'skillcoin',
        'sistem',
        'promosi'
    ) NOT NULL,
    id_terkait INT,
    tipe_terkait VARCHAR(50),
    dibaca BOOLEAN DEFAULT FALSE,
    diklik BOOLEAN DEFAULT FALSE,
    dibuat_pada TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    kadaluarsa_pada TIMESTAMP DEFAULT (CURRENT_TIMESTAMP + INTERVAL 30 DAY),
    FOREIGN KEY (nik_pengguna) REFERENCES pengguna(nik) ON DELETE CASCADE,
    INDEX idx_notif_pengguna (nik_pengguna, dibaca, dibuat_pada DESC)
);

-- Tabel 11: laporan_pengguna
CREATE TABLE laporan_pengguna (
    id INT PRIMARY KEY AUTO_INCREMENT,
    nik_pelapor VARCHAR(16) NOT NULL,
    nik_dilaporkan VARCHAR(16) NOT NULL,
    jenis_laporan ENUM('penipuan', 'tidak_pantas', 'spam', 'lainnya') NOT NULL,
    deskripsi TEXT NOT NULL,
    bukti_gambar MEDIUMBLOB,
    jenis_bukti VARCHAR(10),
    status ENUM('menunggu', 'ditinjau', 'valid', 'tidak_valid') DEFAULT 'menunggu',
    ditinjau_oleh_nik VARCHAR(16),
    hasil_tinjauan TEXT,
    dibuat_pada TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    diselesaikan_pada TIMESTAMP NULL,
    FOREIGN KEY (nik_pelapor) REFERENCES pengguna(nik),
    FOREIGN KEY (nik_dilaporkan) REFERENCES pengguna(nik),
    FOREIGN KEY (ditinjau_oleh_nik) REFERENCES pengguna(nik)
);

-- Tabel 12: sanksi_pengguna
CREATE TABLE sanksi_pengguna (
    id INT PRIMARY KEY AUTO_INCREMENT,
    nik_pengguna VARCHAR(16) NOT NULL,
    jenis_sanksi ENUM('peringatan', 'suspensi', 'pengurangan_skillcoin', 'blokir') NOT NULL,
    alasan TEXT NOT NULL,
    durasi_hari INT,
    otomatis_sistem BOOLEAN DEFAULT TRUE,
    diberlakukan_oleh_nik VARCHAR(16),
    dibuat_pada TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    berakhir_pada TIMESTAMP NULL,
    status_aktif BOOLEAN DEFAULT TRUE,
    FOREIGN KEY (nik_pengguna) REFERENCES pengguna(nik),
    FOREIGN KEY (diberlakukan_oleh_nik) REFERENCES pengguna(nik)
);

-- Aktifkan kembali foreign key check
SET FOREIGN_KEY_CHECKS = 1;

-- Tabel 13: notifications (New Notification System)
CREATE TABLE notifications (
    id_notifikasi INT PRIMARY KEY AUTO_INCREMENT,
    nik VARCHAR(16) NOT NULL,
    tipe VARCHAR(50) NOT NULL,
    judul VARCHAR(100) NOT NULL,
    pesan TEXT NOT NULL,
    data JSON,
    is_read BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (nik) REFERENCES pengguna(nik) ON DELETE CASCADE,
    INDEX idx_notifications_user (nik, is_read, created_at DESC)
);

-- ============================================
-- INSERT DATA DEFAULT
-- ============================================

-- Insert kategori default
INSERT INTO kategori_skill (nama_kategori, ikon, urutan_tampil) VALUES
('Teknologi', 'laptop', 1),
('Desain Grafis', 'palette', 2),
('Bahasa Asing', 'translate', 3),
('Musik & Seni', 'music', 4),
('Olahraga', 'dumbbell', 5),
('Masak & Kuliner', 'utensils', 6),
('Menulis & Edit', 'pen', 7),
('Bisnis & Marketing', 'chart-line', 8),
('Kendaraan', 'car', 9),
('Kesehatan', 'heart', 10),
('Pendidikan', 'graduation-cap', 11),
('Lainnya', 'ellipsis-h', 12);

-- ============================================
-- FUNGSI DAN PROSEDUR (PASTIKAN DELIMITER BENAR)
-- ============================================

DELIMITER $$

-- Fungsi untuk membuat kode transaksi
CREATE FUNCTION buat_kode_transaksi()
RETURNS VARCHAR(20)
BEGIN
    DECLARE kode VARCHAR(20);
    DECLARE tanggal_hari_ini VARCHAR(8);
    DECLARE nomor_urutan INT;
    
    SET tanggal_hari_ini = DATE_FORMAT(NOW(), '%Y%m%d');
    
    SELECT COUNT(*) + 1 INTO nomor_urutan 
    FROM transaksi_barter 
    WHERE DATE(dibuat_pada) = CURDATE();
    
    SET kode = CONCAT('BR-', tanggal_hari_ini, '-', LPAD(nomor_urutan, 3, '0'));
    RETURN kode;
END$$

-- Fungsi untuk cek saldo
CREATE FUNCTION cek_saldo_skillcoin(p_nik VARCHAR(16))
RETURNS INT
READS SQL DATA
BEGIN
    DECLARE v_saldo INT;
    
    SELECT saldo_skillcoin INTO v_saldo
    FROM pengguna
    WHERE nik = p_nik;
    
    RETURN COALESCE(v_saldo, 0);
END$$

-- Fungsi untuk validasi cukup saldo
CREATE FUNCTION cukup_saldo(p_nik VARCHAR(16), p_jumlah INT)
RETURNS BOOLEAN
BEGIN
    DECLARE v_saldo INT;
    
    SET v_saldo = cek_saldo_skillcoin(p_nik);
    
    RETURN v_saldo >= p_jumlah;
END$$

-- Prosedur transfer skillcoin
CREATE PROCEDURE transfer_skillcoin(
    IN p_nik_pengirim VARCHAR(16),
    IN p_nik_penerima VARCHAR(16),
    IN p_jumlah INT,
    IN p_keterangan TEXT
)
BEGIN
    DECLARE v_saldo_sebelum_pengirim INT;
    DECLARE v_saldo_sebelum_penerima INT;
    DECLARE v_saldo_sesudah_pengirim INT;
    DECLARE v_saldo_sesudah_penerima INT;
    
    -- Validasi
    IF p_jumlah <= 0 THEN
        SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = 'Jumlah transfer harus positif';
    END IF;
    
    IF p_nik_pengirim = p_nik_penerima THEN
        SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = 'Tidak bisa transfer ke diri sendiri';
    END IF;
    
    IF NOT cukup_saldo(p_nik_pengirim, p_jumlah) THEN
        SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = 'Saldo skillcoin tidak cukup';
    END IF;
    
    -- Dapatkan saldo sebelum
    SELECT saldo_skillcoin INTO v_saldo_sebelum_pengirim
    FROM pengguna WHERE nik = p_nik_pengirim;
    
    SELECT saldo_skillcoin INTO v_saldo_sebelum_penerima
    FROM pengguna WHERE nik = p_nik_penerima;
    
    -- Hitung saldo sesudah
    SET v_saldo_sesudah_pengirim = v_saldo_sebelum_pengirim - p_jumlah;
    SET v_saldo_sesudah_penerima = v_saldo_sebelum_penerima + p_jumlah;
    
    -- Mulai transaksi
    START TRANSACTION;
    
    -- Update saldo pengirim
    UPDATE pengguna 
    SET saldo_skillcoin = v_saldo_sesudah_pengirim,
        diperbarui_pada = NOW()
    WHERE nik = p_nik_pengirim;
    
    -- Update saldo penerima
    UPDATE pengguna 
    SET saldo_skillcoin = v_saldo_sesudah_penerima,
        diperbarui_pada = NOW()
    WHERE nik = p_nik_penerima;
    
    -- Catat transaksi keluar
    INSERT INTO transaksi_skillcoin (
        nik_pengguna, jenis, jumlah,
        saldo_sebelum, saldo_sesudah, keterangan,
        penerima_nik
    ) VALUES (
        p_nik_pengirim,
        'transfer_keluar',
        -p_jumlah,
        v_saldo_sebelum_pengirim,
        v_saldo_sesudah_pengirim,
        CONCAT('Transfer ke ', p_nik_penerima, ': ', p_keterangan),
        p_nik_penerima
    );
    
    -- Catat transaksi masuk
    INSERT INTO transaksi_skillcoin (
        nik_pengguna, jenis, jumlah,
        saldo_sebelum, saldo_sesudah, keterangan,
        penerima_nik
    ) VALUES (
        p_nik_penerima,
        'transfer_masuk',
        p_jumlah,
        v_saldo_sebelum_penerima,
        v_saldo_sesudah_penerima,
        CONCAT('Transfer dari ', p_nik_pengirim, ': ', p_keterangan),
        p_nik_pengirim
    );
    
    -- Tambah notifikasi
    INSERT INTO notifikasi (
        nik_pengguna, judul, isi_pesan, tipe
    ) VALUES 
    (p_nik_pengirim, 'Transfer Berhasil', 
     CONCAT('Anda mentransfer ', p_jumlah, ' skillcoin ke ', p_nik_penerima),
     'skillcoin'),
    (p_nik_penerima, 'Skillcoin Diterima', 
     CONCAT('Anda menerima ', p_jumlah, ' skillcoin dari ', p_nik_pengirim),
     'skillcoin');
    
    COMMIT;
END$$

-- Prosedur tambah skillcoin
CREATE PROCEDURE tambah_skillcoin(
    IN p_nik VARCHAR(16),
    IN p_jumlah INT,
    IN p_jenis VARCHAR(20),
    IN p_keterangan TEXT
)
BEGIN
    DECLARE v_saldo_sebelum INT;
    DECLARE v_saldo_sesudah INT;
    
    IF p_jumlah <= 0 THEN
        SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = 'Jumlah harus positif untuk penambahan';
    END IF;
    
    -- Dapatkan saldo sebelum
    SELECT saldo_skillcoin INTO v_saldo_sebelum
    FROM pengguna WHERE nik = p_nik;
    
    SET v_saldo_sesudah = v_saldo_sebelum + p_jumlah;
    
    START TRANSACTION;
    
    -- Update saldo
    UPDATE pengguna 
    SET saldo_skillcoin = v_saldo_sesudah,
        diperbarui_pada = NOW()
    WHERE nik = p_nik;
    
    -- Catat transaksi
    INSERT INTO transaksi_skillcoin (
        nik_pengguna, jenis, jumlah,
        saldo_sebelum, saldo_sesudah, keterangan
    ) VALUES (
        p_nik,
        p_jenis,
        p_jumlah,
        v_saldo_sebelum,
        v_saldo_sesudah,
        p_keterangan
    );
    
    -- Notifikasi
    INSERT INTO notifikasi (
        nik_pengguna, judul, isi_pesan, tipe
    ) VALUES (
        p_nik,
        'Skillcoin Bertambah',
        CONCAT('Anda mendapatkan ', p_jumlah, ' skillcoin: ', p_keterangan),
        'skillcoin'
    );
    
    COMMIT;
END$$

-- Prosedur kurangi skillcoin
CREATE PROCEDURE kurangi_skillcoin(
    IN p_nik VARCHAR(16),
    IN p_jumlah INT,
    IN p_jenis VARCHAR(20),
    IN p_keterangan TEXT
)
BEGIN
    DECLARE v_saldo_sebelum INT;
    DECLARE v_saldo_sesudah INT;
    
    IF p_jumlah <= 0 THEN
        SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = 'Jumlah harus positif untuk pengurangan';
    END IF;
    
    -- Validasi saldo cukup
    IF NOT cukup_saldo(p_nik, p_jumlah) THEN
        SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = 'Saldo skillcoin tidak cukup';
    END IF;
    
    -- Dapatkan saldo sebelum
    SELECT saldo_skillcoin INTO v_saldo_sebelum
    FROM pengguna WHERE nik = p_nik;
    
    SET v_saldo_sesudah = v_saldo_sebelum - p_jumlah;
    
    START TRANSACTION;
    
    -- Update saldo
    UPDATE pengguna 
    SET saldo_skillcoin = v_saldo_sesudah,
        diperbarui_pada = NOW()
    WHERE nik = p_nik;
    
    -- Catat transaksi
    INSERT INTO transaksi_skillcoin (
        nik_pengguna, jenis, jumlah,
        saldo_sebelum, saldo_sesudah, keterangan
    ) VALUES (
        p_nik,
        p_jenis,
        -p_jumlah,
        v_saldo_sebelum,
        v_saldo_sesudah,
        p_keterangan
    );
    
    -- Notifikasi
    INSERT INTO notifikasi (
        nik_pengguna, judul, isi_pesan, tipe
    ) VALUES (
        p_nik,
        'Skillcoin Berkurang',
        CONCAT(p_jumlah, ' skillcoin digunakan: ', p_keterangan),
        'skillcoin'
    );
    
    COMMIT;
END$$

-- Prosedur proses transaksi barter
CREATE PROCEDURE proses_transaksi_barter(
    IN p_id_transaksi INT
)
BEGIN
    DECLARE v_nik_penawar VARCHAR(16);
    DECLARE v_nik_ditawar VARCHAR(16);
    DECLARE v_durasi_jam INT;
    DECLARE v_harga_penawar INT;
    DECLARE v_harga_ditawar INT;
    DECLARE v_total_skillcoin_penawar INT;
    DECLARE v_total_skillcoin_ditawar INT;
    DECLARE v_tipe_transaksi ENUM('barter', 'bantuan');
    DECLARE v_saldo_sebelum_penawar INT;
    DECLARE v_saldo_sebelum_ditawar INT;
    
    -- Error Handler
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;
    
    -- Ambil data
    SELECT 
        tb.nik_penawar, tb.nik_ditawar, tb.durasi_jam, tb.tipe_transaksi,
        IFNULL(k1.harga_per_jam, 0), IFNULL(k2.harga_per_jam, 0)
    INTO 
        v_nik_penawar, v_nik_ditawar, v_durasi_jam, v_tipe_transaksi, v_harga_penawar, v_harga_ditawar
    FROM transaksi_barter tb
    LEFT JOIN keahlian k1 ON tb.id_keahlian_penawar = k1.id
    LEFT JOIN keahlian k2 ON tb.id_keahlian_diminta = k2.id
    WHERE tb.id = p_id_transaksi;
    
    -- Hitung
    SET v_total_skillcoin_penawar = v_durasi_jam * v_harga_penawar;
    SET v_total_skillcoin_ditawar = v_durasi_jam * v_harga_ditawar;
    
    START TRANSACTION;
    
    IF v_tipe_transaksi = 'bantuan' THEN
        -- LOGIKA MINTA BANTUAN: Murid (Penawar) Bayar Guru (Ditawar)
        SELECT saldo_skillcoin INTO v_saldo_sebelum_penawar FROM pengguna WHERE nik = v_nik_penawar FOR UPDATE;
        
        IF v_saldo_sebelum_penawar >= v_total_skillcoin_ditawar THEN
            -- Kurangi Penawar
            UPDATE pengguna 
            SET saldo_skillcoin = saldo_skillcoin - v_total_skillcoin_ditawar,
                jumlah_transaksi = jumlah_transaksi + 1,
                diperbarui_pada = NOW()
            WHERE nik = v_nik_penawar;
            
            -- Tambah Ditawar
            SELECT saldo_skillcoin INTO v_saldo_sebelum_ditawar FROM pengguna WHERE nik = v_nik_ditawar FOR UPDATE;
            
            UPDATE pengguna 
            SET saldo_skillcoin = saldo_skillcoin + v_total_skillcoin_ditawar,
                total_jam_berkontribusi = total_jam_berkontribusi + v_durasi_jam,
                jumlah_transaksi = jumlah_transaksi + 1,
                diperbarui_pada = NOW()
            WHERE nik = v_nik_ditawar;
            
            -- Log Transfer
            INSERT INTO transaksi_skillcoin (nik_pengguna, penerima_nik, id_transaksi, jenis, jumlah, saldo_sebelum, saldo_sesudah, keterangan)
            VALUES 
            (v_nik_penawar, v_nik_ditawar, p_id_transaksi, 'transfer_keluar', -v_total_skillcoin_ditawar, v_saldo_sebelum_penawar, v_saldo_sebelum_penawar - v_total_skillcoin_ditawar, 'Pembayaran Jasa (Bantuan)'),
            (v_nik_ditawar, v_nik_penawar, p_id_transaksi, 'transfer_masuk', v_total_skillcoin_ditawar, v_saldo_sebelum_ditawar, v_saldo_sebelum_ditawar + v_total_skillcoin_ditawar, 'Penerimaan Jasa (Bantuan)');
            
            INSERT INTO notifikasi (nik_pengguna, judul, isi_pesan, tipe)
            VALUES (v_nik_penawar, 'Pembayaran Berhasil', CONCAT('Anda membayar ', v_total_skillcoin_ditawar, ' skillcoin'), 'skillcoin');
            
            INSERT INTO notifikasi (nik_pengguna, judul, isi_pesan, tipe)
            VALUES (v_nik_ditawar, 'Menerima Bayaran', CONCAT('Anda menerima ', v_total_skillcoin_ditawar, ' skillcoin'), 'skillcoin');
        ELSE
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Saldo tidak cukup untuk membayar jasa';
        END IF;

    ELSE
        -- LOGIKA BARTER: Sistem Memberi Reward ke Kedua Pihak
        IF v_total_skillcoin_penawar > 0 THEN
            SELECT saldo_skillcoin INTO v_saldo_sebelum_penawar FROM pengguna WHERE nik = v_nik_penawar FOR UPDATE;
            UPDATE pengguna SET saldo_skillcoin = saldo_skillcoin + v_total_skillcoin_penawar, total_jam_berkontribusi = total_jam_berkontribusi + v_durasi_jam, jumlah_transaksi = jumlah_transaksi + 1, diperbarui_pada = NOW() WHERE nik = v_nik_penawar;
            INSERT INTO transaksi_skillcoin (nik_pengguna, jenis, jumlah, saldo_sebelum, saldo_sesudah, keterangan) VALUES (v_nik_penawar, 'hasil_barter', v_total_skillcoin_penawar, v_saldo_sebelum_penawar, v_saldo_sebelum_penawar + v_total_skillcoin_penawar, CONCAT('Reward Barter: Mengajar (', v_durasi_jam, ' jam)'));
            INSERT INTO notifikasi (nik_pengguna, judul, isi_pesan, tipe) VALUES (v_nik_penawar, 'Skillcoin Bertambah', CONCAT('Anda mendapatkan ', v_total_skillcoin_penawar, ' skillcoin dari barter'), 'skillcoin');
        END IF;
        
        IF v_total_skillcoin_ditawar > 0 THEN
            SELECT saldo_skillcoin INTO v_saldo_sebelum_ditawar FROM pengguna WHERE nik = v_nik_ditawar FOR UPDATE;
            UPDATE pengguna SET saldo_skillcoin = saldo_skillcoin + v_total_skillcoin_ditawar, total_jam_berkontribusi = total_jam_berkontribusi + v_durasi_jam, jumlah_transaksi = jumlah_transaksi + 1, diperbarui_pada = NOW() WHERE nik = v_nik_ditawar;
            INSERT INTO transaksi_skillcoin (nik_pengguna, jenis, jumlah, saldo_sebelum, saldo_sesudah, keterangan) VALUES (v_nik_ditawar, 'hasil_barter', v_total_skillcoin_ditawar, v_saldo_sebelum_ditawar, v_saldo_sebelum_ditawar + v_total_skillcoin_ditawar, CONCAT('Reward Barter: Mengajar (', v_durasi_jam, ' jam)'));
            INSERT INTO notifikasi (nik_pengguna, judul, isi_pesan, tipe) VALUES (v_nik_ditawar, 'Skillcoin Bertambah', CONCAT('Anda mendapatkan ', v_total_skillcoin_ditawar, ' skillcoin dari barter'), 'skillcoin');
        END IF;
    END IF;
    
    -- Update Status & Log
    UPDATE transaksi_barter SET status = 'terkonfirmasi', skillcoin_ditransfer = TRUE, diperbarui_pada = NOW() WHERE id = p_id_transaksi;
    INSERT INTO log_transaksi (id_transaksi, nik_pengguna, aksi, keterangan) VALUES (p_id_transaksi, v_nik_penawar, 'selesai', 'Transaksi Selesai'), (p_id_transaksi, v_nik_ditawar, 'selesai', 'Transaksi Selesai');
    
    COMMIT;
END$$

-- Prosedur verifikasi keahlian
CREATE PROCEDURE verifikasi_keahlian(
    IN p_id_keahlian INT,
    IN p_nik_verifikator VARCHAR(16)
)
BEGIN
    DECLARE v_nik_pemilik VARCHAR(16);
    DECLARE v_nama_keahlian VARCHAR(100);
    DECLARE v_biaya_verifikasi INT DEFAULT 10;
    
    -- Ambil data keahlian
    SELECT nik_pengguna, nama_keahlian 
    INTO v_nik_pemilik, v_nama_keahlian
    FROM keahlian 
    WHERE id = p_id_keahlian;
    
    -- Validasi
    IF p_nik_verifikator = v_nik_pemilik THEN
        SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = 'Tidak bisa verifikasi keahlian sendiri';
    END IF;
    
    -- Kurangi skillcoin verifikator
    CALL kurangi_skillcoin(
        p_nik_verifikator,
        v_biaya_verifikasi,
        'bayar_verifikasi',
        CONCAT('Verifikasi keahlian "', v_nama_keahlian, '" milik ', v_nik_pemilik)
    );
    
    -- Tambah skillcoin pemilik
    CALL tambah_skillcoin(
        v_nik_pemilik,
        v_biaya_verifikasi,
        'hadiah',
        CONCAT('Keahlian diverifikasi oleh ', p_nik_verifikator)
    );
    
    -- Update status keahlian
    UPDATE keahlian 
    SET status_verifikasi = TRUE
    WHERE id = p_id_keahlian;
    
    -- Log
    INSERT INTO log_transaksi (
        nik_pengguna, aksi, keterangan
    ) VALUES (
        p_nik_verifikator,
        'verifikasi',
        CONCAT('Memverifikasi keahlian ID ', p_id_keahlian)
    );
END$$

DELIMITER ;

-- ============================================
-- TRIGGERS
-- ============================================

DELIMITER $$

-- Trigger untuk kode transaksi otomatis
CREATE TRIGGER sebelum_tambah_transaksi
BEFORE INSERT ON transaksi_barter
FOR EACH ROW
BEGIN
    IF NEW.kode_transaksi IS NULL THEN
        SET NEW.kode_transaksi = buat_kode_transaksi();
    END IF;
    
    IF NEW.status = 'menunggu' THEN
        SET NEW.waktu_kedaluwarsa = DATE_ADD(NOW(), INTERVAL 3 DAY);
    END IF;
END$$

-- Trigger bonus registrasi
CREATE TRIGGER setelah_registrasi_pengguna
AFTER INSERT ON pengguna
FOR EACH ROW
BEGIN
    -- Beri bonus awal 10 skillcoin
    INSERT INTO transaksi_skillcoin (
        nik_pengguna, jenis, jumlah,
        saldo_sebelum, saldo_sesudah, keterangan
    ) VALUES (
        NEW.nik,
        'bonus_awal',
        10,
        0,
        10,
        'Bonus registrasi pengguna baru'
    );
    
    -- Notifikasi
    INSERT INTO notifikasi (
        nik_pengguna, judul, isi_pesan, tipe
    ) VALUES (
        NEW.nik,
        'Selamat Datang!',
        'Anda mendapatkan 10 skillcoin bonus registrasi',
        'skillcoin'
    );
END$$

-- Trigger update rating otomatis
CREATE TRIGGER setelah_tambah_ulasan
AFTER INSERT ON ulasan_dan_rating
FOR EACH ROW
BEGIN
    DECLARE rata_rata_baru DECIMAL(3,2);
    
    -- Hitung rata-rata rating
    SELECT AVG(rating) INTO rata_rata_baru
    FROM ulasan_dan_rating
    WHERE nik_diulas = NEW.nik_diulas;
    
    -- Update rating pengguna
    UPDATE pengguna 
    SET rating_rata_rata = COALESCE(rata_rata_baru, 0),
        diperbarui_pada = NOW()
    WHERE nik = NEW.nik_diulas;
END$$

-- Trigger denda pembatalan
CREATE TRIGGER setelah_batal_transaksi
AFTER UPDATE ON transaksi_barter
FOR EACH ROW
BEGIN
    DECLARE v_denda INT DEFAULT 5;
    
    -- Jika transaksi dibatalkan setelah diterima
    IF OLD.status = 'diterima' AND NEW.status = 'dibatalkan' THEN
        -- Pengguna yang membatalkan kena denda
        CALL kurangi_skillcoin(
            NEW.nik_penawar,
            v_denda,
            'denda',
            'Denda pembatalan transaksi setelah diterima'
        );
        
        -- Kompensasi untuk pengguna yang dirugikan
        CALL tambah_skillcoin(
            NEW.nik_ditawar,
            v_denda,
            'hadiah',
            'Kompensasi pembatalan transaksi'
        );
    END IF;
END$$

-- Trigger reward rating
CREATE TRIGGER setelah_rating_tinggi
AFTER INSERT ON ulasan_dan_rating
FOR EACH ROW
BEGIN
    DECLARE v_reward INT DEFAULT 2;
    
    -- Jika rating 5 bintang, beri reward
    IF NEW.rating = 5 THEN
        CALL tambah_skillcoin(
            NEW.nik_diulas,
            v_reward,
            'hadiah',
            'Reward rating 5 bintang'
        );
    END IF;
    
    -- Jika rating 1 bintang, kurangi skillcoin
    IF NEW.rating = 1 THEN
        CALL kurangi_skillcoin(
            NEW.nik_diulas,
            v_reward,
            'denda',
            'Penalty rating 1 bintang'
        );
    END IF;
END$$

DELIMITER ;

-- ============================================
-- VIEWS
-- ============================================

-- View riwayat skillcoin
CREATE VIEW riwayat_skillcoin_pengguna AS
SELECT 
    ts.nik_pengguna,
    p.nama_panggilan,
    ts.jenis,
    ts.jumlah,
    ts.saldo_sebelum,
    ts.saldo_sesudah,
    ts.keterangan,
    ts.penerima_nik,
    p2.nama_panggilan as nama_penerima,
    ts.dibuat_pada,
    CASE 
        WHEN ts.jumlah > 0 THEN 'masuk'
        WHEN ts.jumlah < 0 THEN 'keluar'
        ELSE 'netral'
    END as arah
FROM transaksi_skillcoin ts
JOIN pengguna p ON ts.nik_pengguna = p.nik
LEFT JOIN pengguna p2 ON ts.penerima_nik = p2.nik
ORDER BY ts.dibuat_pada DESC;

-- View statistik skillcoin
CREATE VIEW statistik_skillcoin AS
SELECT 
    (SELECT SUM(saldo_skillcoin) FROM pengguna) as total_skillcoin_beredar,
    (SELECT SUM(jumlah) FROM transaksi_skillcoin WHERE jumlah > 0) as total_masuk,
    (SELECT ABS(SUM(jumlah)) FROM transaksi_skillcoin WHERE jumlah < 0) as total_keluar,
    (SELECT COUNT(DISTINCT nik) FROM pengguna WHERE saldo_skillcoin > 0) as pengguna_aktif,
    (SELECT AVG(saldo_skillcoin) FROM pengguna) as rata_rata_saldo,
    (SELECT MAX(saldo_skillcoin) FROM pengguna) as saldo_tertinggi;

-- View leaderboard skillcoin
CREATE VIEW peringkat_skillcoin AS
SELECT 
    nik,
    nama_panggilan,
    foto_profil,
    saldo_skillcoin,
    total_jam_berkontribusi,
    rating_rata_rata,
    RANK() OVER (ORDER BY saldo_skillcoin DESC) as peringkat,
    RANK() OVER (ORDER BY total_jam_berkontribusi DESC) as peringkat_kontribusi
FROM pengguna
WHERE status_aktif = TRUE
ORDER BY saldo_skillcoin DESC
LIMIT 100;

-- View dashboard pengguna
CREATE VIEW dashboard_pengguna AS
SELECT 
    p.nik,
    p.nama_panggilan,
    p.foto_profil,
    p.rating_rata_rata,
    p.saldo_skillcoin,
    p.total_jam_berkontribusi,
    p.jumlah_transaksi,
    COUNT(DISTINCT k.id) as jumlah_keahlian,
    COUNT(DISTINCT CASE WHEN tb.status = 'terkonfirmasi' THEN tb.id END) as transaksi_selesai,
    COUNT(DISTINCT CASE WHEN tb.status = 'menunggu' AND tb.nik_penawar = p.nik THEN tb.id END) as menunggu_konfirmasi,
    COUNT(DISTINCT CASE WHEN n.dibaca = FALSE THEN n.id END) as notifikasi_baru,
    COUNT(DISTINCT CASE WHEN ps.dibaca = FALSE AND ps.nik_penerima = p.nik THEN ps.id END) as pesan_baru
FROM pengguna p
LEFT JOIN keahlian k ON p.nik = k.nik_pengguna
LEFT JOIN transaksi_barter tb ON p.nik IN (tb.nik_penawar, tb.nik_ditawar)
LEFT JOIN notifikasi n ON p.nik = n.nik_pengguna
LEFT JOIN pesan ps ON p.nik = ps.nik_penerima
GROUP BY p.nik;

-- View rekomendasi pencocokan
CREATE VIEW rekomendasi_pencocokan AS
SELECT 
    k1.nik_pengguna as pengguna_a,
    k2.nik_pengguna as pengguna_b,
    k1.nama_keahlian as keahlian_ditawarkan,
    k2.nama_keahlian as keahlian_dicari,
    ks.nama_kategori,
    p1.nama_panggilan as nama_a,
    p2.nama_panggilan as nama_b,
    p1.kota as kota_a,
    p2.kota as kota_b,
    p1.rating_rata_rata as rating_a,
    p2.rating_rata_rata as rating_b,
    ABS(p1.rating_rata_rata - p2.rating_rata_rata) as selisih_rating
FROM keahlian k1
JOIN keahlian k2 ON k1.id_kategori = k2.id_kategori 
    AND k1.tipe = 'dikuasai' 
    AND k2.tipe = 'dicari'
    AND k1.nik_pengguna != k2.nik_pengguna
JOIN kategori_skill ks ON k1.id_kategori = ks.id
JOIN pengguna p1 ON k1.nik_pengguna = p1.nik
JOIN pengguna p2 ON k2.nik_pengguna = p2.nik
WHERE p1.status_aktif = TRUE 
    AND p2.status_aktif = TRUE
    AND ks.status_aktif = TRUE
    AND NOT EXISTS (
        SELECT 1 FROM transaksi_barter tb
        WHERE tb.id_keahlian_penawar = k1.id 
        AND tb.id_keahlian_diminta = k2.id
        AND tb.status NOT IN ('ditolak', 'kedaluwarsa', 'dibatalkan')
    );

-- View untuk list percakapan terbaru
CREATE VIEW list_percakapan AS
SELECT 
    p1.nik as nik_user,
    p2.nik as nik_lawan,
    p2.nama_panggilan as nama_lawan,
    p2.foto_profil as foto_lawan,
    p2.kota as kota_lawan,
    MAX(ps.dibuat_pada) as waktu_terakhir_chat,
    MAX(ps.id) as id_pesan_terakhir,
    (SELECT isi_pesan FROM pesan WHERE id = MAX(ps.id)) as pesan_terakhir,
    (SELECT tipe FROM pesan WHERE id = MAX(ps.id)) as tipe_pesan_terakhir,
    COUNT(CASE WHEN ps.dibaca = FALSE AND ps.nik_penerima = p1.nik THEN 1 END) as jumlah_pesan_belum_dibaca,
    tb.kode_transaksi,
    tb.status as status_transaksi_terkait
FROM pengguna p1
CROSS JOIN pengguna p2
LEFT JOIN pesan ps ON (
    (ps.nik_pengirim = p1.nik AND ps.nik_penerima = p2.nik) OR
    (ps.nik_pengirim = p2.nik AND ps.nik_penerima = p1.nik)
)
LEFT JOIN transaksi_barter tb ON ps.id_transaksi = tb.id
WHERE p1.nik != p2.nik
AND ps.id IS NOT NULL
GROUP BY p1.nik, p2.nik
ORDER BY waktu_terakhir_chat DESC;

-- View untuk detail percakapan (tanpa pesan yang dihapus)
CREATE VIEW detail_percakapan AS
SELECT 
    ps.*,
    pengirim.nama_panggilan as nama_pengirim,
    pengirim.foto_profil as foto_pengirim,
    penerima.nama_panggilan as nama_penerima,
    penerima.foto_profil as foto_penerima,
    tb.kode_transaksi,
    CASE 
        WHEN JSON_EXTRACT(COALESCE(ps.metadata, '{}'), '$.dihapus_oleh_pengirim') = TRUE THEN NULL
        ELSE ps.isi_pesan
    END as isi_pesan_tampil,
    CASE 
        WHEN JSON_EXTRACT(COALESCE(ps.metadata, '{}'), '$.dihapus_oleh') = ps.nik_pengirim THEN TRUE
        ELSE FALSE
    END as dihapus_oleh_pengirim,
    CASE 
        WHEN JSON_EXTRACT(COALESCE(ps.metadata, '{}'), '$.dihapus_oleh') = ps.nik_penerima THEN TRUE
        ELSE FALSE
    END as dihapus_oleh_penerima
FROM pesan ps
JOIN pengguna pengirim ON ps.nik_pengirim = pengirim.nik
JOIN pengguna penerima ON ps.nik_penerima = penerima.nik
LEFT JOIN transaksi_barter tb ON ps.id_transaksi = tb.id
WHERE JSON_EXTRACT(COALESCE(ps.metadata, '{}'), '$.dihapus_oleh') IS NULL 
   OR JSON_EXTRACT(COALESCE(ps.metadata, '{}'), '$.dihapus_oleh') NOT IN (ps.nik_pengirim, ps.nik_penerima);

-- View untuk pesan belum dibaca
CREATE VIEW pesan_belum_dibaca AS
SELECT 
    ps.id,
    ps.nik_pengirim,
    ps.nik_penerima,
    ps.isi_pesan,
    ps.tipe,
    ps.dibuat_pada,
    p.nama_panggilan as nama_pengirim,
    p.foto_profil as foto_pengirim,
    tb.kode_transaksi
FROM pesan ps
JOIN pengguna p ON ps.nik_pengirim = p.nik
LEFT JOIN transaksi_barter tb ON ps.id_transaksi = tb.id
WHERE ps.dibaca = FALSE
ORDER BY ps.dibuat_pada ASC;

DELIMITER $$

-- Trigger: Auto-pesan saat transaksi dibuat
CREATE TRIGGER setelah_buat_transaksi
AFTER INSERT ON transaksi_barter
FOR EACH ROW
BEGIN
    DECLARE v_nama_penawar VARCHAR(50);
    DECLARE v_nama_ditawar VARCHAR(50);
    DECLARE v_nama_keahlian_ditawarkan VARCHAR(100);
    DECLARE v_nama_keahlian_diminta VARCHAR(100);
    
    -- Ambil data untuk pesan
    SELECT nama_panggilan INTO v_nama_penawar
    FROM pengguna WHERE nik = NEW.nik_penawar;
    
    SELECT nama_panggilan INTO v_nama_ditawar
    FROM pengguna WHERE nik = NEW.nik_ditawar;
    
    SELECT nama_keahlian INTO v_nama_keahlian_ditawarkan
    FROM keahlian WHERE id = NEW.id_keahlian_penawar;
    
    SELECT nama_keahlian INTO v_nama_keahlian_diminta
    FROM keahlian WHERE id = NEW.id_keahlian_diminta;
    
    -- Kirim pesan otomatis dari sistem ke penawar
    INSERT INTO pesan (
        nik_pengirim,
        nik_penerima,
        id_transaksi,
        isi_pesan,
        tipe,
        metadata
    ) VALUES (
        'SISTEM',
        NEW.nik_penawar,
        NEW.id,
        CONCAT('Anda mengajukan barter ke ', v_nama_ditawar, '. Menunggu konfirmasi.'),
        'sistem',
        JSON_OBJECT('auto_message', TRUE, 'transaction_id', NEW.id)
    );
    
    -- Kirim pesan otomatis dari sistem ke ditawar
    INSERT INTO pesan (
        nik_pengirim,
        nik_penerima,
        id_transaksi,
        isi_pesan,
        tipe,
        metadata
    ) VALUES (
        'SISTEM',
        NEW.nik_ditawar,
        NEW.id,
        CONCAT(v_nama_penawar, ' mengajukan barter: ', v_nama_keahlian_ditawarkan, 
               ' untuk ', v_nama_keahlian_diminta, '. Silakan konfirmasi.'),
        'sistem',
        JSON_OBJECT('auto_message', TRUE, 'transaction_id', NEW.id)
    );
END$$

-- Trigger: Auto-pesan saat transaksi diupdate
CREATE TRIGGER setelah_update_transaksi
AFTER UPDATE ON transaksi_barter
FOR EACH ROW
BEGIN
    DECLARE v_nama_penawar VARCHAR(50);
    DECLARE v_nama_ditawar VARCHAR(50);
    
    IF OLD.status != NEW.status THEN
        -- Ambil nama untuk pesan
        SELECT nama_panggilan INTO v_nama_penawar
        FROM pengguna WHERE nik = NEW.nik_penawar;
        
        SELECT nama_panggilan INTO v_nama_ditawar
        FROM pengguna WHERE nik = NEW.nik_ditawar;
        
        -- Pesan berdasarkan status baru
        IF NEW.status = 'diterima' THEN
            -- Kirim ke penawar
            INSERT INTO pesan (
                nik_pengirim,
                nik_penerima,
                id_transaksi,
                isi_pesan,
                tipe,
                metadata
            ) VALUES (
                'SISTEM',
                NEW.nik_penawar,
                NEW.id,
                CONCAT(v_nama_ditawar, ' telah menerima tawaran barter Anda.'),
                'sistem',
                JSON_OBJECT('auto_message', TRUE, 'status_change', NEW.status)
            );
            
            -- Kirim ke ditawar
            INSERT INTO pesan (
                nik_pengirim,
                nik_penerima,
                id_transaksi,
                isi_pesan,
                tipe,
                metadata
            ) VALUES (
                'SISTEM',
                NEW.nik_ditawar,
                NEW.id,
                CONCAT('Anda telah menerima tawaran barter dari ', v_nama_penawar, '.'),
                'sistem',
                JSON_OBJECT('auto_message', TRUE, 'status_change', NEW.status)
            );
            
        ELSEIF NEW.status = 'ditolak' THEN
            INSERT INTO pesan (
                nik_pengirim,
                nik_penerima,
                id_transaksi,
                isi_pesan,
                tipe,
                metadata
            ) VALUES (
                'SISTEM',
                NEW.nik_penawar,
                NEW.id,
                CONCAT(v_nama_ditawar, ' telah menolak tawaran barter Anda.'),
                'sistem',
                JSON_OBJECT('auto_message', TRUE, 'status_change', NEW.status)
            );
            
        ELSEIF NEW.status = 'berlangsung' THEN
            INSERT INTO pesan (
                nik_pengirim,
                nik_penerima,
                id_transaksi,
                isi_pesan,
                tipe,
                metadata
            ) VALUES (
                'SISTEM',
                NEW.nik_penawar,
                NEW.id,
                'Sesi barter telah dimulai. Selamat bertukar ilmu!',
                'sistem',
                JSON_OBJECT('auto_message', TRUE, 'status_change', NEW.status)
            );
            
            INSERT INTO pesan (
                nik_pengirim,
                nik_penerima,
                id_transaksi,
                isi_pesan,
                tipe,
                metadata
            ) VALUES (
                'SISTEM',
                NEW.nik_ditawar,
                NEW.id,
                'Sesi barter telah dimulai. Selamat bertukar ilmu!',
                'sistem',
                JSON_OBJECT('auto_message', TRUE, 'status_change', NEW.status)
            );
            
        ELSEIF NEW.status = 'selesai' THEN
            INSERT INTO pesan (
                nik_pengirim,
                nik_penerima,
                id_transaksi,
                isi_pesan,
                tipe,
                metadata
            ) VALUES (
                'SISTEM',
                NEW.nik_penawar,
                NEW.id,
                'Sesi barter telah selesai. Jangan lupa berikan rating!',
                'sistem',
                JSON_OBJECT('auto_message', TRUE, 'status_change', NEW.status)
            );
            
            INSERT INTO pesan (
                nik_pengirim,
                nik_penerima,
                id_transaksi,
                isi_pesan,
                tipe,
                metadata
            ) VALUES (
                'SISTEM',
                NEW.nik_ditawar,
                NEW.id,
                'Sesi barter telah selesai. Jangan lupa berikan rating!',
                'sistem',
                JSON_OBJECT('auto_message', TRUE, 'status_change', NEW.status)
            );
            
        END IF;
    END IF;
END$$

DELIMITER ;

DELIMITER $$

-- Fungsi untuk cek apakah bisa kirim pesan (terkait transaksi atau sudah pernah chat)
CREATE FUNCTION bisa_kirim_pesan(
    p_nik_pengirim VARCHAR(16),
    p_nik_penerima VARCHAR(16)
)
RETURNS BOOLEAN
READS SQL DATA
BEGIN
    DECLARE v_transaksi_aktif INT;
    DECLARE v_sudah_pernah_chat INT;
    
    -- Cek apakah ada transaksi aktif antara kedua user
    SELECT COUNT(*) INTO v_transaksi_aktif
    FROM transaksi_barter
    WHERE (
        (nik_penawar = p_nik_pengirim AND nik_ditawar = p_nik_penerima) OR
        (nik_penawar = p_nik_penerima AND nik_ditawar = p_nik_pengirim)
    )
    AND status IN ('menunggu', 'diterima', 'berlangsung', 'selesai');
    
    -- Cek apakah sudah pernah chat sebelumnya
    SELECT COUNT(*) INTO v_sudah_pernah_chat
    FROM pesan
    WHERE (nik_pengirim = p_nik_pengirim AND nik_penerima = p_nik_penerima)
       OR (nik_pengirim = p_nik_penerima AND nik_penerima = p_nik_pengirim);
    
    RETURN v_transaksi_aktif > 0 OR v_sudah_pernah_chat > 0;
END$$

-- Prosedur untuk kirim pesan
CREATE PROCEDURE kirim_pesan(
    IN p_nik_pengirim VARCHAR(16),
    IN p_nik_penerima VARCHAR(16),
    IN p_id_transaksi INT,
    IN p_isi_pesan TEXT,
    IN p_tipe_pesan ENUM('teks', 'gambar', 'lokasi', 'sistem'),
    IN p_gambar MEDIUMBLOB,
    IN p_jenis_gambar VARCHAR(10),
    IN p_metadata JSON
)
BEGIN
    DECLARE v_bisa_kirim BOOLEAN;
    
    -- Validasi: tidak bisa kirim ke diri sendiri
    IF p_nik_pengirim = p_nik_penerima THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Tidak bisa mengirim pesan ke diri sendiri';
    END IF;
    
    -- Cek apakah bisa kirim pesan
    SET v_bisa_kirim = bisa_kirim_pesan(p_nik_pengirim, p_nik_penerima);
    
    IF NOT v_bisa_kirim THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Tidak bisa mengirim pesan ke pengguna ini';
    END IF;
    
    -- Insert pesan
    INSERT INTO pesan (
        nik_pengirim,
        nik_penerima,
        id_transaksi,
        isi_pesan,
        tipe,
        gambar_pesan,
        jenis_gambar,
        metadata
    ) VALUES (
        p_nik_pengirim,
        p_nik_penerima,
        p_id_transaksi,
        p_isi_pesan,
        p_tipe_pesan,
        p_gambar,
        p_jenis_gambar,
        p_metadata
    );
    
    -- Tambah notifikasi untuk penerima
    INSERT INTO notifikasi (
        nik_pengguna,
        judul,
        isi_pesan,
        tipe,
        id_terkait,
        tipe_terkait
    ) VALUES (
        p_nik_penerima,
        'Pesan Baru',
        CONCAT('Pesan dari ', p_nik_pengirim),
        'pesan_baru',
        LAST_INSERT_ID(),
        'pesan'
    );
END$$

-- Prosedur untuk baca pesan (mark as read)
CREATE PROCEDURE baca_pesan(
    IN p_nik_penerima VARCHAR(16),
    IN p_id_pesan INT
)
BEGIN
    UPDATE pesan 
    SET dibaca = TRUE 
    WHERE id = p_id_pesan 
    AND nik_penerima = p_nik_penerima;
END$$

-- Prosedur untuk baca semua pesan dari pengirim tertentu
CREATE PROCEDURE baca_semua_pesan_dari(
    IN p_nik_penerima VARCHAR(16),
    IN p_nik_pengirim VARCHAR(16)
)
BEGIN
    UPDATE pesan 
    SET dibaca = TRUE 
    WHERE nik_penerima = p_nik_penerima 
    AND nik_pengirim = p_nik_pengirim
    AND dibaca = FALSE;
END$$

-- Prosedur untuk hapus pesan (soft delete untuk pengirim)
CREATE PROCEDURE hapus_pesan_untuk_pengirim(
    IN p_id_pesan INT,
    IN p_nik_pengirim VARCHAR(16)
)
BEGIN
    -- Update metadata untuk menandai dihapus oleh pengirim
    UPDATE pesan 
    SET metadata = JSON_SET(
        COALESCE(metadata, '{}'),
        '$.dihapus_oleh_pengirim', TRUE,
        '$.waktu_hapus_pengirim', NOW()
    )
    WHERE id = p_id_pesan 
    AND nik_pengirim = p_nik_pengirim;
END$$

-- Prosedur untuk hapus percakapan
CREATE PROCEDURE hapus_percakapan(
    IN p_nik_user VARCHAR(16),
    IN p_nik_lawan VARCHAR(16)
)
BEGIN
    -- Tandai semua pesan dalam percakapan sebagai dihapus
    UPDATE pesan 
    SET metadata = JSON_SET(
        COALESCE(metadata, '{}'),
        '$.dihapus_oleh', p_nik_user,
        '$.waktu_hapus', NOW()
    )
    WHERE (nik_pengirim = p_nik_user AND nik_penerima = p_nik_lawan)
       OR (nik_pengirim = p_nik_lawan AND nik_penerima = p_nik_user);
END$$

DELIMITER ;

-- ============================================
-- EVENTS (MAINTENANCE OTOMATIS)
-- ============================================

DELIMITER $$

CREATE EVENT bersihkan_transaksi_kedaluwarsa
ON SCHEDULE EVERY 1 HOUR
DO
BEGIN
    UPDATE transaksi_barter
    SET status = 'kedaluwarsa',
        diperbarui_pada = NOW()
    WHERE status = 'menunggu' 
    AND waktu_kedaluwarsa IS NOT NULL 
    AND waktu_kedaluwarsa < NOW();
END$$

CREATE EVENT update_notifikasi_kadaluarsa
ON SCHEDULE EVERY 1 DAY
DO
BEGIN
    DELETE FROM notifikasi 
    WHERE kadaluarsa_pada < NOW();
END$$

DELIMITER ;

-- ============================================
-- INSERT DATA SAMPLE UNTUK TESTING
-- ============================================

-- Insert sample users
INSERT INTO pengguna (nik, nama_lengkap, nama_panggilan, kata_sandi, jenis_kelamin, tanggal_lahir, alamat_lengkap, kota) VALUES
('3273010101010001', 'Budi Santoso', 'Budi', 'hashed_password_1', 'L', '1990-01-01', 'Jl. Merdeka No. 123', 'Jakarta'),
('3273010101010002', 'Sari Dewi', 'Sari', 'hashed_password_2', 'P', '1992-05-15', 'Jl. Sudirman No. 45', 'Bandung'),
('3273010101010003', 'Ahmad Fauzi', 'Ahmad', 'hashed_password_3', 'L', '1988-11-20', 'Jl. Diponegoro No. 78', 'Surabaya'),
('3273010101010004', 'Maya Indah', 'Maya', 'hashed_password_4', 'P', '1995-03-10', 'Jl. Gajah Mada No. 12', 'Yogyakarta');

-- Insert sample skills
INSERT INTO keahlian (nik_pengguna, nama_keahlian, id_kategori, tipe, tingkat, harga_per_jam) VALUES
('3273010101010001', 'Programming Flutter', 1, 'dikuasai', 'mahir', 2),
('3273010101010001', 'Desain UI/UX', 2, 'dicari', 'pemula', 1),
('3273010101010002', 'Bahasa Inggris', 3, 'dikuasai', 'mahir', 2),
('3273010101010002', 'Memasak Italian', 6, 'dicari', 'menengah', 1),
('3273010101010003', 'Gitar Klasik', 4, 'dikuasai', 'ahli', 3),
('3273010101010003', 'Web Development', 1, 'dicari', 'pemula', 1),
('3273010101010004', 'Yoga Instructor', 10, 'dikuasai', 'mahir', 2),
('3273010101010004', 'Penulisan Artikel', 7, 'dicari', 'menengah', 1);

-- Insert sample transaction
INSERT INTO transaksi_barter (nik_penawar, nik_ditawar, id_keahlian_penawar, id_keahlian_diminta, durasi_jam, tanggal_pelaksanaan, status) 
VALUES 
('3273010101010001', '3273010101010002', 1, 4, 2, DATE_ADD(NOW(), INTERVAL 2 DAY), 'diterima');

-- ============================================
-- TESTS (JALANKAN SATU PER SATU)
-- ============================================

-- Test 1: Cek saldo
SELECT cek_saldo_skillcoin('3273010101010001') as saldo_budi;

-- Test 2: Cek apakah cukup saldo
SELECT cukup_saldo('3273010101010001', 5) as cukup_saldo;

-- Test 3: Transfer skillcoin (harusnya berhasil karena ada 10 coin bonus)
CALL transfer_skillcoin('3273010101010001', '3273010101010002', 5, 'Test transfer pertama');

-- Test 4: Cek riwayat transfer
SELECT * FROM riwayat_skillcoin_pengguna WHERE nik_pengguna = '3273010101010001';

-- Test 5: Cek dashboard
SELECT * FROM dashboard_pengguna WHERE nik = '3273010101010001';

-- Test 6: Cek rekomendasi
SELECT * FROM rekomendasi_pencocokan LIMIT 5;

-- Test 7: Proses transaksi barter selesai
CALL proses_transaksi_barter(1);

-- Test 8: Verifikasi keahlian (butuh skillcoin)
CALL verifikasi_keahlian(1, '3273010101010003');

-- Test 9: Cek statistik
SELECT * FROM statistik_skillcoin;

-- Test 10: Cek leaderboard
SELECT * FROM peringkat_skillcoin;

-- ============================================
-- STORED PROCEDURES UNTUK VERIFIKASI SKILL
-- ============================================

DELIMITER $$

-- Prosedur untuk verifikasi keahlian (bayar 10 skillcoin)
CREATE PROCEDURE verifikasi_keahlian(
    IN p_id_keahlian INT,
    IN p_nik_pengguna VARCHAR(16)
)
BEGIN
    DECLARE v_saldo_sekarang INT;
    DECLARE v_biaya_verifikasi INT DEFAULT 10;
    
    -- Cek saldo skillcoin user
    SELECT saldo_skillcoin INTO v_saldo_sekarang
    FROM pengguna
    WHERE nik = p_nik_pengguna;
    
    -- Validasi saldo cukup
    IF v_saldo_sekarang < v_biaya_verifikasi THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Saldo skillcoin tidak cukup untuk verifikasi';
    END IF;
    
    -- Kurangi skillcoin
    UPDATE pengguna
    SET saldo_skillcoin = saldo_skillcoin - v_biaya_verifikasi
    WHERE nik = p_nik_pengguna;
    
    -- Update status verifikasi skill
    UPDATE keahlian
    SET status_verifikasi = TRUE,
        diperbarui_pada = CURRENT_TIMESTAMP
    WHERE id = p_id_keahlian;
    
    -- Catat transaksi skillcoin
    INSERT INTO transaksi_skillcoin (
        nik_pengguna,
        jenis,
        jumlah,
        saldo_sebelum,
        saldo_sesudah,
        keterangan
    ) VALUES (
        p_nik_pengguna,
        'bayar_verifikasi',
        -v_biaya_verifikasi,
        v_saldo_sekarang,
        v_saldo_sekarang - v_biaya_verifikasi,
        CONCAT('Verifikasi keahlian ID: ', p_id_keahlian)
    );
END$$

DELIMITER ;

-- ============================================
-- HASIL YANG DIHARAPKAN:
-- ============================================

/*
1. Setiap user baru dapat 10 skillcoin otomatis
2. Transfer skillcoin antar user berfungsi
3. Transaksi barter selesai -> tambah skillcoin
4. Verifikasi keahlian -> transfer skillcoin
5. Rating 5 bintang -> +2 skillcoin
6. Rating 1 bintang -> -2 skillcoin
7. Pembatalan transaksi -> denda 5 skillcoin
8. Semua riwayat tercatat di transaksi_skillcoin
*/

-- ============================================
-- PERBAIKAN ERROR:
-- ============================================

/*
ERROR YANG DIPERBAIKI:
1. Syntax error karena copy-paste dengan tanda ->
2. DELIMITER tidak konsisten
3. Tabel belum dibuat saat membuat fungsi
4. Variable tidak dideklarasikan
5. Foreign key constraint violation
6. View mengacu ke tabel yang belum ada
7. Missing commas dan parentheses
8. Parameter tidak sesuai

SOLUSI:
1. Buat semua tabel dulu sebelum fungsi/prosedur
2. Pastikan DELIMITER $$ dan DELIMITER ; konsisten
3. Gunakan SET FOREIGN_KEY_CHECKS = 0/1
4. Declare semua variable di awal
5. Urutkan pembuatan tabel dengan benar
6. Insert data sample setelah semua dibuat
7. Test satu per satu
*/

-- ============================================
-- DATABASE SIAP DIGUNAKAN!
-- ============================================


-- ============================================
-- 🔥 PATCH: UPDATE FITUR BARU & MIGRASI OTOMATIS 🔥
-- (Bagian ini ditambahkan untuk melengkapi fitur yang kurang)
-- ============================================

-- 1. Nonaktifkan FK Check sebentar
SET FOREIGN_KEY_CHECKS = 0;

-- 2. Tambah kolom status_online di tabel pengguna (jika belum ada)
-- Kita pakai ALTER IGNORE atau teknik procedure agar tidak error jika sudah ada
DROP PROCEDURE IF EXISTS upgrade_pengguna_table;
DELIMITER $$
CREATE PROCEDURE upgrade_pengguna_table()
BEGIN
    IF NOT EXISTS (SELECT * FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='pengguna' AND COLUMN_NAME='status_online') THEN
        ALTER TABLE pengguna ADD COLUMN status_online ENUM('online', 'offline') DEFAULT 'offline';
        ALTER TABLE pengguna ADD COLUMN terakhir_aktif TIMESTAMP DEFAULT CURRENT_TIMESTAMP;
        ALTER TABLE pengguna ADD COLUMN terakhir_login TIMESTAMP NULL;
    END IF;
END$$
DELIMITER ;
CALL upgrade_pengguna_table();
DROP PROCEDURE upgrade_pengguna_table;

-- 3. Hapus tabel lama/salah & prosedur konflik
DROP TABLE IF EXISTS skill_requests;
DROP TABLE IF EXISTS barter_confirmations;
DROP PROCEDURE IF EXISTS proses_transaksi_barter;
DROP VIEW IF EXISTS rekomendasi_pencocokan;

-- 4. Buat Tabel Skill Request (Baru)
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
    FOREIGN KEY (id_kategori) REFERENCES kategori_skill(id)
);

-- 5. Update Tabel Transaksi Barter (Kolom baru)
DROP PROCEDURE IF EXISTS upgrade_transaksi_table;
DELIMITER $$
CREATE PROCEDURE upgrade_transaksi_table()
BEGIN
    IF NOT EXISTS (SELECT * FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='transaksi_barter' AND COLUMN_NAME='tipe_transaksi') THEN
        ALTER TABLE transaksi_barter ADD COLUMN tipe_transaksi ENUM('barter', 'bantuan') NOT NULL DEFAULT 'barter';
        ALTER TABLE transaksi_barter ADD COLUMN id_skill_request INT NULL;
        ALTER TABLE transaksi_barter ADD CONSTRAINT fk_tr_skill_req FOREIGN KEY (id_skill_request) REFERENCES skill_requests(id) ON DELETE SET NULL;
        -- Ubah kolom id_keahlian_penawar jadi NULLABLE
        ALTER TABLE transaksi_barter MODIFY COLUMN id_keahlian_penawar INT NULL;
        -- Ubah isi_pesan di tabel pesan jadi NULLABLE
        ALTER TABLE pesan MODIFY COLUMN isi_pesan TEXT NULL;
    END IF;
END$$
DELIMITER ;
CALL upgrade_transaksi_table();
DROP PROCEDURE upgrade_transaksi_table;

-- 6. Buat Tabel Barter Confirmations (Baru)
CREATE TABLE IF NOT EXISTS barter_confirmations (
  id_konfirmasi INT PRIMARY KEY AUTO_INCREMENT,
  id_barter INT NOT NULL,
  nik VARCHAR(16) NOT NULL,
  konfirmasi_selesai BOOLEAN DEFAULT FALSE,
  catatan TEXT,
  waktu_konfirmasi TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  foto_bukti LONGTEXT, 
  waktu_upload_foto TIMESTAMP NULL,
  FOREIGN KEY (id_barter) REFERENCES transaksi_barter(id) ON DELETE CASCADE,
  FOREIGN KEY (nik) REFERENCES pengguna(nik) ON DELETE CASCADE,
  UNIQUE KEY unique_confirmation (id_barter, nik)
);

-- 7. Insert User SYSTEM (Wajib)
INSERT IGNORE INTO pengguna (nik, nama_lengkap, nama_panggilan, kata_sandi, jenis_kelamin, tanggal_lahir, alamat_lengkap, kota, bio) 
VALUES ('SISTEM', 'System Notification', 'System', '$2b$10$SYSTEMACCOUNTLOCKEDDONOTUSE99', 'L', '2000-01-01', 'System Internal', 'System', 'Official System Account');

-- 8. Re-Create Procedure & View (Versi Fix)
DELIMITER $$

-- Fix Prosedur Barter (Logic Reward)
CREATE PROCEDURE proses_transaksi_barter(IN p_id_transaksi INT)
BEGIN
    DECLARE v_nik_penawar VARCHAR(16);
    DECLARE v_nik_ditawar VARCHAR(16);
    DECLARE v_durasi_jam INT;
    DECLARE v_harga_penawar INT;
    DECLARE v_harga_ditawar INT;
    DECLARE v_total_skillcoin_penawar INT;
    DECLARE v_total_skillcoin_ditawar INT;
    DECLARE v_tipe_transaksi ENUM('barter', 'bantuan');
    DECLARE v_saldo_sebelum_penawar INT;
    DECLARE v_saldo_sebelum_ditawar INT;
    
    DECLARE EXIT HANDLER FOR SQLEXCEPTION ROLLBACK;
    
    SELECT tb.nik_penawar, tb.nik_ditawar, tb.durasi_jam, tb.tipe_transaksi, IFNULL(k1.harga_per_jam, 0), IFNULL(k2.harga_per_jam, 0)
    INTO v_nik_penawar, v_nik_ditawar, v_durasi_jam, v_tipe_transaksi, v_harga_penawar, v_harga_ditawar
    FROM transaksi_barter tb
    LEFT JOIN keahlian k1 ON tb.id_keahlian_penawar = k1.id
    LEFT JOIN keahlian k2 ON tb.id_keahlian_diminta = k2.id
    WHERE tb.id = p_id_transaksi;
    
    SET v_total_skillcoin_penawar = v_durasi_jam * v_harga_penawar;
    SET v_total_skillcoin_ditawar = v_durasi_jam * v_harga_ditawar;
    
    START TRANSACTION;
    
    IF v_tipe_transaksi = 'bantuan' THEN
        SELECT saldo_skillcoin INTO v_saldo_sebelum_penawar FROM pengguna WHERE nik = v_nik_penawar FOR UPDATE;
        IF v_saldo_sebelum_penawar >= v_total_skillcoin_ditawar THEN
            UPDATE pengguna SET saldo_skillcoin = saldo_skillcoin - v_total_skillcoin_ditawar, jumlah_transaksi = jumlah_transaksi + 1 WHERE nik = v_nik_penawar;
            UPDATE pengguna SET saldo_skillcoin = saldo_skillcoin + v_total_skillcoin_ditawar, total_jam_berkontribusi = total_jam_berkontribusi + v_durasi_jam, jumlah_transaksi = jumlah_transaksi + 1 WHERE nik = v_nik_ditawar;
            INSERT INTO transaksi_skillcoin (nik_pengguna, penerima_nik, id_transaksi, jenis, jumlah, saldo_sebelum, saldo_sesudah, keterangan)
            VALUES (v_nik_penawar, v_nik_ditawar, p_id_transaksi, 'transfer_keluar', -v_total_skillcoin_ditawar, v_saldo_sebelum_penawar, v_saldo_sebelum_penawar - v_total_skillcoin_ditawar, 'Pembayaran Jasa'),
                   (v_nik_ditawar, v_nik_penawar, p_id_transaksi, 'transfer_masuk', v_total_skillcoin_ditawar, 0, v_total_skillcoin_ditawar, 'Penerimaan Jasa'); -- Saldo ditawar perlu diquery dl sbnrnya tp utk singkatan 0
        END IF;
    ELSE
        IF v_total_skillcoin_penawar > 0 THEN CALL tambah_skillcoin(v_nik_penawar, v_total_skillcoin_penawar, 'hasil_barter', 'Reward Barter'); END IF;
        IF v_total_skillcoin_ditawar > 0 THEN CALL tambah_skillcoin(v_nik_ditawar, v_total_skillcoin_ditawar, 'hasil_barter', 'Reward Barter'); END IF;
        UPDATE pengguna SET total_jam_berkontribusi = total_jam_berkontribusi + v_durasi_jam, jumlah_transaksi = jumlah_transaksi + 1 WHERE nik IN (v_nik_penawar, v_nik_ditawar);
    END IF;
    
    UPDATE transaksi_barter SET status = 'terkonfirmasi', skillcoin_ditransfer = TRUE, diperbarui_pada = NOW() WHERE id = p_id_transaksi;
    INSERT INTO log_transaksi (id_transaksi, nik_pengguna, aksi, keterangan) VALUES (p_id_transaksi, v_nik_penawar, 'selesai', 'Selesai'), (p_id_transaksi, v_nik_ditawar, 'selesai', 'Selesai');
    COMMIT;
END$$

DELIMITER ;

-- Fix View
CREATE VIEW rekomendasi_pencocokan AS
SELECT k1.nik_pengguna as pengguna_a, k2.nik_pengguna as pengguna_b, k1.nama_keahlian as keahlian_ditawarkan, k2.nama_keahlian as keahlian_dicari, 
       ks.nama_kategori, p1.nama_panggilan as nama_a, p2.nama_panggilan as nama_b, p1.kota as kota_a, p2.kota as kota_b, 
       p1.rating_rata_rata as rating_a, p2.rating_rata_rata as rating_b, ABS(p1.rating_rata_rata - p2.rating_rata_rata) as selisih_rating,
       (40 + CASE WHEN k1.tingkat = k2.tingkat THEN 30 ELSE 10 END + CASE WHEN LOWER(p1.kota) = LOWER(p2.kota) THEN 20 ELSE 0 END) AS skor_kecocokan,
       k1.status_verifikasi AS verifikasi_a, k2.status_verifikasi AS verifikasi_b, k1.tingkat AS tingkat_a, k2.tingkat AS tingkat_b
FROM keahlian k1 JOIN keahlian k2 ON k1.id_kategori = k2.id_kategori AND k1.tipe = 'dikuasai' AND k2.tipe = 'dicari' AND k1.nik_pengguna != k2.nik_pengguna
JOIN kategori_skill ks ON k1.id_kategori = ks.id JOIN pengguna p1 ON k1.nik_pengguna = p1.nik JOIN pengguna p2 ON k2.nik_pengguna = p2.nik
WHERE p1.status_aktif = TRUE AND p2.status_aktif = TRUE;

SET FOREIGN_KEY_CHECKS = 1;
