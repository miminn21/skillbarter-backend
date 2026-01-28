const Pesan = require('../models/Pesan');

exports.sendMessage = async (req, res) => {
    try {
        const { id_transaksi, nik_penerima, isi_pesan, tipe } = req.body;
        const nik_pengirim = req.user.nik; // Assumes auth middleware populates req.user

        if (!id_transaksi || !nik_penerima || !isi_pesan) {
            return res.status(400).json({
                success: false,
                message: 'Data tidak lengkap'
            });
        }

        const messageId = await Pesan.create({
            nik_pengirim,
            nik_penerima,
            id_transaksi,
            isi_pesan,
            tipe
        });

        res.status(201).json({
            success: true,
            data: { id: messageId },
            message: 'Pesan terkirim'
        });
    } catch (error) {
        console.error('Error sending message:', error);
        res.status(500).json({
            success: false,
            message: 'Gagal mengirim pesan'
        });
    }
};

exports.getHistory = async (req, res) => {
    try {
        const { transactionId } = req.params;
        const messages = await Pesan.getByTransactionId(transactionId);
        
        res.status(200).json({
            success: true,
            data: messages
        });
    } catch (error) {
        console.error('Error fetching chat history:', error);
        res.status(500).json({
            success: false,
            message: 'Gagal mengambil riwayat chat'
        });
    }
};
