import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/skill_request_provider.dart';
import '../../providers/category_provider.dart';
import '../../models/skill_request.dart';
import '../../models/category.dart';

class SkillRequestScreen extends StatefulWidget {
  const SkillRequestScreen({Key? key}) : super(key: key);

  @override
  State<SkillRequestScreen> createState() => _SkillRequestScreenState();
}

class _SkillRequestScreenState extends State<SkillRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _namaKeahlianController = TextEditingController();
  final _deskripsiController = TextEditingController();
  final _durasiController = TextEditingController();
  final _lokasiController = TextEditingController();
  final _catatanController = TextEditingController();

  Category? _selectedCategory;
  String _tingkatKeahlian = 'menengah';

  @override
  void initState() {
    super.initState();
    // Load categories
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CategoryProvider>().fetchCategories();
    });
  }

  @override
  void dispose() {
    _namaKeahlianController.dispose();
    _deskripsiController.dispose();
    _durasiController.dispose();
    _lokasiController.dispose();
    _catatanController.dispose();
    super.dispose();
  }

  Future<void> _submitRequest() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategory == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Pilih kategori skill')));
      return;
    }

    final request = SkillRequest(
      nikPengguna: '', // Will be set by backend
      idKategori: _selectedCategory!.id,
      namaKeahlian: _namaKeahlianController.text.trim(),
      deskripsiKebutuhan: _deskripsiController.text.trim(),
      tingkatKeahlianDiinginkan: _tingkatKeahlian,
      durasiEstimasi: _durasiController.text.trim(),
      lokasiPreferensi: _lokasiController.text.trim(),
      catatanTambahan: _catatanController.text.trim(),
    );

    final provider = context.read<SkillRequestProvider>();
    final success = await provider.createRequest(request);

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Skill request berhasil dibuat!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.error ?? 'Gagal membuat request'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Buat Skill Request'), elevation: 0),
      body: Consumer2<CategoryProvider, SkillRequestProvider>(
        builder: (context, categoryProvider, requestProvider, child) {
          if (categoryProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Header
                const Text(
                  'Ceritakan skill apa yang Anda butuhkan',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Kami akan mencarikan orang yang tepat untuk membantu Anda',
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),
                const SizedBox(height: 24),

                // Category Selection
                const Text(
                  'Kategori Skill *',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: categoryProvider.categories.map((category) {
                    final isSelected = _selectedCategory?.id == category.id;
                    return ChoiceChip(
                      label: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(category.ikon ?? '📚'),
                          const SizedBox(width: 4),
                          Text(category.namaKategori),
                        ],
                      ),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          _selectedCategory = selected ? category : null;
                        });
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),

                // Skill Name
                TextFormField(
                  controller: _namaKeahlianController,
                  decoration: const InputDecoration(
                    labelText: 'Nama Skill *',
                    hintText: 'Contoh: Web Development, Graphic Design',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.lightbulb_outline),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Nama skill harus diisi';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Description
                TextFormField(
                  controller: _deskripsiController,
                  decoration: const InputDecoration(
                    labelText: 'Deskripsi Kebutuhan *',
                    hintText: 'Jelaskan apa yang Anda butuhkan...',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.description_outlined),
                  ),
                  maxLines: 4,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Deskripsi harus diisi';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Skill Level
                const Text(
                  'Tingkat Keahlian yang Diinginkan',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                ),
                const SizedBox(height: 8),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(
                      value: 'pemula',
                      label: Text('Pemula'),
                      icon: Icon(Icons.star_outline),
                    ),
                    ButtonSegment(
                      value: 'menengah',
                      label: Text('Menengah'),
                      icon: Icon(Icons.star_half),
                    ),
                    ButtonSegment(
                      value: 'mahir',
                      label: Text('Mahir'),
                      icon: Icon(Icons.star),
                    ),
                  ],
                  selected: {_tingkatKeahlian},
                  onSelectionChanged: (Set<String> newSelection) {
                    setState(() {
                      _tingkatKeahlian = newSelection.first;
                    });
                  },
                ),
                const SizedBox(height: 16),

                // Duration
                TextFormField(
                  controller: _durasiController,
                  decoration: const InputDecoration(
                    labelText: 'Estimasi Durasi',
                    hintText: 'Contoh: 2 minggu, 1 bulan',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.access_time),
                  ),
                ),
                const SizedBox(height: 16),

                // Location
                TextFormField(
                  controller: _lokasiController,
                  decoration: const InputDecoration(
                    labelText: 'Lokasi Preferensi',
                    hintText: 'Contoh: Jakarta, Online',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.location_on_outlined),
                  ),
                ),
                const SizedBox(height: 16),

                // Additional Notes
                TextFormField(
                  controller: _catatanController,
                  decoration: const InputDecoration(
                    labelText: 'Catatan Tambahan',
                    hintText: 'Informasi tambahan yang perlu diketahui...',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.note_outlined),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 32),

                // Submit Button
                ElevatedButton(
                  onPressed: requestProvider.isLoading ? null : _submitRequest,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: requestProvider.isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text(
                          'Buat Request',
                          style: TextStyle(fontSize: 16),
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
