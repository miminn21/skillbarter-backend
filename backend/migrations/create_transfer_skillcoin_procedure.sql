-- Migration: Create stored procedure for SkillCoin transfer
-- Purpose: Atomic transfer of SkillCoin between users with transaction safety
-- Date: 2026-01-16

DELIMITER $$

DROP PROCEDURE IF EXISTS transfer_skillcoin$$

CREATE PROCEDURE transfer_skillcoin(
  IN p_nik_pengirim VARCHAR(16),
  IN p_nik_penerima VARCHAR(16),
  IN p_jumlah INT,
  IN p_id_barter INT,
  IN p_keterangan TEXT
)
BEGIN
  DECLARE v_saldo_pengirim INT;
  DECLARE v_saldo_penerima INT;
  DECLARE v_saldo_pengirim_baru INT;
  DECLARE v_saldo_penerima_baru INT;
  
  -- Error handler
  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    ROLLBACK;
    RESIGNAL;
  END;

  IF p_jumlah <= 0 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Jumlah transfer harus positif';
  END IF;
  
  START TRANSACTION;
  
  -- Lock and check sender balance
  SELECT saldo_skillcoin INTO v_saldo_pengirim
  FROM pengguna 
  WHERE nik = p_nik_pengirim 
  FOR UPDATE;
  
  IF v_saldo_pengirim IS NULL THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Pengirim tidak ditemukan';
  END IF;
  
  IF v_saldo_pengirim < p_jumlah THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Saldo SkillCoin tidak mencukupi';
  END IF;

  -- Get receiver balance
  SELECT saldo_skillcoin INTO v_saldo_penerima
  FROM pengguna 
  WHERE nik = p_nik_penerima;
  
  IF v_saldo_penerima IS NULL THEN
     SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Penerima tidak ditemukan';
  END IF;

  -- Calculate new balances
  SET v_saldo_pengirim_baru = v_saldo_pengirim - p_jumlah;
  SET v_saldo_penerima_baru = v_saldo_penerima + p_jumlah;
  
  -- Update sender
  UPDATE pengguna 
  SET saldo_skillcoin = v_saldo_pengirim_baru
  WHERE nik = p_nik_pengirim;
  
  -- Update receiver
  UPDATE pengguna
  SET saldo_skillcoin = v_saldo_penerima_baru
  WHERE nik = p_nik_penerima;
  
  -- Record transaction (Sender side - Transfer Out)
  INSERT INTO transaksi_skillcoin 
    (nik_pengguna, penerima_nik, id_transaksi, jumlah, jenis, saldo_sebelum, saldo_sesudah, keterangan)
  VALUES 
    (p_nik_pengirim, p_nik_penerima, p_id_barter, -p_jumlah, 'transfer_keluar', v_saldo_pengirim, v_saldo_pengirim_baru, p_keterangan);

  -- Record transaction (Receiver side - Transfer In)
  INSERT INTO transaksi_skillcoin 
    (nik_pengguna, penerima_nik, id_transaksi, jumlah, jenis, saldo_sebelum, saldo_sesudah, keterangan)
  VALUES 
    (p_nik_penerima, p_nik_pengirim, p_id_barter, p_jumlah, 'transfer_masuk', v_saldo_penerima, v_saldo_penerima_baru, p_keterangan);
  
  COMMIT;
END$$

DELIMITER ;
