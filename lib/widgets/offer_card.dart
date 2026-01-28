import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/barter_offer.dart';

class OfferCard extends StatelessWidget {
  final BarterOffer offer;
  final VoidCallback onTap;
  final bool showActions;

  const OfferCard({
    Key? key,
    required this.offer,
    required this.onTap,
    this.showActions = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with partner info and status
              Row(
                children: [
                  // Partner avatar
                  CircleAvatar(
                    radius: 24,
                    backgroundImage: offer.fotoPartner != null
                        ? MemoryImage(base64Decode(offer.fotoPartner!))
                        : null,
                    child: offer.fotoPartner == null
                        ? Text(offer.namaPartner?[0].toUpperCase() ?? 'U')
                        : null,
                  ),
                  const SizedBox(width: 12),

                  // Partner name and role
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          offer.tipeTransaksi == 'request'
                              ? '(Menunggu Partner)'
                              : (offer.namaPartner ?? 'Unknown'),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: offer.tipeTransaksi == 'request'
                                ? Colors.grey
                                : Colors.black,
                            fontStyle: offer.tipeTransaksi == 'request'
                                ? FontStyle.italic
                                : FontStyle.normal,
                          ),
                        ),
                        Text(
                          offer.tipeTransaksi == 'request'
                              ? 'Minta Bantuan'
                              : (offer.role == 'sent'
                                    ? 'Penawaran Terkirim'
                                    : 'Penawaran Diterima'),
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Status badge
                  _buildStatusBadge(),
                ],
              ),
              const SizedBox(height: 12),

              // Transaction code
              if (offer.kodeTransaksi != null)
                Text(
                  offer.kodeTransaksi!,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                    fontFamily: 'monospace',
                  ),
                ),
              const SizedBox(height: 8),

              // Skills exchange
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Anda Tawarkan',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            offer.skillOwn ?? '-',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.swap_horiz, color: Colors.blue),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'Anda Minta',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            offer.skillPartner ?? '-',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                            textAlign: TextAlign.right,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Schedule and duration
              Row(
                children: [
                  Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    '${offer.durasiJam} jam',
                    style: TextStyle(color: Colors.grey[700], fontSize: 13),
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    DateFormat(
                      'dd MMM yyyy, HH:mm',
                    ).format(offer.tanggalPelaksanaan),
                    style: TextStyle(color: Colors.grey[700], fontSize: 13),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Location
              Row(
                children: [
                  Icon(
                    Icons.location_on_outlined,
                    size: 16,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    offer.tipeLokasi == 'online'
                        ? 'Online'
                        : offer.detailLokasi ?? 'Offline',
                    style: TextStyle(color: Colors.grey[700], fontSize: 13),
                  ),
                ],
              ),

              // Skillcoin info
              if (offer.hargaPenawar != null && offer.hargaDiminta != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.amber.shade200),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.monetization_on,
                            size: 16,
                            color: Colors.amber.shade700,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Anda: ${offer.skillcoinPenawar} coin',
                            style: TextStyle(
                              color: Colors.amber.shade900,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        'Partner: ${offer.skillcoinDiminta} coin',
                        style: TextStyle(
                          color: Colors.amber.shade900,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge() {
    Color backgroundColor;
    Color textColor;
    IconData icon;

    switch (offer.status) {
      case 'menunggu':
        backgroundColor = Colors.orange.shade100;
        textColor = Colors.orange.shade900;
        icon = Icons.schedule;
        break;
      case 'diterima':
        backgroundColor = Colors.blue.shade100;
        textColor = Colors.blue.shade900;
        icon = Icons.check_circle_outline;
        break;
      case 'ditolak':
        backgroundColor = Colors.red.shade100;
        textColor = Colors.red.shade900;
        icon = Icons.cancel_outlined;
        break;
      case 'berlangsung':
        backgroundColor = Colors.purple.shade100;
        textColor = Colors.purple.shade900;
        icon = Icons.play_circle_outline;
        break;
      case 'selesai':
        backgroundColor = Colors.teal.shade100;
        textColor = Colors.teal.shade900;
        icon = Icons.done_outline;
        break;
      case 'terkonfirmasi':
        backgroundColor = Colors.green.shade100;
        textColor = Colors.green.shade900;
        icon = Icons.verified_outlined;
        break;
      case 'dibatalkan':
        backgroundColor = Colors.grey.shade300;
        textColor = Colors.grey.shade800;
        icon = Icons.block;
        break;
      default:
        backgroundColor = Colors.grey.shade200;
        textColor = Colors.grey.shade700;
        icon = Icons.info_outline;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: textColor),
          const SizedBox(width: 4),
          Text(
            offer.statusText,
            style: TextStyle(
              color: textColor,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
