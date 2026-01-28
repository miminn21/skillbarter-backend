const mysql = require('mysql2/promise');
require('dotenv').config();

async function applyOptimization() {
  console.log('🚀 Applying FINAL Optimization to Barter Procedure...');
  console.log('   Inlining logic to avoid Nested Transaction issues.');
  
  let connection;
  try {
    connection = await mysql.createConnection({
      host: process.env.DB_HOST || 'localhost',
      user: process.env.DB_USER || 'root',
      password: process.env.DB_PASSWORD || '',
      database: process.env.DB_NAME || 'skillbarter_db',
      multipleStatements: true
    });
    
    // 1. Drop existing
    await connection.query("DROP PROCEDURE IF EXISTS proses_transaksi_barter");
    
    // 2. Create optimized atomic procedure
    const sql = `
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
    
    -- MULAI TRANSAKSI TUNGGAL (ATOMIC)
    START TRANSACTION;
    
    IF v_tipe_transaksi = 'bantuan' THEN
        -- LOGIKA MINTA BANTUAN: Murid (Penawar) Bayar Guru (Ditawar)
        -- Penawar meminta skill (tb.id_keahlian_diminta), jadi id_keahlian_penawar NULL
        -- v_total_skillcoin_ditawar adalah harga skill Guru
        
        -- Cek Saldo Penawar
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
            -- Saldo Kurang (Harusnya dicek di awal, tapi untuk safety)
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Saldo tidak cukup untuk membayar jasa';
        END IF;

    ELSE
        -- LOGIKA BARTER: Sistem Memberi Reward ke Kedua Pihak
        
        -- 1. Update Saldo Penawar
        IF v_total_skillcoin_penawar > 0 THEN
            SELECT saldo_skillcoin INTO v_saldo_sebelum_penawar FROM pengguna WHERE nik = v_nik_penawar FOR UPDATE;
            
            UPDATE pengguna 
            SET saldo_skillcoin = saldo_skillcoin + v_total_skillcoin_penawar,
                total_jam_berkontribusi = total_jam_berkontribusi + v_durasi_jam,
                jumlah_transaksi = jumlah_transaksi + 1,
                diperbarui_pada = NOW()
            WHERE nik = v_nik_penawar;
            
            INSERT INTO transaksi_skillcoin (nik_pengguna, jenis, jumlah, saldo_sebelum, saldo_sesudah, keterangan)
            VALUES (v_nik_penawar, 'hasil_barter', v_total_skillcoin_penawar, v_saldo_sebelum_penawar, v_saldo_sebelum_penawar + v_total_skillcoin_penawar, 
                    CONCAT('Reward Barter: Mengajar (', v_durasi_jam, ' jam)'));
            
            INSERT INTO notifikasi (nik_pengguna, judul, isi_pesan, tipe)
            VALUES (v_nik_penawar, 'Skillcoin Bertambah', CONCAT('Anda mendapatkan ', v_total_skillcoin_penawar, ' skillcoin dari barter'), 'skillcoin');
        END IF;
        
        -- 2. Update Saldo Ditawar (Partner)
        IF v_total_skillcoin_ditawar > 0 THEN
            SELECT saldo_skillcoin INTO v_saldo_sebelum_ditawar FROM pengguna WHERE nik = v_nik_ditawar FOR UPDATE;
            
            UPDATE pengguna 
            SET saldo_skillcoin = saldo_skillcoin + v_total_skillcoin_ditawar,
                total_jam_berkontribusi = total_jam_berkontribusi + v_durasi_jam,
                jumlah_transaksi = jumlah_transaksi + 1,
                diperbarui_pada = NOW()
            WHERE nik = v_nik_ditawar;
            
            INSERT INTO transaksi_skillcoin (nik_pengguna, jenis, jumlah, saldo_sebelum, saldo_sesudah, keterangan)
            VALUES (v_nik_ditawar, 'hasil_barter', v_total_skillcoin_ditawar, v_saldo_sebelum_ditawar, v_saldo_sebelum_ditawar + v_total_skillcoin_ditawar, 
                    CONCAT('Reward Barter: Mengajar (', v_durasi_jam, ' jam)'));
            
            INSERT INTO notifikasi (nik_pengguna, judul, isi_pesan, tipe)
            VALUES (v_nik_ditawar, 'Skillcoin Bertambah', CONCAT('Anda mendapatkan ', v_total_skillcoin_ditawar, ' skillcoin dari barter'), 'skillcoin');
        END IF;
        
    END IF;
    
    -- 3. Update Status Transaksi
    UPDATE transaksi_barter 
    SET status = 'terkonfirmasi',
        skillcoin_ditransfer = TRUE,
        diperbarui_pada = NOW()
    WHERE id = p_id_transaksi;
    
    -- 4. Log
    INSERT INTO log_transaksi (id_transaksi, nik_pengguna, aksi, keterangan) VALUES 
    (p_id_transaksi, v_nik_penawar, 'selesai', 'Transaksi Selesai'),
    (p_id_transaksi, v_nik_ditawar, 'selesai', 'Transaksi Selesai');
    
    COMMIT;
END
    `;
    
    await connection.query(sql);
    console.log('✅ Optimization Applied! No more nested transactions.');

  } catch (error) {
    console.error('❌ Error:', error);
  } finally {
    if (connection) await connection.end();
  }
}

applyOptimization();
