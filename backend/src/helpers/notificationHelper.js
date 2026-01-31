const Notification = require('../models/Notification');

/**
 * Helper functions for creating notifications
 */

// Create notification helper
async function createNotification(nik, tipe, judul, pesan, data = null) {
  try {
    await Notification.create(nik, tipe, judul, pesan, data);
  } catch (error) {
    console.error('Error creating notification:', error);
  }
}

// Notify when offer is received
async function notifyOfferReceived(offer) {
  const data = {
    id_barter: offer.id_barter,
    nik_penawar: offer.nik_penawar,
    nama_penawar: offer.nama_penawar
  };

  const isHelpRequest = offer.tipe_transaksi === 'bantuan';
  const title = isHelpRequest ? 'Permintaan Bantuan Baru' : 'Penawaran Barter Baru';
  const message = isHelpRequest 
    ? `${offer.nama_penawar} meminta bantuan jasa Anda (via SkillCoin)`
    : `${offer.nama_penawar} mengirim penawaran barter kepada Anda`;

  await createNotification(
    offer.nik_ditawar,
    'offer_received',
    title,
    message,
    data
  );
}

// Notify when offer is accepted
async function notifyOfferAccepted(offer) {
  const data = {
    id_barter: offer.id_barter,
    nik_ditawar: offer.nik_ditawar,
    nama_ditawar: offer.nama_ditawar
  };

  await createNotification(
    offer.nik_penawar,
    'offer_accepted',
    'Penawaran Diterima',
    `${offer.nama_ditawar} menerima penawaran barter Anda`,
    data
  );
}

// Notify when offer is rejected
async function notifyOfferRejected(offer) {
  const data = {
    id_barter: offer.id_barter,
    nik_ditawar: offer.nik_ditawar,
    nama_ditawar: offer.nama_ditawar
  };

  await createNotification(
    offer.nik_penawar,
    'offer_rejected',
    'Penawaran Ditolak',
    `${offer.nama_ditawar} menolak penawaran barter Anda`,
    data
  );
}

// Notify when offer is cancelled
async function notifyOfferCancelled(offer) {
  const data = {
    id_barter: offer.id_barter,
    nik_penawar: offer.nik_penawar,
    nama_penawar: offer.nama_penawar
  };

  await createNotification(
    offer.nik_ditawar,
    'offer_cancelled',
    'Penawaran Dibatalkan',
    `${offer.nama_penawar} membatalkan penawaran barter`,
    data
  );
}

// Notify when barter starts
async function notifyBarterStarted(barter) {
  const data = {
    id_barter: barter.id_barter,
    tanggal_pelaksanaan: barter.tanggal_pelaksanaan
  };

  // Notify both parties
  await createNotification(
    barter.nik_penawar,
    'barter_started',
    'Barter Dimulai',
    'Barter Anda telah dimulai. Jangan lupa konfirmasi setelah selesai!',
    data
  );

  await createNotification(
    barter.nik_ditawar,
    'barter_started',
    'Barter Dimulai',
    'Barter Anda telah dimulai. Jangan lupa konfirmasi setelah selesai!',
    data
  );
}

// Notify when confirmation is needed
async function notifyConfirmationNeeded(barter, nikConfirmed) {
  const data = {
    id_barter: barter.id_barter
  };

  // Notify the other party
  const nikToNotify = nikConfirmed === barter.nik_penawar 
    ? barter.nik_ditawar 
    : barter.nik_penawar;

  await createNotification(
    nikToNotify,
    'confirmation_needed',
    'Konfirmasi Diperlukan',
    'Partner Anda sudah konfirmasi selesai. Silakan konfirmasi juga!',
    data
  );
}

// Notify when barter is completed
async function notifyBarterCompleted(barter) {
  const data = {
    id_barter: barter.id_barter,
    total_skillcoin: barter.total_skillcoin_transfer
  };

  // Notify both parties
  await createNotification(
    barter.nik_penawar,
    'barter_completed',
    'Barter Selesai',
    'Barter telah selesai. Jangan lupa beri review!',
    data
  );

  await createNotification(
    barter.nik_ditawar,
    'barter_completed',
    'Barter Selesai',
    'Barter telah selesai. Jangan lupa beri review!',
    data
  );
}

// Notify when review is received
async function notifyReviewReceived(review, namaReviewer) {
  const data = {
    id_review: review.id_review,
    id_barter: review.id_barter,
    rating: review.rating
  };

  await createNotification(
    review.nik_reviewed,
    'review_received',
    'Review Baru',
    `${namaReviewer} memberi Anda rating ${review.rating} bintang`,
    data
  );
}

// Notify when SkillCoin is received
async function notifySkillCoinReceived(nik, jumlah, namaPengirim) {
  const data = {
    jumlah: jumlah,
    nik_pengirim: namaPengirim
  };

  await createNotification(
    nik,
    'skillcoin_received',
    'SkillCoin Diterima',
    `Anda menerima ${jumlah} SkillCoin dari ${namaPengirim}`,
    data
  );
}

// Notify when SkillCoin is sent
async function notifySkillCoinSent(nik, jumlah, namaPenerima) {
  const data = {
    jumlah: jumlah,
    nik_penerima: namaPenerima
  };

  await createNotification(
    nik,
    'skillcoin_sent',
    'SkillCoin Terkirim',
    `Anda mengirim ${jumlah} SkillCoin ke ${namaPenerima}`,
    data
  );
}

module.exports = {
  createNotification,
  notifyOfferReceived,
  notifyOfferAccepted,
  notifyOfferRejected,
  notifyOfferCancelled,
  notifyBarterStarted,
  notifyConfirmationNeeded,
  notifyBarterCompleted,
  notifyReviewReceived,
  notifySkillCoinReceived,
  notifySkillCoinSent
};
