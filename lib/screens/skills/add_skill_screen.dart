import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/skill_provider.dart';
import '../../models/category_model.dart';
import '../../widgets/custom_notification.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class AddSkillScreen extends StatefulWidget {
  final String? initialTipe;

  const AddSkillScreen({super.key, this.initialTipe});

  @override
  State<AddSkillScreen> createState() => _AddSkillScreenState();
}

class _AddSkillScreenState extends State<AddSkillScreen> {
  final _formKey = GlobalKey<FormState>();
  final _namaController = TextEditingController();
  final _pengalamanController = TextEditingController();
  final _deskripsiController = TextEditingController();
  final _hargaController = TextEditingController();
  final _linkController = TextEditingController();

  XFile? _skillImage;
  CategoryModel? _selectedCategory;
  String _tipe = 'dikuasai';
  String _tingkat = 'menengah';
  DateTime? _expiryDate;

  @override
  void initState() {
    super.initState();
    if (widget.initialTipe != null) {
      _tipe = widget.initialTipe!;
    }
    _hargaController.text = '1';

    // Load categories
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SkillProvider>().loadCategories();
    });
  }

  @override
  void dispose() {
    _namaController.dispose();
    _pengalamanController.dispose();
    _deskripsiController.dispose();
    _hargaController.dispose();
    _linkController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategory == null) {
      CustomNotification.showWarning(
        context,
        'Silakan pilih kategori terlebih dahulu',
      );
      return;
    }

    final skillProvider = context.read<SkillProvider>();

    final skillData = {
      'nama_keahlian': _namaController.text.trim(),
      'id_kategori': _selectedCategory!.id,
      'tipe': _tipe,
      'tingkat': _tingkat,
      'pengalaman': _pengalamanController.text.trim().isEmpty
          ? null
          : _pengalamanController.text.trim(),
      'deskripsi': _deskripsiController.text.trim().isEmpty
          ? null
          : _deskripsiController.text.trim(),
      'harga_per_jam': int.parse(_hargaController.text),
      'link_portofolio': _linkController.text.trim().isEmpty
          ? null
          : _linkController.text.trim(),
    };

    // Add tanggal_berakhir for dicari type
    if (_tipe == 'dicari') {
      if (_expiryDate != null) {
        skillData['tanggal_berakhir'] = _expiryDate!.toIso8601String().split(
          'T',
        )[0];
      }
    }

    print('[AddSkill] Submitting skill data: $skillData');
    print('[AddSkill] Tipe: $_tipe, Expiry Date: $_expiryDate');
    print('[AddSkill] Image: ${_skillImage?.path}');

    final success = await skillProvider.addSkill(
      skillData,
      imageFile: _skillImage,
    );

    if (!mounted) return;

    if (success) {
      CustomNotification.showSuccess(context, '✨ Skill berhasil ditambahkan!');
      Navigator.pop(context, true);
    } else {
      print('[AddSkill] Error: ${skillProvider.error}');
      CustomNotification.showError(
        context,
        skillProvider.error ?? 'Gagal menambahkan skill',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tambah Skill')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Image Picker
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 180,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                  image: _skillImage != null
                      ? DecorationImage(
                          image: kIsWeb
                              ? NetworkImage(_skillImage!.path)
                              : FileImage(File(_skillImage!.path))
                                    as ImageProvider,
                          fit: BoxFit.contain,
                          alignment: Alignment.center,
                        )
                      : null,
                  border: Border.all(color: Colors.grey[400]!),
                ),
                child: _skillImage == null
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.add_photo_alternate,
                            size: 50,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Upload Foto Keahlian',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      )
                    : Stack(
                        children: [
                          Positioned(
                            top: 8,
                            right: 8,
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _skillImage = null;
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.close,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 16),

            // Nama Keahlian
            TextFormField(
              controller: _namaController,
              decoration: const InputDecoration(
                labelText: 'Nama Keahlian *',
                hintText: 'Contoh: Web Development',
                prefixIcon: Icon(Icons.star),
              ),
              textCapitalization: TextCapitalization.words,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Nama keahlian wajib diisi';
                }
                if (value.length < 3) {
                  return 'Nama minimal 3 karakter';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Kategori
            Consumer<SkillProvider>(
              builder: (context, skillProvider, _) {
                return DropdownButtonFormField<CategoryModel>(
                  value: _selectedCategory,
                  decoration: const InputDecoration(
                    labelText: 'Kategori *',
                    prefixIcon: Icon(Icons.category),
                  ),
                  items: skillProvider.categories.map((category) {
                    return DropdownMenuItem(
                      value: category,
                      child: Text(category.namaKategori),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedCategory = value;
                    });
                  },
                  validator: (value) {
                    if (value == null) {
                      return 'Kategori wajib dipilih';
                    }
                    return null;
                  },
                );
              },
            ),
            const SizedBox(height: 16),

            // Tipe
            DropdownButtonFormField<String>(
              value: _tipe,
              decoration: const InputDecoration(
                labelText: 'Tipe *',
                prefixIcon: Icon(Icons.swap_horiz),
              ),
              items: const [
                DropdownMenuItem(value: 'dikuasai', child: Text('Dikuasai')),
                DropdownMenuItem(value: 'dicari', child: Text('Dicari')),
              ],
              onChanged: (value) {
                setState(() {
                  _tipe = value!;
                });
              },
            ),
            const SizedBox(height: 16),

            // Tingkat
            DropdownButtonFormField<String>(
              value: _tingkat,
              decoration: const InputDecoration(
                labelText: 'Tingkat',
                prefixIcon: Icon(Icons.trending_up),
              ),
              items: const [
                DropdownMenuItem(value: 'pemula', child: Text('Pemula')),
                DropdownMenuItem(value: 'menengah', child: Text('Menengah')),
                DropdownMenuItem(value: 'mahir', child: Text('Mahir')),
                DropdownMenuItem(value: 'ahli', child: Text('Ahli')),
              ],
              onChanged: (value) {
                setState(() {
                  _tingkat = value!;
                });
              },
            ),
            const SizedBox(height: 16),

            // Pengalaman
            TextFormField(
              controller: _pengalamanController,
              decoration: const InputDecoration(
                labelText: 'Pengalaman (Opsional)',
                hintText: 'Contoh: 5 tahun',
                prefixIcon: Icon(Icons.work),
              ),
              maxLength: 50,
            ),
            const SizedBox(height: 16),

            // Deskripsi
            TextFormField(
              controller: _deskripsiController,
              decoration: const InputDecoration(
                labelText: 'Deskripsi (Opsional)',
                hintText: 'Jelaskan tentang keahlian Anda...',
                prefixIcon: Icon(Icons.description),
              ),
              maxLines: 4,
              maxLength: 1000,
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 16),

            // Tanggal Berakhir (only for dicari)
            if (_tipe == 'dicari') ...[
              InkWell(
                onTap: () => _selectExpiryDate(context),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Tanggal Berakhir (Opsional)',
                    hintText: 'Pilih tanggal berakhir',
                    prefixIcon: Icon(Icons.event),
                    border: OutlineInputBorder(),
                  ),
                  child: Text(
                    _expiryDate != null
                        ? DateFormat('dd MMM yyyy').format(_expiryDate!)
                        : 'Tidak ada batas waktu',
                    style: TextStyle(
                      color: _expiryDate != null ? null : Colors.grey[600],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Harga per Jam
            TextFormField(
              controller: _hargaController,
              decoration: const InputDecoration(
                labelText: 'Harga per Jam (SkillCoin)',
                prefixIcon: Icon(Icons.monetization_on),
                suffix: Text('SC'),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Harga wajib diisi';
                }
                final harga = int.tryParse(value);
                if (harga == null || harga < 1) {
                  return 'Harga minimal 1 SkillCoin';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Link Portfolio
            TextFormField(
              controller: _linkController,
              decoration: const InputDecoration(
                labelText: 'Link Portfolio (Opsional)',
                hintText: 'https://...',
                prefixIcon: Icon(Icons.link),
              ),
              keyboardType: TextInputType.url,
            ),
            const SizedBox(height: 32),

            // Submit Button
            Consumer<SkillProvider>(
              builder: (context, skillProvider, _) {
                return ElevatedButton(
                  onPressed: skillProvider.isLoading ? null : _handleSubmit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: skillProvider.isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Tambah Skill',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectExpiryDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now().add(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      helpText: 'Pilih Tanggal Berakhir',
      cancelText: 'Batal',
      confirmText: 'Pilih',
    );

    if (picked != null) {
      setState(() {
        _expiryDate = picked;
      });
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );

    if (pickedFile != null) {
      setState(() {
        _skillImage = pickedFile;
      });
    }
  }
}
