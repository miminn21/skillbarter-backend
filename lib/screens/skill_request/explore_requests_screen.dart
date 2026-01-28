import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/skill_request_provider.dart';
import '../../providers/category_provider.dart';
import '../../models/skill_request.dart';
import '../barter/create_offer_screen.dart';

class ExploreRequestsScreen extends StatefulWidget {
  const ExploreRequestsScreen({Key? key}) : super(key: key);

  @override
  State<ExploreRequestsScreen> createState() => _ExploreRequestsScreenState();
}

class _ExploreRequestsScreenState extends State<ExploreRequestsScreen> {
  int? _selectedCategory;
  String? _selectedLevel;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CategoryProvider>().fetchCategories();
      _loadRequests();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _loadRequests() {
    context.read<SkillRequestProvider>().fetchExploreRequests(
      kategori: _selectedCategory,
      tingkat: _selectedLevel,
      lokasi: _searchController.text.trim().isEmpty
          ? null
          : _searchController.text.trim(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Explore Skill Requests'), elevation: 0),
      body: Column(
        children: [
          // Search and Filters
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[50],
            child: Column(
              children: [
                // Search Bar
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Cari berdasarkan lokasi...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              _loadRequests();
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  onSubmitted: (_) => _loadRequests(),
                ),
                const SizedBox(height: 12),

                // Category Filter
                Consumer<CategoryProvider>(
                  builder: (context, categoryProvider, child) {
                    if (categoryProvider.categories.isEmpty) {
                      return const SizedBox.shrink();
                    }

                    return SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          FilterChip(
                            label: const Text('Semua'),
                            selected: _selectedCategory == null,
                            onSelected: (selected) {
                              setState(() {
                                _selectedCategory = null;
                              });
                              _loadRequests();
                            },
                          ),
                          const SizedBox(width: 8),
                          ...categoryProvider.categories.map((category) {
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: FilterChip(
                                label: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(category.ikon ?? '📚'),
                                    const SizedBox(width: 4),
                                    Text(category.namaKategori),
                                  ],
                                ),
                                selected: _selectedCategory == category.id,
                                onSelected: (selected) {
                                  setState(() {
                                    _selectedCategory = selected
                                        ? category.id
                                        : null;
                                  });
                                  _loadRequests();
                                },
                              ),
                            );
                          }).toList(),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 8),

                // Level Filter
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      const Text('Level: '),
                      const SizedBox(width: 8),
                      FilterChip(
                        label: const Text('Semua'),
                        selected: _selectedLevel == null,
                        onSelected: (selected) {
                          setState(() {
                            _selectedLevel = null;
                          });
                          _loadRequests();
                        },
                      ),
                      const SizedBox(width: 8),
                      FilterChip(
                        label: const Text('Pemula'),
                        selected: _selectedLevel == 'pemula',
                        onSelected: (selected) {
                          setState(() {
                            _selectedLevel = selected ? 'pemula' : null;
                          });
                          _loadRequests();
                        },
                      ),
                      const SizedBox(width: 8),
                      FilterChip(
                        label: const Text('Menengah'),
                        selected: _selectedLevel == 'menengah',
                        onSelected: (selected) {
                          setState(() {
                            _selectedLevel = selected ? 'menengah' : null;
                          });
                          _loadRequests();
                        },
                      ),
                      const SizedBox(width: 8),
                      FilterChip(
                        label: const Text('Mahir'),
                        selected: _selectedLevel == 'mahir',
                        onSelected: (selected) {
                          setState(() {
                            _selectedLevel = selected ? 'mahir' : null;
                          });
                          _loadRequests();
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Requests List
          Expanded(
            child: Consumer<SkillRequestProvider>(
              builder: (context, provider, child) {
                if (provider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (provider.error != null) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 64,
                          color: Colors.red,
                        ),
                        const SizedBox(height: 16),
                        Text(provider.error!),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadRequests,
                          child: const Text('Coba Lagi'),
                        ),
                      ],
                    ),
                  );
                }

                if (provider.exploreRequests.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off,
                          size: 80,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Tidak ada request ditemukan',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Coba ubah filter atau kata kunci pencarian',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async => _loadRequests(),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: provider.exploreRequests.length,
                    itemBuilder: (context, index) {
                      final request = provider.exploreRequests[index];
                      return _buildRequestCard(request);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRequestCard(SkillRequest request) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _showRequestDetail(request),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with user info
              Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundImage: request.fotoProfil != null
                        ? MemoryImage(base64Decode(request.fotoProfil!))
                        : null,
                    child: request.fotoProfil == null
                        ? Text(request.namaPemohon?[0].toUpperCase() ?? 'U')
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          request.namaPemohon ?? 'Unknown',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        if (request.trustScore != null)
                          Row(
                            children: [
                              const Icon(
                                Icons.star,
                                size: 14,
                                color: Colors.amber,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                request.trustScore!.toStringAsFixed(1),
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                  // Category Icon
                  if (request.kategoriIkon != null)
                    Text(
                      request.kategoriIkon!,
                      style: const TextStyle(fontSize: 24),
                    ),
                ],
              ),
              const SizedBox(height: 12),

              // Skill Name
              Text(
                request.namaKeahlian,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),

              // Description
              if (request.deskripsiKebutuhan != null)
                Text(
                  request.deskripsiKebutuhan!,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Colors.grey[700]),
                ),
              const SizedBox(height: 12),

              // Tags
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildTag(
                    Icons.trending_up,
                    request.tingkatKeahlianDiinginkan.toUpperCase(),
                    Colors.blue,
                  ),
                  if (request.durasiEstimasi != null)
                    _buildTag(
                      Icons.access_time,
                      request.durasiEstimasi!,
                      Colors.orange,
                    ),
                  if (request.lokasiPreferensi != null)
                    _buildTag(
                      Icons.location_on_outlined,
                      request.lokasiPreferensi!,
                      Colors.green,
                    ),
                ],
              ),
              const SizedBox(height: 12),

              // Action Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _sendOffer(request),
                  icon: const Icon(Icons.send, size: 18),
                  label: const Text('Kirim Penawaran'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTag(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  void _showRequestDetail(SkillRequest request) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          return SingleChildScrollView(
            controller: scrollController,
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // User Info
                Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundImage: request.fotoProfil != null
                          ? MemoryImage(base64Decode(request.fotoProfil!))
                          : null,
                      child: request.fotoProfil == null
                          ? Text(request.namaPemohon?[0].toUpperCase() ?? 'U')
                          : null,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            request.namaPemohon ?? 'Unknown',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (request.trustScore != null)
                            Row(
                              children: [
                                const Icon(
                                  Icons.star,
                                  size: 16,
                                  color: Colors.amber,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${request.trustScore!.toStringAsFixed(1)} Trust Score',
                                  style: TextStyle(color: Colors.grey[600]),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Skill Name
                Text(
                  request.namaKeahlian,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  request.namaKategori ?? '',
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),
                const SizedBox(height: 16),

                // Description
                if (request.deskripsiKebutuhan != null) ...[
                  const Text(
                    'Deskripsi Kebutuhan',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(request.deskripsiKebutuhan!),
                  const SizedBox(height: 16),
                ],

                // Details
                const Text(
                  'Detail',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                _buildDetailRow(
                  'Tingkat Keahlian',
                  request.tingkatKeahlianDiinginkan.toUpperCase(),
                ),
                if (request.durasiEstimasi != null)
                  _buildDetailRow('Durasi Estimasi', request.durasiEstimasi!),
                if (request.lokasiPreferensi != null)
                  _buildDetailRow(
                    'Lokasi Preferensi',
                    request.lokasiPreferensi!,
                  ),
                if (request.catatanTambahan != null) ...[
                  const SizedBox(height: 16),
                  const Text(
                    'Catatan Tambahan',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(request.catatanTambahan!),
                ],
                const SizedBox(height: 32),

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Tutup'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _sendOffer(request);
                        },
                        child: const Text('Kirim Penawaran'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  void _sendOffer(SkillRequest request) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateOfferScreen(
          targetNik: request.nikPengguna,
          targetSkillName: request.namaKeahlian,
          skillRequestId: request.id,
          suggestedDuration: request.durasiEstimasi != null
              ? int.tryParse(request.durasiEstimasi!.split(' ').first)
              : null,
          suggestedLocation: request.lokasiPreferensi,
          // Note: targetSkillId, ownSkillId, and ownSkillName
          // should come from user's skills selection
        ),
      ),
    );
  }
}
