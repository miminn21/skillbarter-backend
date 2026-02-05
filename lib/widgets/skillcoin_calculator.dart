import 'package:flutter/material.dart';

class SkillcoinCalculator extends StatelessWidget {
  final int durasiJam;
  final int hargaPerJamAnda;
  final int hargaPerJamPartner;
  final String skillAnda;
  final String skillPartner;

  const SkillcoinCalculator({
    Key? key,
    required this.durasiJam,
    required this.hargaPerJamAnda,
    required this.hargaPerJamPartner,
    required this.skillAnda,
    required this.skillPartner,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final skillcoinAnda = durasiJam * hargaPerJamAnda;
    final skillcoinPartner = durasiJam * hargaPerJamPartner;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Card(
      elevation: 2,
      color: theme.cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Row(
              children: [
                Icon(Icons.calculate, color: Colors.orange),
                const SizedBox(width: 8),
                Text(
                  'Perhitungan Skillcoin',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Your earnings
            _buildCalculationRow(
              label: 'Anda Mengajarkan',
              skill: skillAnda,
              duration: durasiJam,
              pricePerHour: hargaPerJamAnda,
              total: skillcoinAnda,
              color: isDark ? Colors.greenAccent : Colors.green,
              isIncome: true,
              isDark: isDark,
            ),
            const SizedBox(height: 12),

            // Partner earnings
            _buildCalculationRow(
              label: 'Partner Mengajarkan',
              skill: skillPartner,
              duration: durasiJam,
              pricePerHour: hargaPerJamPartner,
              total: skillcoinPartner,
              color: Colors.blue,
              isIncome: false,
              isDark: isDark,
            ),
            const SizedBox(height: 16),

            // Summary
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.orange.withOpacity(0.1)
                    : Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isDark
                      ? Colors.orange.withOpacity(0.3)
                      : Colors.orange.shade200,
                ),
              ),
              child: Column(
                children: [
                  Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        'Anda Akan Terima: ',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white70 : Colors.black87,
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.monetization_on,
                            size: 20,
                            color: Colors.orange,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '$skillcoinAnda Skillcoin',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: isDark
                                  ? Colors.orangeAccent
                                  : Colors.orange.shade900,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        'Partner Akan Terima: ',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white70 : Colors.black87,
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.monetization_on,
                            size: 20,
                            color: Colors.orange,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '$skillcoinPartner Skillcoin',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: isDark
                                  ? Colors.orangeAccent
                                  : Colors.orange.shade900,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Info
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.blue.withOpacity(0.1)
                    : Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 16,
                    color: isDark ? Colors.blueAccent : Colors.blue.shade700,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Skillcoin akan ditransfer setelah kedua pihak mengkonfirmasi penyelesaian barter',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark
                            ? Colors.blue.shade100
                            : Colors.blue.shade900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalculationRow({
    required String label,
    required String skill,
    required int duration,
    required int pricePerHour,
    required int total,
    required Color color,
    required bool isIncome,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(isDark ? 0.05 : 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(isDark ? 0.2 : 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.grey[400] : Colors.grey[700],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            skill,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  '$duration jam × $pricePerHour coin/jam',
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.grey[400] : Colors.grey[700],
                  ),
                ),
              ),
              Row(
                children: [
                  Icon(
                    isIncome ? Icons.add_circle : Icons.info_outline,
                    size: 16,
                    color: color,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '$total coin',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
