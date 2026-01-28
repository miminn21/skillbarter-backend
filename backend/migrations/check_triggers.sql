-- Check for triggers that might reference isi_pesan
USE skillbarter_db;

-- Show all triggers on transaksi_barter table
SHOW TRIGGERS WHERE `Table` = 'transaksi_barter';

-- Show trigger details
SELECT 
    TRIGGER_NAME,
    EVENT_MANIPULATION,
    EVENT_OBJECT_TABLE,
    ACTION_STATEMENT,
    ACTION_TIMING
FROM information_schema.TRIGGERS
WHERE EVENT_OBJECT_SCHEMA = 'skillbarter_db'
  AND EVENT_OBJECT_TABLE = 'transaksi_barter';
