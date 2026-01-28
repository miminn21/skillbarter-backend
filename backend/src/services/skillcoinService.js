const db = require('../config/database');

/**
 * Skillcoin Service
 * Handles skillcoin balance and transactions
 */
class SkillcoinService {
  /**
   * Get user's skillcoin balance
   */
  static async getBalance(nik) {
    const query = 'SELECT saldo_skillcoin FROM pengguna WHERE nik = ?';
    const [rows] = await db.execute(query, [nik]);
    
    if (rows.length === 0) {
      throw new Error('User not found');
    }
    
    return rows[0].saldo_skillcoin;
  }

  /**
   * Get skillcoin transaction history
   */
  static async getHistory(nik, limit = 50) {
    const query = `
      SELECT 
        ts.*,
        p.nama_lengkap as nama_penerima,
        tb.kode_transaksi
      FROM transaksi_skillcoin ts
      LEFT JOIN pengguna p ON ts.penerima_nik = p.nik
      LEFT JOIN transaksi_barter tb ON ts.id_transaksi = tb.id
      WHERE ts.nik_pengguna = ?
      ORDER BY ts.dibuat_pada DESC
      LIMIT ?
    `;

    const [rows] = await db.execute(query, [nik, limit]);
    return rows;
  }

  /**
   * Add skillcoin using stored procedure
   */
  static async addSkillcoin(nik, amount, type, description) {
    try {
      await db.execute(
        'CALL tambah_skillcoin(?, ?, ?, ?)',
        [nik, amount, type, description]
      );
      
      return await this.getBalance(nik);
    } catch (error) {
      throw new Error(`Failed to add skillcoin: ${error.message}`);
    }
  }

  /**
   * Deduct skillcoin using stored procedure
   */
  static async deductSkillcoin(nik, amount, type, description) {
    try {
      await db.execute(
        'CALL kurangi_skillcoin(?, ?, ?, ?)',
        [nik, amount, type, description]
      );
      
      return await this.getBalance(nik);
    } catch (error) {
      throw new Error(`Failed to deduct skillcoin: ${error.message}`);
    }
  }

  /**
   * Transfer skillcoin using stored procedure
   */
  static async transferSkillcoin(fromNik, toNik, amount, barterId, description) {
    try {
      await db.execute(
        'CALL transfer_skillcoin(?, ?, ?, ?, ?)',
        [fromNik, toNik, amount, barterId, description]
      );
      
      return {
        senderBalance: await this.getBalance(fromNik),
        receiverBalance: await this.getBalance(toNik)
      };
    } catch (error) {
      throw new Error(`Failed to transfer skillcoin: ${error.message}`);
    }
  }

  /**
   * Process barter transaction skillcoin
   * Uses stored procedure proses_transaksi_barter
   */
  static async processBarterTransaction(transactionId) {
    try {
      await db.execute('CALL proses_transaksi_barter(?)', [transactionId]);
      return true;
    } catch (error) {
      throw new Error(`Failed to process barter transaction: ${error.message}`);
    }
  }

