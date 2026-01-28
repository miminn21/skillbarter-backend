import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/skill_provider.dart';
import '../../models/skill_model.dart';
import '../../models/category_model.dart';
import '../../widgets/custom_notification.dart';
import 'dart:io';
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class EditSkillScreen extends StatefulWidget {
  final SkillModel skill;

  const EditSkillScreen({super.key, required this.skill});

  @override
  State<EditSkillScreen> createState() => _EditSkillScreenState();
}

class _EditSkillScreenState extends State<EditSkillScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _namaController;
  late TextEditingController _pengalamanController;
  late TextEditingController _deskripsiController;
  late TextEditingController _hargaController;
  late TextEditingController _linkController;

  CategoryModel? _selectedCategory;
  late String _tingkat;
  XFile? _newImage;

  @override
  void initState() {
    super.initState();
    _namaController = TextEditingController(text: widget.skill.namaKeahlian);
    _pengalamanController = TextEditingController(
      text: widget.skill.pengalaman,
    );
    _deskripsiController = TextEditingController(text: widget.skill.deskripsi);
    _hargaController = TextEditingController(
      text: widget.skill.hargaPerJam.toString(),
    );
    _linkController = TextEditingController(text: widget.skill.linkPortofolio);
    _tingkat = widget.skill.tingkat;

    // Load categories and set selected
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final skillProvider = context.read<SkillProvider>();
      if (skillProvider.categories.isNotEmpty) {
        setState(() {
          _selectedCategory = skillProvider.categories.firstWhere(
            (cat) => cat.id == widget.skill.idKategori,
            orElse: () => skillProvider.categories.first,
          );
        });
      }
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
        '⚠️ Silakan pilih kategori terlebih dahulu',
      );
      return;
    }

    final skillProvider = context.read<SkillProvider>();

    final skillData = {
      'nama_keahlian': _namaController.text.trim(),
      'id_kategori': _selectedCategory!.id,
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

    final success = await skillProvider.updateSkill(
      widget.skill.id,
      skillData,
      imageFile: _newImage,
    );

    if (!mounted) return;

    if (success) {
      CustomNotification.showSuccess(context, '✅ Skill berhasil diperbarui!');
      Navigator.pop(context, true);
    } else {
      CustomNotification.showError(
        context,
        skillProvider.error ?? '❌ Gagal memperbarui skill',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Skill')),
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
                  image: _newImage != null
                      ? DecorationImage(
                          image: kIsWeb
                              ? NetworkImage(_newImage!.path)
                              : FileImage(File(_newImage!.path))
                                    as ImageProvider,
                          fit: BoxFit.contain,
                          alignment: Alignment.center,
                        )
                      : (widget.skill.gambarSkill != null &&
                            widget.skill.gambarSkill!.isNotEmpty)
                      ? DecorationImage(
                          image: MemoryImage(
                            base64Decode(widget.skill.gambarSkill!),
                          ),
                          fit: BoxFit.contain,
                          alignment: Alignment.center,
                        )
                      : null,
                  border: Border.all(color: Colors.grey[400]!),
                ),
                child:
                    (_newImage == null &&
                        (widget.skill.gambarSkill == null ||
                            widget.skill.gambarSkill!.isEmpty))
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
                            'Ganti Foto Keahlian',
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
                                  _newImage = null;
                                  // Note: We can't easily remove the existing server image without an API call,
                                  // so this just clears the new selection.
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: Colors.black54,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.edit,
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
                          'Simpan Perubahan',
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

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );

    if (pickedFile != null) {
      setState(() {
        _newImage = pickedFile;
      });
    }
  }
}
