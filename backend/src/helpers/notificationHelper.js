const Notification = require('../models/Notification');
const { sendPushNotification } = require('../services/fcmService');
const User = require('../models/User');

/**
 * Helper functions for creating notifications
 */

// Create notification helper
async function createNotification(nik, tipe, judul, pesan, data = null) {
  try {
    console.log(`[NOTIF] Creating notification: tipe=${tipe}, nik=${nik}, judul=${judul}`);
    await Notification.create(nik, tipe, judul, pesan, data);
    console.log(`[NOTIF] ✅ Notification created successfully`);
  } catch (error) {
    console.error('[NOTIF] ❌ Error creating notification:', error);
    console.error('[NOTIF] Error details:', error.message);
  }
}

// Notify when offer is received
async function notifyOfferReceived(offer) {
  console.log('[NOTIF] notifyOfferReceived called for offer:', offer.id_barter);
  
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

  // Send push notification
  try {
    const user = await User.findByNik(offer.nik_ditawar);
    if (user && user.fcm_token) {
      await sendPushNotification(user.fcm_token, {
        judul: title,
        pesan: message,
        tipe: 'offer_received',
        data: data
      });
    }
  } catch (error) {
    console.error('FCM push error:', error.message);
  }
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

  // Send push notification
  try {
    const user = await User.findByNik(offer.nik_penawar);
    if (user && user.fcm_token) {
      await sendPushNotification(user.fcm_token, {
        judul: 'Penawaran Diterima',
        pesan: `${offer.nama_ditawar} menerima penawaran barter Anda`,
        tipe: 'offer_accepted',
        data: data
      });
    }
  } catch (error) {
    console.error('FCM push error:', error.message);
  }
}

// Notify when offer is rejected
async function notifyOfferRejected(offer) {
  console.log('[NOTIF] notifyOfferRejected called for offer:', offer.id_barter);
  
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

  // Send push notification
  try {
    const user = await User.findByNik(offer.nik_penawar);
    if (user && user.fcm_token) {
      await sendPushNotification(user.fcm_token, {
        judul: 'Penawaran Ditolak',
        pesan: `${offer.nama_ditawar} menolak penawaran barter Anda`,
        tipe: 'offer_rejected',
        data: data
      });
    }
  } catch (error) {
    console.error('FCM push error:', error.message);
  }
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

  // Send push notification to both
  try {
    const penawar = await User.findByNik(barter.nik_penawar);
    if (penawar && penawar.fcm_token) {
      await sendPushNotification(penawar.fcm_token, {
        judul: 'Barter Dimulai',
        pesan: 'Barter Anda telah dimulai. Jangan lupa konfirmasi setelah selesai!',
        tipe: 'barter_started',
        data: data
      });
    }

    const ditawar = await User.findByNik(barter.nik_ditawar);
    if (ditawar && ditawar.fcm_token) {
      await sendPushNotification(ditawar.fcm_token, {
        judul: 'Barter Dimulai',
        pesan: 'Barter Anda telah dimulai. Jangan lupa konfirmasi setelah selesai!',
        tipe: 'barter_started',
        data: data
      });
    }
  } catch (error) {
    console.error('FCM push error:', error.message);
  }
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

  // Send push notification
  try {
    const user = await User.findByNik(nikToNotify);
    if (user && user.fcm_token) {
      await sendPushNotification(user.fcm_token, {
        judul: 'Konfirmasi Diperlukan',
        pesan: 'Partner Anda sudah konfirmasi selesai. Silakan konfirmasi juga!',
        tipe: 'confirmation_needed',
        data: data
      });
    }
  } catch (error) {
    console.error('FCM push error:', error.message);
  }
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

  // Send push notification to both
  try {
    const penawar = await User.findByNik(barter.nik_penawar);
    if (penawar && penawar.fcm_token) {
      await sendPushNotification(penawar.fcm_token, {
        judul: 'Barter Selesai',
        pesan: 'Barter telah selesai. Jangan lupa beri review!',
        tipe: 'barter_completed',
        data: data
      });
    }

    const ditawar = await User.findByNik(barter.nik_ditawar);
    if (ditawar && ditawar.fcm_token) {
      await sendPushNotification(ditawar.fcm_token, {
        judul: 'Barter Selesai',
        pesan: 'Barter telah selesai. Jangan lupa beri review!',
        tipe: 'barter_completed',
        data: data
      });
    }
  } catch (error) {
    console.error('FCM push error:', error.message);
  }
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

  // Send push notification
  try {
    const user = await User.findByNik(review.nik_reviewed);
    if (user && user.fcm_token) {
      await sendPushNotification(user.fcm_token, {
        judul: 'Review Baru',
        pesan: `${namaReviewer} memberi Anda rating ${review.rating} bintang`,
        tipe: 'review_received',
        data: data
      });
    }
  } catch (error) {
    console.error('FCM push error:', error.message);
  }
}

// Notify when SkillCoin is received
async function notifySkillCoinReceived(nik, jumlah, namaPengirim) {
  const data = {
    jumlah: jumlah,
    nik_pengirim: namaPengirim
  };

  const message = `Anda menerima ${jumlah} SkillCoin dari ${namaPengirim}`;

  await createNotification(
    nik,
    'skillcoin_received',
    'SkillCoin Diterima',
    message,
    data
  );

  // Send push notification
  try {
    const user = await User.findByNik(nik);
    if (user && user.fcm_token) {
      await sendPushNotification(user.fcm_token, {
        judul: 'SkillCoin Diterima',
        pesan: message,
        tipe: 'skillcoin_received',
        data: data
      });
    }
  } catch (error) {
    console.error('FCM push error:', error.message);
  }
}

// Notify when SkillCoin is sent
async function notifySkillCoinSent(nik, jumlah, namaPenerima) {
  const data = {
    jumlah: jumlah,
    nik_penerima: namaPenerima
  };

  const message = `Anda mengirim ${jumlah} SkillCoin ke ${namaPenerima}`;

  await createNotification(
    nik,
    'skillcoin_sent',
    'SkillCoin Terkirim',
    message,
    data
  );

  // Send push notification
  try {
    const user = await User.findByNik(nik);
    if (user && user.fcm_token) {
      await sendPushNotification(user.fcm_token, {
        judul: 'SkillCoin Terkirim',
        pesan: message,
        tipe: 'skillcoin_sent',
        data: data
      });
    }
  } catch (error) {
    console.error('FCM push error:', error.message);
  }
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
