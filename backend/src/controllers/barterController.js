const Barter = require('../models/Barter');
const SkillcoinService = require('../services/skillcoinService');
const db = require('../config/database');

/**
 * Helper function to get user's SkillCoin balance
 */
async function getRequesterBalance(nik) {
  const [rows] = await db.execute(
    'SELECT saldo_skillcoin FROM pengguna WHERE nik = ?',
    [nik]
  );
  return rows.length > 0 ? rows[0].saldo_skillcoin : 0;
}

/**
 * Barter Controller
 * Handles barter offer/transaction operations
 */

/**
 * Create new barter offer
 */
exports.createOffer = async (req, res) => {
  try {
    const {
      nik_ditawar,
      id_keahlian_penawar,
      id_keahlian_diminta,
      id_skill_request,
      tipe_transaksi,      // NEW: 'barter' or 'bantuan'
      durasi_jam,
      tanggal_pelaksanaan,
      tipe_lokasi,
      detail_lokasi,
      catatan_penawar
    } = req.body;

    const nik_penawar = req.user.nik;

    // Log incoming request
    console.log('[CreateOffer] Request from:', nik_penawar);
    console.log('[CreateOffer] Body:', JSON.stringify(req.body, null, 2));

    // Validate required fields based on transaction type
    const missing = [];
    if (!nik_ditawar) missing.push('nik_ditawar');
    // Validate required fields
    if (!nik_ditawar || !id_keahlian_diminta || !durasi_jam || !tanggal_pelaksanaan) {
      console.log('[CreateOffer] Missing required fields');
      return res.status(400).json({
        success: false,
        message: 'Missing required fields'
      });
    }

    // Detect transaction type based on id_keahlian_penawar
    const isHelpRequest = !id_keahlian_penawar;
    const actualTipeTransaksi = isHelpRequest ? 'bantuan' : 'barter';
    
    console.log('[CreateOffer] Transaction type:', actualTipeTransaksi);
    console.log('[CreateOffer] Is help request:', isHelpRequest);

    // Calculate SkillCoin based on transaction type
    let skillcoinCalculation;
    
    if (isHelpRequest) {
      // Help request mode: only calculate cost for requester
      console.log('[CreateOffer] Calculating help request cost...');
      skillcoinCalculation = await SkillcoinService.calculateHelpRequestCost(
        id_keahlian_diminta,
        durasi_jam
      );
      
      // Validate requester has enough balance
      const requesterBalance = await getRequesterBalance(nik_penawar);
      const totalCost = skillcoinCalculation.total_cost;
      
      console.log('[CreateOffer] Requester balance:', requesterBalance);
      console.log('[CreateOffer] Total cost:', totalCost);
      
      if (requesterBalance < totalCost) {
        console.log('[CreateOffer] Insufficient balance!');
        return res.status(400).json({
          success: false,
          message: `Saldo SkillCoin tidak cukup. Dibutuhkan ${totalCost} coin, saldo Anda ${requesterBalance} coin.`
        });
      }
    } else {
      // Barter mode: calculate for both parties
      console.log('[CreateOffer] Calculating barter skillcoin...');
      skillcoinCalculation = await SkillcoinService.calculateBarterSkillcoin(
        id_keahlian_penawar,
        id_keahlian_diminta,
        durasi_jam
      );
    }
    console.log('[CreateOffer] Skillcoin calculation result:', skillcoinCalculation);

    // Create offer
    const offerData = {
      nik_penawar: nik_penawar,
      nik_ditawar,
      id_keahlian_penawar: id_keahlian_penawar || null,
      id_keahlian_diminta,
      id_skill_request: id_skill_request || null,
      tipe_transaksi: actualTipeTransaksi,
      durasi_jam,
      tanggal_pelaksanaan,
      tipe_lokasi: tipe_lokasi || 'online',
      detail_lokasi: detail_lokasi || null,
      catatan_penawar: catatan_penawar || null
    };

    console.log('[CreateOffer] Creating offer with data:', offerData);
    
    const result = await Barter.create(offerData);
    const offerId = result.insertId;

    // Log action
    await Barter.logAction(offerId, nik_penawar, 'ajukan', 'Offer created');

    // Get created offer
    const offer = await Barter.findById(offerId);

    console.log('[CreateOffer] Success! Offer ID:', offerId);

    res.status(201).json({
      success: true,
      message: isHelpRequest ? 'Permintaan bantuan berhasil dibuat' : 'Penawaran barter berhasil dibuat',
      data: {
        ...offer,
        skillcoin_calculation: skillcoinCalculation
      }
    });
  } catch (error) {
    console.error('Create offer error:', error);
    res.status(500).json({
      success: false,
      message: `Failed to create offer: ${error.message}`
    });
  }
};

