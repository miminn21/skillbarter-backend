const mysql = require('mysql2/promise');

const RAILWAY_CONFIG = {
    host: 'switchyard.proxy.rlwy.net',
    port: 38963,
    user: 'root',
    password: 'fSexsPKyjZtWdhESBvdEFrfBTFSORsfw',
    database: 'railway'
};

const dropTambahInfo = "DROP PROCEDURE IF EXISTS tambah_skillcoin";
const createTambahInfo = `
CREATE PROCEDURE tambah_skillcoin(
    IN p_nik VARCHAR(16),
    IN p_jumlah INT,
    IN p_jenis VARCHAR(20),
    IN p_keterangan TEXT
)
BEGIN
    DECLARE v_saldo_sebelum INT;
    DECLARE v_saldo_sesudah INT;

    -- Transaction removed to allow call from trigger

    IF p_jumlah <= 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Jumlah harus positif';
    END IF;

    SELECT saldo_skillcoin INTO v_saldo_sebelum
    FROM pengguna WHERE nik = p_nik;

    SET v_saldo_sesudah = v_saldo_sebelum + p_jumlah;

    UPDATE pengguna
    SET saldo_skillcoin = v_saldo_sesudah,
        diperbarui_pada = NOW()
    WHERE nik = p_nik;

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

    INSERT INTO notifikasi (
        nik_pengguna, judul, isi_pesan, tipe
    ) VALUES (
        p_nik,
        'Skillcoin Bertambah',
        CONCAT('Anda mendapatkan ', p_jumlah, ' skillcoin: ', p_keterangan),
        'skillcoin'
    );
END
`;

const dropKurangInfo = "DROP PROCEDURE IF EXISTS kurangi_skillcoin";
const createKurangInfo = `
CREATE PROCEDURE kurangi_skillcoin(
    IN p_nik VARCHAR(16),
    IN p_jumlah INT,
    IN p_jenis VARCHAR(20),
    IN p_keterangan TEXT
)
BEGIN
    DECLARE v_saldo_sebelum INT;
    DECLARE v_saldo_sesudah INT;

    -- Transaction removed to allow call from trigger

    IF p_jumlah <= 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Jumlah harus positif untuk pengurangan';
    END IF;

    -- Note: cukup_saldo function handles the check, but we duplicate logic or assume it's checked?
    -- The original had: IF NOT cukup_saldo(...)
    -- We must ensure simple logic.
    -- Assuming cukup_saldo is a function (RETURN BOOLEAN)
    
    IF (SELECT saldo_skillcoin FROM pengguna WHERE nik = p_nik) < p_jumlah THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Saldo skillcoin tidak cukup';
    END IF;

    SELECT saldo_skillcoin INTO v_saldo_sebelum
    FROM pengguna WHERE nik = p_nik;

    SET v_saldo_sesudah = v_saldo_sebelum - p_jumlah;

    UPDATE pengguna
    SET saldo_skillcoin = v_saldo_sesudah,
        diperbarui_pada = NOW()
    WHERE nik = p_nik;

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

    INSERT INTO notifikasi (
        nik_pengguna, judul, isi_pesan, tipe
    ) VALUES (
        p_nik,
        'Skillcoin Berkurang',
        CONCAT(p_jumlah, ' skillcoin digunakan: ', p_keterangan),
        'skillcoin'
    );
END
`;

async function fixProcedures() {
    console.log('🔧 FIXING STORED PROCEDURES...');
    let connection;
    try {
        connection = await mysql.createConnection(RAILWAY_CONFIG);
        
        console.log('1. Fixing tambah_skillcoin...');
        await connection.query(dropTambahInfo);
        await connection.query(createTambahInfo);
        console.log('✅ tambah_skillcoin fixed.');

        console.log('2. Fixing kurangi_skillcoin...');
        await connection.query(dropKurangInfo);
        await connection.query(createKurangInfo);
        console.log('✅ kurangi_skillcoin fixed.');

    } catch (error) {
        console.error('❌ Error fixing procedures:', error);
    } finally {
        if (connection) await connection.end();
    }
}

fixProcedures();
