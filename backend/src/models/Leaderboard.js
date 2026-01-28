const db = require('../config/database');

class Leaderboard {
  /**
   * Get top users by skillcoin balance
   * Uses database view: peringkat_skillcoin
   */
  static async getTopUsers(limit = 50) {
    const query = `
      SELECT 
        peringkat,
        nik,
        nama_panggilan,
        foto_profil,
        saldo_skillcoin,
        total_jam_berkontribusi,
        rating_rata_rata
      FROM peringkat_skillcoin
      ORDER BY peringkat ASC
      LIMIT ?
    `;

    const [users] = await db.query(query, [parseInt(limit)]);
    
    // Convert BLOB to base64 for each user
    return users.map(user => {
      if (user.foto_profil) {
        user.foto_profil = user.foto_profil.toString('base64');
      }
      return user;
    });
  }

  /**
   * Get user's rank
   */
  static async getUserRank(nik) {
    const query = `
      SELECT 
        peringkat,
        nik,
        nama_panggilan,
        foto_profil,
        saldo_skillcoin,
        total_jam_berkontribusi,
        rating_rata_rata
      FROM peringkat_skillcoin
      WHERE nik = ?
    `;

    const [users] = await db.query(query, [nik]);
    
    if (users.length > 0) {
      const user = users[0];
      // Convert BLOB to base64
      if (user.foto_profil) {
        user.foto_profil = user.foto_profil.toString('base64');
      }
      return user;
    }
    
    return null;
  }

  /**
   * Get leaderboard with current user's position
   */
  static async getLeaderboardWithUser(nik, limit = 50) {
    const leaderboard = await this.getTopUsers(limit);
    const currentUserRank = await this.getUserRank(nik);

    return {
      leaderboard,
      currentUserRank
    };
  }
}

module.exports = Leaderboard;
