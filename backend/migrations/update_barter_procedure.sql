-- Update barter transaction procedure to handle corrected logic
-- Both users earn SkillCoin for teaching their skill

DROP PROCEDURE IF EXISTS proses_transaksi_barter;

DELIMITER $$
CREATE PROCEDURE proses_transaksi_barter(IN p_id_transaksi INT)
BEGIN
  DECLARE v_nik_penawar VARCHAR(16);
  DECLARE v_nik_ditawar VARCHAR(16);
  DECLARE v_harga_penawar INT;
  DECLARE v_harga_diminta INT;
  DECLARE v_durasi INT;
  DECLARE v_penawar_earns INT;
  DECLARE v_diminta_earns INT;
  DECLARE v_tipe_transaksi VARCHAR(20);
  
  -- Get transaction details
  SELECT 
    tb.nik_penawar,
    tb.nik_ditawar,
    COALESCE(k1.harga_per_jam, 0),
    k2.harga_per_jam,
    tb.durasi_jam,
    tb.tipe_transaksi
  INTO 
    v_nik_penawar,
    v_nik_ditawar,
    v_harga_penawar,
    v_harga_diminta,
    v_durasi,
    v_tipe_transaksi
  FROM transaksi_barter tb
  LEFT JOIN keahlian k1 ON tb.id_keahlian_penawar = k1.id
  JOIN keahlian k2 ON tb.id_keahlian_diminta = k2.id
  WHERE tb.id = p_id_transaksi;
  
  IF v_tipe_transaksi = 'bantuan' THEN
    -- Help request: only penawar pays, ditawar earns
    SET v_diminta_earns = v_durasi * v_harga_diminta;
    
    CALL transfer_skillcoin(
      v_nik_penawar,
      v_nik_ditawar,
      v_diminta_earns,
      CONCAT('Help Request #', p_id_transaksi, ' - Payment for teaching')
    );
  ELSE
    -- Barter: both users earn for teaching
    SET v_penawar_earns = v_durasi * v_harga_penawar;
    SET v_diminta_earns = v_durasi * v_harga_diminta;
    
    -- Transfer: Penawar earns from Ditawar (for teaching their skill)
    CALL transfer_skillcoin(
      v_nik_ditawar,
      v_nik_penawar,
      v_penawar_earns,
      CONCAT('Barter #', p_id_transaksi, ' - Payment for teaching ', 
        (SELECT nama_keahlian FROM keahlian WHERE id = 
          (SELECT id_keahlian_penawar FROM transaksi_barter WHERE id = p_id_transaksi)))
    );
    
    -- Transfer: Ditawar earns from Penawar (for teaching their skill)
    CALL transfer_skillcoin(
      v_nik_penawar,
      v_nik_ditawar,
      v_diminta_earns,
      CONCAT('Barter #', p_id_transaksi, ' - Payment for teaching ',
        (SELECT nama_keahlian FROM keahlian WHERE id = 
          (SELECT id_keahlian_diminta FROM transaksi_barter WHERE id = p_id_transaksi)))
    );
  END IF;
  
  -- Mark as transferred
  UPDATE transaksi_barter 
  SET skillcoin_ditransfer = TRUE 
  WHERE id = p_id_transaksi;
END$$
DELIMITER ;
