const db = require('../config/database');

class Pesan {
    static async create(data) {
        const { nik_pengirim, nik_penerima, id_transaksi, isi_pesan, tipe } = data;
        const query = `
            INSERT INTO pesan (nik_pengirim, nik_penerima, id_transaksi, isi_pesan, tipe)
            VALUES (?, ?, ?, ?, ?)
        `;
        const [result] = await db.execute(query, [nik_pengirim, nik_penerima, id_transaksi, isi_pesan, tipe || 'teks']);
        return result.insertId;
    }

    static async getByTransactionId(transactionId) {
        const query = `
            SELECT * FROM pesan 
            WHERE id_transaksi = ? 
            ORDER BY dibuat_pada ASC
        `;
        const [rows] = await db.execute(query, [transactionId]);
        return rows;
    }
}

module.exports = Pesan;