/**
 * Get offer detail
 */
exports.getOfferDetail = async (req, res) => {
  try {
    const { id } = req.params;
    const userNik = req.user.nik;

    // Check if user is participant
    const isParticipant = await Barter.isParticipant(id, userNik);
    if (!isParticipant) {
      return res.status(403).json({
        success: false,
        message: 'You do not have access to this offer'
      });
    }

    const offer = await Barter.findById(id);
    
    if (!offer) {
      return res.status(404).json({
        success: false,
        message: 'Offer not found'
      });
    }

    // Get transaction logs
    const logs = await Barter.getLogs(id);

    // Calculate skillcoin
    // Calculate skillcoin based on transaction type
    let skillcoinCalc;
    if (offer.tipe_transaksi === 'bantuan' || !offer.id_keahlian_penawar) {
      skillcoinCalc = await SkillcoinService.calculateHelpRequestCost(
        offer.id_keahlian_diminta,
        offer.durasi_jam
      );
    } else {
      skillcoinCalc = await SkillcoinService.calculateBarterSkillcoin(
        offer.id_keahlian_penawar,
        offer.id_keahlian_diminta,
        offer.durasi_jam
      );
    }

    res.json({
      success: true,
      message: 'Offer details retrieved successfully',
      data: {
        ...offer,
        logs,
        skillcoin_calculation: skillcoinCalc
      }
    });
  } catch (error) {
    console.error('Get offer detail error:', error);
    res.status(500).json({
      success: false,
      message: `Failed to get offer details: ${error.message}`
    });
  }
};

/**
 * Get user's offers
 */
exports.getUserOffers = async (req, res) => {
  try {
    const userNik = req.user.nik;
    const { role, status } = req.query; // role: sent/received/all, status: menunggu/diterima/etc

    const offers = await Barter.getUserOffers(userNik, role, status);

    res.json({
      success: true,
      message: 'Offers retrieved successfully',
      data: offers
    });
  } catch (error) {
    console.error('Get user offers error:', error);
    res.status(500).json({
      success: false,
      message: `Failed to get offers: ${error.message}`
    });
  }
};

/**
 * Accept offer
 */
/**
 * Reject offer
 */
exports.rejectOffer = async (req, res) => {
  try {
    const { id } = req.params;
    const { reason } = req.body;
    const userNik = req.user.nik;

    // Check if user is receiver
    const isReceiver = await Barter.isReceiver(id, userNik);
    if (!isReceiver) {
      return res.status(403).json({
        success: false,
        message: 'Only the receiver can reject this offer'
      });
    }

    // Check current status
    const offer = await Barter.findById(id);
    if (offer.status !== 'menunggu') {
      return res.status(400).json({
        success: false,
        message: `Cannot reject offer with status: ${offer.status}`
      });
    }

    await Barter.reject(id, userNik, reason);

    const updatedOffer = await Barter.findById(id);

    res.json({
      success: true,
      message: 'Offer rejected successfully',
      data: updatedOffer
    });
  } catch (error) {
    console.error('Reject offer error:', error);
    res.status(500).json({
      success: false,
      message: `Failed to reject offer: ${error.message}`
    });
  }
};

/**
 * Cancel offer (by sender)
 */
