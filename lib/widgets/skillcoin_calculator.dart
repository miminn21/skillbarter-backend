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

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Row(
              children: [
                Icon(Icons.calculate, color: Colors.amber.shade700),
                const SizedBox(width: 8),
                const Text(
                  'Perhitungan Skillcoin',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
              color: Colors.green,
              isIncome: true,
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
            ),
            const SizedBox(height: 16),

            // Summary
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber.shade200),
              ),
              child: Column(
                children: [
                  Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      const Text(
                        'Anda Akan Terima: ',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.monetization_on,
                            size: 20,
                            color: Colors.amber.shade700,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '$skillcoinAnda Skillcoin',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.amber.shade900,
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
                      const Text(
                        'Partner Akan Terima: ',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.monetization_on,
                            size: 20,
                            color: Colors.amber.shade700,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '$skillcoinPartner Skillcoin',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.amber.shade900,
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
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 16,
                    color: Colors.blue.shade700,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Skillcoin akan ditransfer setelah kedua pihak mengkonfirmasi penyelesaian barter',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue.shade900,
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
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[700],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            skill,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  '$duration jam × $pricePerHour coin/jam',
                  style: TextStyle(fontSize: 13, color: Colors.grey[700]),
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
