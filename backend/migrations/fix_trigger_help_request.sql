-- Fix trigger setelah_buat_transaksi to handle help requests (id_keahlian_penawar NULL)
USE skillbarter_db;

DELIMITER $$

DROP TRIGGER IF EXISTS setelah_buat_transaksi$$

CREATE TRIGGER setelah_buat_transaksi
AFTER INSERT ON transaksi_barter
FOR EACH ROW
BEGIN
    DECLARE v_nama_penawar VARCHAR(50);
    DECLARE v_nama_ditawar VARCHAR(50);
    DECLARE v_nama_keahlian_ditawarkan VARCHAR(100);
    DECLARE v_nama_keahlian_diminta VARCHAR(100);
    DECLARE v_pesan_penawar TEXT;
    DECLARE v_pesan_ditawar TEXT;
    
    -- Ambil data untuk pesan
    SELECT nama_panggilan INTO v_nama_penawar
    FROM pengguna WHERE nik = NEW.nik_penawar;
    
    SELECT nama_panggilan INTO v_nama_ditawar
    FROM pengguna WHERE nik = NEW.nik_ditawar;
    
    -- Handle NULL id_keahlian_penawar for help requests
    IF NEW.id_keahlian_penawar IS NOT NULL THEN
        SELECT nama_keahlian INTO v_nama_keahlian_ditawarkan
        FROM keahlian WHERE id = NEW.id_keahlian_penawar;
    ELSE
        SET v_nama_keahlian_ditawarkan = NULL;
    END IF;
    
    SELECT nama_keahlian INTO v_nama_keahlian_diminta
    FROM keahlian WHERE id = NEW.id_keahlian_diminta;
    
    -- Build messages based on transaction type
    IF NEW.tipe_transaksi = 'bantuan' THEN
        -- Help request messages
        SET v_pesan_penawar = CONCAT('Anda mengajukan permintaan bantuan untuk ', v_nama_keahlian_diminta, ' ke ', v_nama_ditawar, '. Menunggu konfirmasi.');
        SET v_pesan_ditawar = CONCAT(v_nama_penawar, ' meminta bantuan untuk ', v_nama_keahlian_diminta, '. Silakan konfirmasi.');
    ELSE
        -- Barter messages
        SET v_pesan_penawar = CONCAT('Anda mengajukan barter ke ', v_nama_ditawar, '. Menunggu konfirmasi.');
        SET v_pesan_ditawar = CONCAT(v_nama_penawar, ' mengajukan barter: ', 
                                     COALESCE(v_nama_keahlian_ditawarkan, 'Skill'), 
                                     ' untuk ', v_nama_keahlian_diminta, '. Silakan konfirmasi.');
    END IF;
    
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
        v_pesan_penawar,
        'sistem',
        JSON_OBJECT('auto_message', TRUE, 'transaction_id', NEW.id, 'transaction_type', NEW.tipe_transaksi)
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
        v_pesan_ditawar,
        'sistem',
        JSON_OBJECT('auto_message', TRUE, 'transaction_id', NEW.id, 'transaction_type', NEW.tipe_transaksi)
    );
END$$

DELIMITER ;

-- Verify trigger was created
SHOW TRIGGERS WHERE `Table` = 'transaksi_barter';
