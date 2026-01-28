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
    
    -- Ambil data transaksi
    SELECT 
        tb.nik_penawar,
        tb.nik_ditawar,
        tb.durasi_jam,
        IFNULL(k1.harga_per_jam, 0),
        IFNULL(k2.harga_per_jam, 0)
    INTO 
        v_nik_penawar,
        v_nik_ditawar,
        v_durasi_jam,
        v_harga_penawar,
        v_harga_ditawar
    FROM transaksi_barter tb
    LEFT JOIN keahlian k1 ON tb.id_keahlian_penawar = k1.id
    LEFT JOIN keahlian k2 ON tb.id_keahlian_diminta = k2.id
    WHERE tb.id = p_id_transaksi;
    
    -- Hitung skillcoin (Pastikan tidak 0 jika skill ada)
    SET v_total_skillcoin_penawar = v_durasi_jam * v_harga_penawar;
    SET v_total_skillcoin_ditawar = v_durasi_jam * v_harga_ditawar;
    
    START TRANSACTION;
    
    -- LOGIKA REWARD: SISTEM MEMBERI KOIN KE KEDUA PIHAK (BUKAN SALING BAYAR)
    
    -- Tambah skillcoin untuk penawar (Dapat bayaran dari sistem atas skill yg diajarkan)
    IF v_total_skillcoin_penawar > 0 THEN
        CALL tambah_skillcoin(
            v_nik_penawar,
            v_total_skillcoin_penawar,
            'hasil_barter',
            CONCAT('Reward Barter: Mengajar (', v_durasi_jam, ' jam)')
        );
    END IF;
    
    -- Tambah skillcoin untuk ditawar (Dapat bayaran dari sistem atas skill yg diajarkan)
    IF v_total_skillcoin_ditawar > 0 THEN
        CALL tambah_skillcoin(
            v_nik_ditawar,
            v_total_skillcoin_ditawar,
            'hasil_barter',
            CONCAT('Reward Barter: Mengajar (', v_durasi_jam, ' jam)')
        );
    END IF;
    
    -- Update statistik pengguna
    UPDATE pengguna 
    SET total_jam_berkontribusi = total_jam_berkontribusi + v_durasi_jam,
        jumlah_transaksi = jumlah_transaksi + 1,
        diperbarui_pada = NOW()
    WHERE nik IN (v_nik_penawar, v_nik_ditawar);
    
    -- Update status transaksi
    UPDATE transaksi_barter 
    SET status = 'terkonfirmasi',
        skillcoin_ditransfer = TRUE,
        diperbarui_pada = NOW()
    WHERE id = p_id_transaksi;
    
    -- Log transaksi
    INSERT INTO log_transaksi (
        id_transaksi, nik_pengguna, aksi, keterangan
    ) VALUES 
    (p_id_transaksi, v_nik_penawar, 'selesai',
     CONCAT('Barter Selesai. Reward: +', v_total_skillcoin_penawar)),
    (p_id_transaksi, v_nik_ditawar, 'selesai',
     CONCAT('Barter Selesai. Reward: +', v_total_skillcoin_ditawar));
    
    COMMIT;
END$$

DELIMITER ;
