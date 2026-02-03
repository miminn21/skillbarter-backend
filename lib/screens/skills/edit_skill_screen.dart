import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/skill_provider.dart';
import '../../models/skill_model.dart';
import '../../models/category_model.dart';
import '../../widgets/custom_notification.dart';
import '../../widgets/status_dialog.dart';
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
      await StatusDialog.show(
        context,
        success: true,
        title: 'Berhasil',
        message: 'Perubahan skill telah disimpan',
      );
      if (mounted) Navigator.pop(context, true);
    } else {
      if (mounted) {
        StatusDialog.show(
          context,
          success: false,
          title: 'Gagal',
          message: skillProvider.error ?? 'Gagal menyimpan perubahan',
        );
      }
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
        _newImage = pickedFile;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          'Edit Skill',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new,
              size: 18,
              color: Colors.white,
            ),
            onPressed: () => Navigator.pop(context),
          ),
        ),
      ),
      body: Stack(
        children: [
          // Background Gradient Header
          Align(
            alignment: Alignment.topCenter,
            child: ClipPath(
              clipper: _HeaderClipper(),
              child: const _AnimatedHeader(),
            ),
          ),

          // Scrollable Form Container
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 100),
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 1. Image Picker Header
                          GestureDetector(
                            onTap: _pickImage,
                            child: Container(
                              height: 200,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(24),
                                ),
                                image: _newImage != null
                                    ? DecorationImage(
                                        image: kIsWeb
                                            ? NetworkImage(_newImage!.path)
                                            : FileImage(File(_newImage!.path))
                                                  as ImageProvider,
                                        fit: BoxFit.cover,
                                      )
                                    : (widget.skill.gambarSkill != null &&
                                          widget.skill.gambarSkill!.isNotEmpty)
                                    ? DecorationImage(
                                        image: MemoryImage(
                                          base64Decode(
                                            widget.skill.gambarSkill!,
                                          ),
                                        ),
                                        fit: BoxFit.cover,
                                      )
                                    : null,
                              ),
                              child: Stack(
                                children: [
                                  if (_newImage == null &&
                                      (widget.skill.gambarSkill == null ||
                                          widget.skill.gambarSkill!.isEmpty))
                                    Center(
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(16),
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              shape: BoxShape.circle,
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black
                                                      .withOpacity(0.1),
                                                  blurRadius: 10,
                                                ),
                                              ],
                                            ),
                                            child: Icon(
                                              Icons.add_a_photo_rounded,
                                              size: 40,
                                              color: Theme.of(
                                                context,
                                              ).primaryColor,
                                            ),
                                          ),
                                          const SizedBox(height: 12),
                                          Text(
                                            'Pilih Foto Sampul',
                                            style: TextStyle(
                                              color: Colors.grey[600],
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  // Edit Icon Overlay
                                  Positioned(
                                    bottom: 16,
                                    right: 16,
                                    child: Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withOpacity(0.6),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Icon(
                                        Icons.edit_rounded,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Informasi Dasar',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 20),

                                // Nama Keahlian
                                _buildModernTextField(
                                  controller: _namaController,
                                  label: 'Nama Keahlian',
                                  icon: Icons.workspace_premium_rounded,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Nama keahlian wajib diisi';
                                    }
                                    if (value.length < 3) {
                                      return 'Deskripsi terlalu pendek';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),

                                // Kategori Dropdown
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                  ),
                                  child: Consumer<SkillProvider>(
                                    builder: (context, skillProvider, _) {
                                      return DropdownButtonFormField<
                                        CategoryModel
                                      >(
                                        value: _selectedCategory,
                                        decoration: _buildInputDecoration(
                                          'Kategori',
                                          Icons.category_rounded,
                                        ),
                                        items: skillProvider.categories.map((
                                          category,
                                        ) {
                                          return DropdownMenuItem(
                                            value: category,
                                            child: Text(category.namaKategori),
                                          );
                                        }).toList(),
                                        onChanged: (value) => setState(
                                          () => _selectedCategory = value,
                                        ),
                                        validator: (value) => value == null
                                            ? 'Wajib dipilih'
                                            : null,
                                      );
                                    },
                                  ),
                                ),
                                const SizedBox(height: 16),

                                // Tingkat Dropdown
                                DropdownButtonFormField<String>(
                                  value: _tingkat,
                                  decoration: _buildInputDecoration(
                                    'Tingkat Keahlian',
                                    Icons.signal_cellular_alt_rounded,
                                  ),
                                  items: const [
                                    DropdownMenuItem(
                                      value: 'pemula',
                                      child: Text('Pemula'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'menengah',
                                      child: Text('Menengah'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'mahir',
                                      child: Text('Mahir'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'ahli',
                                      child: Text('Ahli'),
                                    ),
                                  ],
                                  onChanged: (value) =>
                                      setState(() => _tingkat = value!),
                                ),

                                const SizedBox(height: 32),
                                const Text(
                                  'Detail & Harga',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 20),

                                // Pengalaman
                                _buildModernTextField(
                                  controller: _pengalamanController,
                                  label: 'Pengalaman (Contoh: 2 Tahun)',
                                  icon: Icons.history_edu_rounded,
                                ),
                                const SizedBox(height: 16),

                                // Harga
                                _buildModernTextField(
                                  controller: _hargaController,
                                  label: 'Harga per Jam (SkillCoin)',
                                  icon: Icons.monetization_on_rounded,
                                  keyboardType: TextInputType.number,
                                  suffixText: 'SC',
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Wajib diisi';
                                    }
                                    if (int.tryParse(value) == null) {
                                      return 'Harus angka';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),

                                // Deskripsi
                                _buildModernTextField(
                                  controller: _deskripsiController,
                                  label: 'Deskripsi Detail',
                                  icon: Icons.description_rounded,
                                  maxLines: 4,
                                ),
                                const SizedBox(height: 16),

                                // Link
                                _buildModernTextField(
                                  controller: _linkController,
                                  label: 'Link Portfolio (URL)',
                                  icon: Icons.link_rounded,
                                  keyboardType: TextInputType.url,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: Consumer<SkillProvider>(
          builder: (context, skillProvider, _) {
            return ElevatedButton(
              onPressed: skillProvider.isLoading ? null : _handleSubmit,
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 4,
                shadowColor: Theme.of(context).primaryColor.withOpacity(0.4),
              ),
              child: skillProvider.isLoading
                  ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text(
                      'Simpan Perubahan',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildModernTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    String? suffixText,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: _buildInputDecoration(label, icon, suffixText: suffixText),
      validator: validator,
    );
  }

  InputDecoration _buildInputDecoration(
    String label,
    IconData icon, {
    String? suffixText,
  }) {
    return InputDecoration(
      labelText: label,
      alignLabelWithHint: true,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Theme.of(context).primaryColor, width: 2),
      ),
      filled: true,
      fillColor: Colors.grey.shade50,
      prefixIcon: Container(
        margin: const EdgeInsets.all(8),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Theme.of(context).primaryColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: Theme.of(context).primaryColor, size: 20),
      ),
      suffixText: suffixText,
      suffixStyle: const TextStyle(fontWeight: FontWeight.bold),
    );
  }
}

// Reusable Header Components (Standardized)
class _AnimatedHeader extends StatefulWidget {
  const _AnimatedHeader();
  @override
  State<_AnimatedHeader> createState() => _AnimatedHeaderState();
}

class _AnimatedHeaderState extends State<_AnimatedHeader>
    with TickerProviderStateMixin {
  late AnimationController _controller1;
  late AnimationController _controller2;

  @override
  void initState() {
    super.initState();
    _controller1 = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
    _controller2 = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller1.dispose();
    _controller2.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 250,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).primaryColor,
            const Color(0xFF1E88E5),
            const Color(0xFF1565C0),
          ],
        ),
      ),
      child: Stack(
        children: [
          _buildCircle(_controller1, -30, -30, 150),
          _buildCircle(_controller2, null, -20, 200, bottom: 20, right: true),
        ],
      ),
    );
  }

  Widget _buildCircle(
    AnimationController controller,
    double? top,
    double? left,
    double size, {
    double? bottom,
    bool right = false,
  }) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        return Positioned(
          top: top != null ? top + (controller.value * 20) : null,
          bottom: bottom != null ? bottom + (controller.value * 30) : null,
          left: !right ? left! + (controller.value * 30) : null,
          right: right ? left! + (controller.value * 20) : null,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.05),
            ),
          ),
        );
      },
    );
  }
}

class _HeaderClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    var path = Path();
    path.lineTo(0, size.height - 40);
    path.quadraticBezierTo(
      size.width / 2,
      size.height + 20,
      size.width,
      size.height - 40,
    );
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