  /**
   * Calculate skillcoin for barter offer
   * CORRECTED LOGIC: Both users earn SkillCoin for teaching
   */
  static async calculateBarterSkillcoin(idKeahlianPenawar, idKeahlianDiminta, durasiJam) {
    console.log('[SkillcoinService] Calculating barter skillcoin...');
    console.log('[SkillcoinService] Penawar skill ID:', idKeahlianPenawar);
    console.log('[SkillcoinService] Diminta skill ID:', idKeahlianDiminta);
    console.log('[SkillcoinService] Duration:', durasiJam);
    
    const query = `
      SELECT 
        k1.harga_per_jam as harga_penawar,
        k1.nama_keahlian as skill_penawar,
        k2.harga_per_jam as harga_diminta,
        k2.nama_keahlian as skill_diminta
      FROM keahlian k1, keahlian k2
      WHERE k1.id = ? AND k2.id = ?
    `;

    const [rows] = await db.execute(query, [idKeahlianPenawar, idKeahlianDiminta]);
    
    console.log('[SkillcoinService] Query result:', rows);
    
    if (rows.length === 0) {
      console.error('[SkillcoinService] Skills not found!');
      console.error('[SkillcoinService] Penawar ID:', idKeahlianPenawar);
      console.error('[SkillcoinService] Diminta ID:', idKeahlianDiminta);
      throw new Error(`Skills not found (Penawar: ${idKeahlianPenawar}, Diminta: ${idKeahlianDiminta})`);
    }

    const { harga_penawar, skill_penawar, harga_diminta, skill_diminta } = rows[0];

    // Both users earn SkillCoin for teaching their skill
    const penawar_earns = durasiJam * harga_penawar;  // What penawar earns by teaching
    const penawar_pays = durasiJam * harga_diminta;   // What penawar pays for learning
    const penawar_net = penawar_earns - penawar_pays; // Net for penawar

    const diminta_earns = durasiJam * harga_diminta;  // What partner earns by teaching
    const diminta_pays = durasiJam * harga_penawar;   // What partner pays for learning
    const diminta_net = diminta_earns - diminta_pays; // Net for partner

    return {
      // Penawar (User A) calculations
      skill_penawar,
      harga_per_jam_penawar: harga_penawar,
      penawar_earns,        // What they earn
      penawar_pays,         // What they pay
      penawar_net,          // Net result
      
      // Diminta (User B / Partner) calculations
      skill_diminta,
      harga_per_jam_diminta: harga_diminta,
      diminta_earns,        // What they earn
      diminta_pays,         // What they pay
      diminta_net,          // Net result
      
      // Summary
      durasi_jam: durasiJam,
      total_transaction: penawar_earns + diminta_earns,
      
      // Legacy fields for backward compatibility
      skillcoin_penawar: penawar_earns,
      skillcoin_diminta: diminta_earns
    };
  }

  /**
   * Calculate cost for help request (no barter)
   */
  static async calculateHelpRequestCost(idKeahlianDiminta, durasiJam) {
    console.log('[SkillcoinService] Calculating help request cost...');
    console.log('[SkillcoinService] Skill ID:', idKeahlianDiminta);
    console.log('[SkillcoinService] Duration:', durasiJam);
    
    const query = `
      SELECT harga_per_jam, nama_keahlian
      FROM keahlian
      WHERE id = ?
    `;

    const [rows] = await db.execute(query, [idKeahlianDiminta]);
    
    console.log('[SkillcoinService] Query result:', rows);
    
    if (rows.length === 0) {
      console.error('[SkillcoinService] Skill not found! ID:', idKeahlianDiminta);
      throw new Error(`Skill with ID ${idKeahlianDiminta} not found`);
    }

    const { harga_per_jam, nama_keahlian } = rows[0];
    const total_cost = durasiJam * harga_per_jam;

    console.log('[SkillcoinService] Help request cost calculated:', total_cost);

    return {
      skill_diminta: nama_keahlian,
      harga_per_jam_diminta: harga_per_jam,
      total_cost,
      durasi_jam: durasiJam
    };
  }

  /**
   * Get skillcoin statistics for user
   */
  static async getStatistics(nik) {
    const query = `
      SELECT 
        COUNT(*) as total_transactions,
        SUM(CASE WHEN jumlah > 0 THEN jumlah ELSE 0 END) as total_earned,
        SUM(CASE WHEN jumlah < 0 THEN ABS(jumlah) ELSE 0 END) as total_spent,
        (SELECT saldo_skillcoin FROM pengguna WHERE nik = ?) as current_balance
      FROM transaksi_skillcoin
      WHERE nik_pengguna = ?
    `;

    const [rows] = await db.execute(query, [nik, nik]);
    return rows[0];
  }

  /**
   * Check if user has sufficient balance
   */
  static async hasSufficientBalance(nik, amount) {
    const balance = await this.getBalance(nik);
    return balance >= amount;
  }
}

module.exports = SkillcoinService;
