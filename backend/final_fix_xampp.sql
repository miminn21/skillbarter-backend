DELIMITER $$

DROP PROCEDURE IF EXISTS proses_transaksi_barter$$

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
    
    -- Error Handler: Rollback jika ada error
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;
    
    -- 1. Ambil Data Transaksi
    SELECT 
        tb.nik_penawar, tb.nik_ditawar, tb.durasi_jam, tb.tipe_transaksi,
        IFNULL(k1.harga_per_jam, 0), IFNULL(k2.harga_per_jam, 0)
    INTO 
        v_nik_penawar, v_nik_ditawar, v_durasi_jam, v_tipe_transaksi, v_harga_penawar, v_harga_ditawar
    FROM transaksi_barter tb
    LEFT JOIN keahlian k1 ON tb.id_keahlian_penawar = k1.id
    LEFT JOIN keahlian k2 ON tb.id_keahlian_diminta = k2.id
    WHERE tb.id = p_id_transaksi;
    
    -- 2. Hitung Total Koin
    SET v_total_skillcoin_penawar = v_durasi_jam * v_harga_penawar;
    SET v_total_skillcoin_ditawar = v_durasi_jam * v_harga_ditawar;
    
    START TRANSACTION;
    
    -- ==========================================
    -- LOGIKA PERCABANGAN (The Hybrid Logic)
    -- ==========================================
    
    IF v_tipe_transaksi = 'bantuan' THEN
        -- KASUS A: MINTA BANTUAN (Help Request)
        -- Logika: Murid (Penawar) MEMBAYAR Guru (Ditawar/Partner)
        -- Harga: Sesuai skill Guru.
        
        -- Cek Saldo Penawar
        SELECT saldo_skillcoin INTO v_saldo_sebelum_penawar FROM pengguna WHERE nik = v_nik_penawar FOR UPDATE;
        
        IF v_saldo_sebelum_penawar >= v_total_skillcoin_ditawar THEN
            -- 1. Kurangi Saldo Penawar (Murid)
            UPDATE pengguna 
            SET saldo_skillcoin = saldo_skillcoin - v_total_skillcoin_ditawar,
                jumlah_transaksi = jumlah_transaksi + 1,
                diperbarui_pada = NOW()
            WHERE nik = v_nik_penawar;
            
            -- 2. Tambah Saldo Ditawar (Guru)
            SELECT saldo_skillcoin INTO v_saldo_sebelum_ditawar FROM pengguna WHERE nik = v_nik_ditawar FOR UPDATE;
            
            UPDATE pengguna 
            SET saldo_skillcoin = saldo_skillcoin + v_total_skillcoin_ditawar,
                total_jam_berkontribusi = total_jam_berkontribusi + v_durasi_jam,
                jumlah_transaksi = jumlah_transaksi + 1,
                diperbarui_pada = NOW()
            WHERE nik = v_nik_ditawar;
            
            -- 3. Catat Transfer
            INSERT INTO transaksi_skillcoin (nik_pengguna, penerima_nik, id_transaksi, jenis, jumlah, saldo_sebelum, saldo_sesudah, keterangan)
            VALUES 
            (v_nik_penawar, v_nik_ditawar, p_id_transaksi, 'transfer_keluar', -v_total_skillcoin_ditawar, v_saldo_sebelum_penawar, v_saldo_sebelum_penawar - v_total_skillcoin_ditawar, 'Pembayaran Jasa (Bantuan)'),
            (v_nik_ditawar, v_nik_penawar, p_id_transaksi, 'transfer_masuk', v_total_skillcoin_ditawar, v_saldo_sebelum_ditawar, v_saldo_sebelum_ditawar + v_total_skillcoin_ditawar, 'Penerimaan Jasa (Bantuan)');
            
            -- 4. Notifikasi
            INSERT INTO notifikasi (nik_pengguna, judul, isi_pesan, tipe)
            VALUES (v_nik_penawar, 'Pembayaran Berhasil', CONCAT('Anda membayar ', v_total_skillcoin_ditawar, ' skillcoin'), 'skillcoin');
            
            INSERT INTO notifikasi (nik_pengguna, judul, isi_pesan, tipe)
            VALUES (v_nik_ditawar, 'Menerima Bayaran', CONCAT('Anda menerima ', v_total_skillcoin_ditawar, ' skillcoin'), 'skillcoin');
            
        ELSE
            -- Gagal jika saldo kurang
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Saldo tidak cukup untuk membayar jasa';
        END IF;

    ELSE
        -- KASUS B: BARTER / TUKAR SKILL
        -- Logika: Sistem Memberi REWARD ke KEDUA PIHAK
        
        -- 1. Beri Reward ke Penawar (Jika dia mengajar sesuatu)
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
        
        -- 2. Beri Reward ke Ditawar/Partner
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
    
    -- 3. Update Status Transaksi (Finish)
    UPDATE transaksi_barter 
    SET status = 'terkonfirmasi',
        skillcoin_ditransfer = TRUE,
        diperbarui_pada = NOW()
    WHERE id = p_id_transaksi;
    
    -- 4. Log Akhir
    INSERT INTO log_transaksi (id_transaksi, nik_pengguna, aksi, keterangan) VALUES 
    (p_id_transaksi, v_nik_penawar, 'selesai', 'Transaksi Selesai'),
    (p_id_transaksi, v_nik_ditawar, 'selesai', 'Transaksi Selesai');
    
    COMMIT;
END$$

DELIMITER ;
