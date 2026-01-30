const mysql = require('mysql2/promise');

const RAILWAY_CONFIG = {
    host: 'switchyard.proxy.rlwy.net', port: 38963, user: 'root', password: 'fSexsPKyjZtWdhESBvdEFrfBTFSORsfw', database: 'railway', multipleStatements: true
};

async function manualFixProcedure() {
    console.log('🛠️ MENULIS ULANG PROCEDURE SECARA MANUAL (EXPLICIT COLLATION)...');
    const conn = await mysql.createConnection(RAILWAY_CONFIG);

    try {
        // Drop dulu
        await conn.query("DROP PROCEDURE IF EXISTS proses_transaksi_barter");

        // Definisi Baru (Copied from Local but enhanced with CHARSET/COLLATE)
        const sql = `
        CREATE PROCEDURE proses_transaksi_barter(
            IN p_id_transaksi INT
        )
        BEGIN
            DECLARE v_nik_penawar VARCHAR(16) CHARSET utf8mb4 COLLATE utf8mb4_general_ci;
            DECLARE v_nik_ditawar VARCHAR(16) CHARSET utf8mb4 COLLATE utf8mb4_general_ci;
            DECLARE v_total_skillcoin_penawar INT;
            DECLARE v_total_skillcoin_ditawar INT;
            DECLARE v_status VARCHAR(20) CHARSET utf8mb4 COLLATE utf8mb4_general_ci;
            DECLARE v_tipe VARCHAR(20) CHARSET utf8mb4 COLLATE utf8mb4_general_ci;

            -- Ambil Data
            SELECT nik_penawar, nik_ditawar, total_skillcoin_penawar, total_skillcoin_ditawar, status, tipe_transaksi
            INTO v_nik_penawar, v_nik_ditawar, v_total_skillcoin_penawar, v_total_skillcoin_ditawar, v_status, v_tipe
            FROM transaksi_barter
            WHERE id = p_id_transaksi;

            -- Cek Status (Explicit Collate comparison)
            IF v_status = 'berlangsung' COLLATE utf8mb4_general_ci OR v_status = 'Berlangsung' COLLATE utf8mb4_general_ci THEN
                
                -- Update Status jadi Selesai
                UPDATE transaksi_barter 
                SET status = 'selesai', tanggal_selesai = NOW()
                WHERE id = p_id_transaksi;

                -- Logika Transfer Coin
                IF v_total_skillcoin_penawar > 0 THEN
                     UPDATE pengguna SET skill_coin = skill_coin - v_total_skillcoin_penawar WHERE nik = v_nik_penawar;
                     UPDATE pengguna SET skill_coin = skill_coin + v_total_skillcoin_penawar WHERE nik = v_nik_ditawar;
                     
                     INSERT INTO transaksi_skillcoin (nik_pengirim, nik_penerima, jumlah, tipe, referensi_id)
                     VALUES (v_nik_penawar, v_nik_ditawar, v_total_skillcoin_penawar, 'pembayaran_jasa', p_id_transaksi);
                END IF;

                IF v_total_skillcoin_ditawar > 0 THEN
                     UPDATE pengguna SET skill_coin = skill_coin - v_total_skillcoin_ditawar WHERE nik = v_nik_ditawar;
                     UPDATE pengguna SET skill_coin = skill_coin + v_total_skillcoin_ditawar WHERE nik = v_nik_penawar;

                     INSERT INTO transaksi_skillcoin (nik_pengirim, nik_penerima, jumlah, tipe, referensi_id)
                     VALUES (v_nik_ditawar, v_nik_penawar, v_total_skillcoin_ditawar, 'pembayaran_jasa', p_id_transaksi);
                END IF;

                -- Notifikasi
                INSERT INTO notifikasi (nik_penerima, judul, pesan, tipe, referensi_id)
                VALUES (v_nik_penawar, 'Transaksi Selesai', 'Transaksi barter Anda telah selesai.', 'transaksi', p_id_transaksi);
                
                INSERT INTO notifikasi (nik_penerima, judul, pesan, tipe, referensi_id)
                VALUES (v_nik_ditawar, 'Transaksi Selesai', 'Transaksi barter Anda telah selesai.', 'transaksi', p_id_transaksi);

            END IF;
        END
        `;

        await conn.query(sql);
        console.log("✅ Procedure MANUAL created successfully.");

        // Test Trigger ID 28
        console.log("⚡ Retrying Manual Trigger (ID 28)...");
        await conn.query("CALL proses_transaksi_barter(28)");
        console.log("🎉 BERHASIL!!! (Akhirnya...)");

    } catch (e) {
        console.error("❌ MASIH GAGAL JUGA?!:", e.message);
    } finally {
        conn.end();
    }
}
manualFixProcedure();
