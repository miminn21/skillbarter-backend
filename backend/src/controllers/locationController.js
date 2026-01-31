const db = require('../config/database');
const { success, error } = require('../utils/response');

exports.updateLocation = async (req, res) => {
    try {
        const { latitude, longitude } = req.body;
        const nik = req.user.nik;

        if (!latitude || !longitude) {
            return error(res, 'Latitude and Longitude are required', 400);
        }

        await db.execute(
            'UPDATE pengguna SET latitude = ?, longitude = ?, last_location_update = NOW() WHERE nik = ?',
            [latitude, longitude, nik]
        );

        return success(res, 'Location updated successfully');
    } catch (e) {
        console.error('Update Location Error:', e);
        return error(res, 'Internal Server Error');
    }
};

exports.getNearbyUsers = async (req, res) => {
    try {
        const { latitude, longitude, radius = 10000 } = req.query; // Radius in km (Expanded to 10000)
        const nik = req.user.nik;

        if (!latitude || !longitude) {
            return error(res, 'Latitude and Longitude are required', 400);
        }

        // Haversine Formula
        // 6371 is Earth radius in km
        const query = `
            SELECT 
                nik, 
                nama_lengkap, 
                nama_panggilan,
                foto_profil,
                latitude, 
                longitude,
                (6371 * acos(
                    cos(radians(?)) * 
                    cos(radians(latitude)) * 
                    cos(radians(longitude) - radians(?)) + 
                    sin(radians(?)) * 
                    sin(radians(latitude))
                )) AS distance
            FROM pengguna
            WHERE latitude IS NOT NULL 
              AND longitude IS NOT NULL
              AND nik != ?
            HAVING distance < ?
            ORDER BY distance ASC
            LIMIT 200
        `;

        const [rows] = await db.execute(query, [latitude, longitude, latitude, nik, radius]);

        return success(res, 'Nearby users fetched', rows);
    } catch (e) {
        console.error('Get Nearby Error:', e);
        return error(res, 'Internal Server Error');
    }
};