exports.cancelOffer = async (req, res) => {
  try {
    const { id } = req.params;
    const { reason } = req.body;
    const userNik = req.user.nik;

    // Check if user is sender
    const offer = await Barter.findById(id);
    if (offer.nik_penawar !== userNik) {
      return res.status(403).json({
        success: false,
        message: 'Only the sender can cancel this offer'
      });
    }

    // Check current status - can only cancel if menunggu
    if (offer.status !== 'menunggu') {
      return res.status(400).json({
        success: false,
        message: `Cannot cancel offer with status: ${offer.status}. Use delete for rejected offers.`
      });
    }

    await Barter.cancel(id, userNik, reason);

    const updatedOffer = await Barter.findById(id);

    res.json({
      success: true,
      message: 'Offer cancelled successfully',
      data: updatedOffer
    });
  } catch (error) {
    console.error('Cancel offer error:', error);
    res.status(500).json({
      success: false,
      message: `Failed to cancel offer: ${error.message}`
    });
  }
};

/**
 * Delete offer (permanent)
 * Only for ditolak and dibatalkan status
 */
exports.deleteOffer = async (req, res) => {
  try {
    const { id } = req.params;
    const userNik = req.user.nik;

    const offer = await Barter.findById(id);
    
    // Check if offer exists
    if (!offer) {
      return res.status(404).json({
        success: false,
        message: 'Offer not found or already deleted'
      });
    }
    
    // Only sender can delete
    if (offer.nik_penawar !== userNik) {
      return res.status(403).json({
        success: false,
        message: 'Only the sender can delete this offer'
      });
    }

    // Can only delete rejected or cancelled
    if (!['ditolak', 'dibatalkan'].includes(offer.status)) {
      return res.status(400).json({
        success: false,
        message: `Cannot delete offer with status: ${offer.status}. Only rejected or cancelled offers can be deleted.`
      });
    }

    await Barter.delete(id);

    res.json({
      success: true,
      message: 'Offer deleted successfully'
    });
  } catch (error) {
    console.error('Delete offer error:', error);
    res.status(500).json({
      success: false,
      message: `Failed to delete offer: ${error.message}`
    });
  }
};

/**
 * Cancel offer
 */
exports.cancelOffer = async (req, res) => {
  try {
    const { id } = req.params;
    const { reason } = req.body;
    const userNik = req.user.nik;

    // Check if user is participant
    const isParticipant = await Barter.isParticipant(id, userNik);
    if (!isParticipant) {
      return res.status(403).json({
        success: false,
        message: 'You do not have access to this offer'
      });
    }

    const offer = await Barter.findById(id);

    // Only sender can cancel pending offers
    // Both can cancel accepted offers (with penalty)
    if (offer.status === 'menunggu' && offer.nik_penawar !== userNik) {
      return res.status(403).json({
        success: false,
        message: 'Only the sender can cancel a pending offer'
      });
    }

    if (!['menunggu', 'diterima'].includes(offer.status)) {
      return res.status(400).json({
        success: false,
        message: `Cannot cancel offer with status: ${offer.status}`
      });
    }

    await Barter.cancel(id, userNik, reason);

    const updatedOffer = await Barter.findById(id);

    res.json({
      success: true,
      message: 'Offer cancelled successfully',
      data: updatedOffer
    });
  } catch (error) {
    console.error('Cancel offer error:', error);
    res.status(500).json({
      success: false,
      message: `Failed to cancel offer: ${error.message}`
    });
  }
};

/**
 * Accept offer
 */
exports.acceptOffer = async (req, res) => {
  try {
    const { id } = req.params;
    const userNik = req.user.nik;

    const isParticipant = await Barter.isParticipant(id, userNik);
    if (!isParticipant) {
      return res.status(403).json({
        success: false,
        message: 'You do not have access to this offer'
      });
    }

    const offer = await Barter.findById(id);
    if (offer.status !== 'menunggu') {
      return res.status(400).json({
        success: false,
        message: 'Can only accept pending offers'
      });
    }

    // Accept the offer
    await Barter.accept(id, userNik);

    // Create initial confirmation records for both parties
    const db = require('../config/database');
    await db.execute(`
      INSERT INTO barter_confirmations (id_barter, nik, konfirmasi_selesai) 
      VALUES (?, ?, FALSE), (?, ?, FALSE)
    `, [id, offer.nik_penawar, id, offer.nik_ditawar]);

    console.log(`[AcceptOffer] Created confirmation records for barter ${id}`);

    const updatedOffer = await Barter.findById(id);

    res.json({
      success: true,
      message: 'Offer accepted successfully',
      data: updatedOffer
    });
  } catch (error) {
    console.error('Accept offer error:', error);
    res.status(500).json({
      success: false,
      message: error.message
    });
  }
};

/**
 * Start barter session
 */
exports.startSession = async (req, res) => {
  try {
    const { id } = req.params;
    const userNik = req.user.nik;

    const isParticipant = await Barter.isParticipant(id, userNik);
    if (!isParticipant) {
      return res.status(403).json({
        success: false,
        message: 'You do not have access to this offer'
      });
    }

    const offer = await Barter.findById(id);
    if (offer.status !== 'diterima') {
      return res.status(400).json({
        success: false,
        message: 'Can only start accepted offers'
      });
    }

    await Barter.markOngoing(id, userNik);

    const updatedOffer = await Barter.findById(id);

    res.json({
      success: true,
      message: 'Barter session started',
      data: updatedOffer
    });
  } catch (error) {
    console.error('Start session error:', error);
    res.status(500).json({
      success: false,
      message: `Failed to start session: ${error.message}`
    });
  }
};

/**
 * Complete barter session
 */
exports.completeSession = async (req, res) => {
  try {
    const { id } = req.params;
    const userNik = req.user.nik;

    const isParticipant = await Barter.isParticipant(id, userNik);
    if (!isParticipant) {
      return res.status(403).json({
        success: false,
        message: 'You do not have access to this offer'
      });
    }

    const offer = await Barter.findById(id);
    if (offer.status !== 'berlangsung') {
      return res.status(400).json({
        success: false,
        message: 'Can only complete ongoing sessions'
      });
    }

    await Barter.markCompleted(id, userNik);

    const updatedOffer = await Barter.findById(id);

    res.json({
      success: true,
      message: 'Session marked as completed. Waiting for confirmation.',
      data: updatedOffer
    });
  } catch (error) {
    console.error('Complete session error:', error);
    res.status(500).json({
      success: false,
      message: `Failed to complete session: ${error.message}`
    });
  }
};

/**
 * Confirm completion and transfer skillcoin
 */
exports.confirmCompletion = async (req, res) => {
  try {
    const { id } = req.params;
    const userNik = req.user.nik;

    const isParticipant = await Barter.isParticipant(id, userNik);
    if (!isParticipant) {
      return res.status(403).json({
        success: false,
        message: 'You do not have access to this offer'
      });
    }

    const offer = await Barter.findById(id);
    // Allow confirmation for berlangsung or selesai status
    if (!['berlangsung', 'selesai'].includes(offer.status)) {
      return res.status(400).json({
        success: false,
        message: `Cannot confirm. Current status: ${offer.status}`
      });
    }

    // Update user's confirmation in barter_confirmations
    const db = require('../config/database');
    await db.execute(`
      UPDATE barter_confirmations 
      SET konfirmasi_selesai = TRUE,
          waktu_konfirmasi = NOW()
      WHERE id_barter = ? AND nik = ?
    `, [id, userNik]);

    console.log('[ConfirmCompletion] User', userNik, 'confirmed barter', id);

    // Check if both parties have confirmed
    const [confirmations] = await db.execute(`
      SELECT COUNT(*) as confirmed_count
      FROM barter_confirmations
      WHERE id_barter = ? AND konfirmasi_selesai = TRUE
    `, [id]);

    const bothConfirmed = confirmations[0].confirmed_count === 2;
    console.log('[ConfirmCompletion] Both confirmed:', bothConfirmed);

    if (bothConfirmed) {
      console.log('[ConfirmCompletion] Both parties confirmed - completing barter via Model');
      
      // Delegate to Model -> Calls Stored Procedure (Hybrid Logic Is Here)
      // The SP handles status update, skillcoin transfer/reward, and logging atomically.
      await Barter.confirmCompletion(id, userNik);
    }

    const updatedOffer = await Barter.findById(id);

    res.json({
      success: true,
      message: bothConfirmed 
        ? 'Barter completed! Skillcoin processed.' 
        : 'Confirmation recorded. Waiting for partner confirmation.',
      data: {
        offer: updatedOffer,
        bothConfirmed
      }
    });
  } catch (error) {
    console.error('Confirm completion error:', error);
    res.status(500).json({
      success: false,
      message: `Failed to confirm completion: ${error.message}`
    });
  }
};

/**
 * Get transaction history
 */
exports.getHistory = async (req, res) => {
  try {
    const userNik = req.user.nik;
    const { limit = 50 } = req.query;

    const history = await Barter.getHistory(userNik, parseInt(limit));

    res.json({
      success: true,
      message: 'Transaction history retrieved successfully',
      data: history
    });
  } catch (error) {
    console.error('Get history error:', error);
    res.status(500).json({
      success: false,
      message: `Failed to get history: ${error.message}`
    });
  }
};

/**
 * Get skillcoin balance
 */
exports.getSkillcoinBalance = async (req, res) => {
  try {
    const userNik = req.user.nik;
    const balance = await SkillcoinService.getBalance(userNik);

    res.json({
      success: true,
      message: 'Balance retrieved successfully',
      data: { balance }
    });
  } catch (error) {
    console.error('Get balance error:', error);
    res.status(500).json({
      success: false,
      message: `Failed to get balance: ${error.message}`
    });
  }
};

/**
 * Get skillcoin transaction history
 */
exports.getSkillcoinHistory = async (req, res) => {
  try {
    const userNik = req.user.nik;
    const { limit = 50 } = req.query;

    const history = await SkillcoinService.getHistory(userNik, parseInt(limit));
    const statistics = await SkillcoinService.getStatistics(userNik);

    res.json({
      success: true,
      message: 'Skillcoin history retrieved successfully',
      data: {
        history,
        statistics
      }
    });
  } catch (error) {
    console.error('Get skillcoin history error:', error);
    res.status(500).json({
      success: false,
      message: `Failed to get skillcoin history: ${error.message}`
    });
  }
};

/**
 * Upload proof of completion
 * POST /api/barter/:id/upload-proof
 */
exports.uploadProof = async (req, res) => {
  try {
    const { id } = req.params;
    const { bukti_pelaksanaan, jenis_bukti } = req.body;
    const userNik = req.user.nik;

    // Validate required fields
    if (!bukti_pelaksanaan || !jenis_bukti) {
      return res.status(400).json({
        success: false,
        message: 'Missing required fields: bukti_pelaksanaan, jenis_bukti'
      });
    }

    // Check if user is part of this transaction
    const offer = await Barter.findById(id);
    if (!offer) {
      return res.status(404).json({
        success: false,
        message: 'Transaction not found'
      });
    }

    if (offer.nik_penawar !== userNik && offer.nik_ditawar !== userNik) {
      return res.status(403).json({
        success: false,
        message: 'You are not authorized to upload proof for this transaction'
      });
    }

    // Upload proof
    await Barter.uploadProof(id, bukti_pelaksanaan, jenis_bukti);
    await Barter.logAction(id, userNik, 'selesai', 'Proof of completion uploaded');

    // Get updated offer
    const updatedOffer = await Barter.findById(id);

    res.json({
      success: true,
      message: 'Proof uploaded successfully',
      data: updatedOffer
    });
  } catch (error) {
    console.error('Upload proof error:', error);
    res.status(500).json({
      success: false,
      message: `Failed to upload proof: ${error.message}`
    });
  }
};

/**
 * Get proof of completion
 * GET /api/barter/:id/proof
 */
exports.getProof = async (req, res) => {
  try {
    const { id } = req.params;
    const userNik = req.user.nik;

    // Check if user is part of this transaction
    const offer = await Barter.findById(id);
    if (!offer) {
      return res.status(404).json({
        success: false,
        message: 'Transaction not found'
      });
    }

    if (offer.nik_penawar !== userNik && offer.nik_ditawar !== userNik) {
      return res.status(403).json({
        success: false,
        message: 'You are not authorized to view proof for this transaction'
      });
    }

    const proof = await Barter.getProof(id);

    if (!proof) {
      return res.status(404).json({
        success: false,
        message: 'No proof uploaded yet'
      });
    }

    res.json({
      success: true,
      message: 'Proof retrieved successfully',
      data: proof
    });
  } catch (error) {
    console.error('Get proof error:', error);
    res.status(500).json({
      success: false,
      message: `Failed to get proof: ${error.message}`
    });
  }
};
