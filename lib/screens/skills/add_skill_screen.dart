import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'dart:math' as math;
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

class _AddSkillScreenState extends State<AddSkillScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _namaController = TextEditingController();
  final _pengalamanController = TextEditingController();
  final _deskripsiController = TextEditingController();
  final _hargaController = TextEditingController();
  final _linkController = TextEditingController();

  // Animation
  late AnimationController _entranceController;

  XFile? _skillImage;
  CategoryModel? _selectedCategory;
  String _tipe = 'dikuasai';
  String _tingkat = 'menengah';
  DateTime? _expiryDate;

  @override
  void initState() {
    super.initState();
    // Entrance Animation Controller
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _entranceController.forward();

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
    _entranceController.dispose();
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

  // Helper method for staggered animation
  Widget _buildStaggeredItem({
    required Widget child,
    required double startInterval,
    required double endInterval,
  }) {
    final animation = CurvedAnimation(
      parent: _entranceController,
      curve: Interval(startInterval, endInterval, curve: Curves.easeOutQuart),
    );

    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.2), // Slide up from slight bottom
          end: Offset.zero,
        ).animate(animation),
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      body: Stack(
        children: [
          // 1. Fixed Wave Background Header
          const Positioned(top: 0, left: 0, right: 0, child: _WaveHeader()),

          // 2. Main Scrollable Content
          Positioned.fill(
            child: SafeArea(
              child: Column(
                children: [
                  // Custom AppBar Title with Fade In
                  FadeTransition(
                    opacity: _entranceController,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: Row(
                        children: [
                          IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(
                              Icons.arrow_back,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Tambah Skill Baru',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Scrollable Form
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 20,
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 1. Image Picker (Staggered 0.1 - 0.5)
                            _buildStaggeredItem(
                              startInterval: 0.1,
                              endInterval: 0.5,
                              child: _buildImagePicker(),
                            ),
                            const SizedBox(height: 24),

                            // 2. Info Card (Staggered 0.2 - 0.6)
                            _buildStaggeredItem(
                              startInterval: 0.2,
                              endInterval: 0.6,
                              child: Card(
                                elevation: 8,
                                shadowColor: Colors.black.withOpacity(0.05),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(20),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      _buildSectionTitle('Informasi Skill'),
                                      const SizedBox(height: 16),
                                      _buildTextField(
                                        controller: _namaController,
                                        label: 'Nama Keahlian',
                                        icon: Icons.star_rounded,
                                        validator: (v) => v?.isEmpty == true
                                            ? 'Wajib diisi'
                                            : null,
                                      ),
                                      const SizedBox(height: 16),
                                      _buildCategoryDropdown(),
                                      const SizedBox(height: 16),
                                      _buildDropdown(
                                        value: _tipe,
                                        label: 'Tipe',
                                        icon: Icons.swap_horiz_rounded,
                                        items: const [
                                          {
                                            'label': 'Dikuasai (Saya bisa)',
                                            'value': 'dikuasai',
                                          },
                                          {
                                            'label': 'Dicari (Saya butuh)',
                                            'value': 'dicari',
                                          },
                                        ],
                                        onChanged: (v) =>
                                            setState(() => _tipe = v),
                                      ),
                                      const SizedBox(height: 16),
                                      _buildDropdown(
                                        value: _tingkat,
                                        label: 'Tingkat Keahlian',
                                        icon: Icons.trending_up_rounded,
                                        items: const [
                                          {
                                            'label': 'Pemula',
                                            'value': 'pemula',
                                          },
                                          {
                                            'label': 'Menengah',
                                            'value': 'menengah',
                                          },
                                          {'label': 'Mahir', 'value': 'mahir'},
                                          {'label': 'Ahli', 'value': 'ahli'},
                                        ],
                                        onChanged: (v) =>
                                            setState(() => _tingkat = v),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),

                            // 3. Detail Card (Staggered 0.3 - 0.7)
                            _buildStaggeredItem(
                              startInterval: 0.3,
                              endInterval: 0.7,
                              child: Card(
                                elevation: 8,
                                shadowColor: Colors.black.withOpacity(0.05),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(20),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      _buildSectionTitle('Detail Tambahan'),
                                      const SizedBox(height: 16),
                                      _buildTextField(
                                        controller: _hargaController,
                                        label: 'Harga per Sesi (SkillCoin)',
                                        icon: Icons.monetization_on_rounded,
                                        keyboardType: TextInputType.number,
                                      ),
                                      const SizedBox(height: 16),
                                      _buildTextField(
                                        controller: _pengalamanController,
                                        label: 'Pengalaman (Tahun/Proyek)',
                                        icon: Icons.work_history_rounded,
                                      ),
                                      const SizedBox(height: 16),
                                      _buildTextField(
                                        controller: _deskripsiController,
                                        label: 'Deskripsi Lengkap',
                                        icon: Icons.description_rounded,
                                        maxLines: 4,
                                      ),
                                      const SizedBox(height: 16),
                                      _buildTextField(
                                        controller: _linkController,
                                        label: 'Link Portofolio (URL)',
                                        icon: Icons.link_rounded,
                                        keyboardType: TextInputType.url,
                                      ),
                                      if (_tipe == 'dicari') ...[
                                        const SizedBox(height: 16),
                                        _buildDatePicker(),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 32),

                            // 4. Submit Button (Staggered 0.4 - 0.8)
                            _buildStaggeredItem(
                              startInterval: 0.4,
                              endInterval: 0.8,
                              child: Consumer<SkillProvider>(
                                builder: (context, skillProvider, _) {
                                  return SizedBox(
                                    width: double.infinity,
                                    height: 54,
                                    child: ElevatedButton(
                                      onPressed: skillProvider.isLoading
                                          ? null
                                          : _handleSubmit,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Theme.of(
                                          context,
                                        ).primaryColor,
                                        foregroundColor: Colors.white,
                                        elevation: 8,
                                        shadowColor: Theme.of(
                                          context,
                                        ).primaryColor.withOpacity(0.5),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                        ),
                                      ),
                                      child: skillProvider.isLoading
                                          ? const CircularProgressIndicator(
                                              color: Colors.white,
                                            )
                                          : const Text(
                                              'Simpan & Publikasikan',
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                    ),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(height: 40),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImagePicker() {
    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        height: 200,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
          image: _skillImage != null
              ? DecorationImage(
                  image: kIsWeb
                      ? NetworkImage(_skillImage!.path)
                      : FileImage(File(_skillImage!.path)) as ImageProvider,
                  fit: BoxFit.cover,
                )
              : null,
        ),
        child: _skillImage == null
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.add_photo_alternate_rounded,
                      size: 40,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Upload Foto Sampul',
                    style: TextStyle(
                      color: Colors.grey[700],
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Tap untuk memilih gambar',
                    style: TextStyle(color: Colors.grey[500], fontSize: 12),
                  ),
                ],
              )
            : Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withOpacity(0.0),
                          Colors.black.withOpacity(0.4),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    top: 12,
                    right: 12,
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _skillImage = null;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 1.5),
                        ),
                        child: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 16,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.edit, color: Colors.white, size: 14),
                            SizedBox(width: 4),
                            Text(
                              'Ganti Foto',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          width: 40,
          height: 3,
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor,
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: Colors.grey[600],
          fontWeight: FontWeight.normal,
        ),
        alignLabelWithHint: maxLines > 1,
        prefixIcon: Padding(
          padding: EdgeInsets.only(bottom: maxLines > 1 ? 60 : 0),
          child: Icon(
            icon,
            color: Theme.of(context).primaryColor.withOpacity(0.7),
          ),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.shade200, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: Theme.of(context).primaryColor,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.red, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 18,
        ),
      ),
    );
  }

  Widget _buildCategoryDropdown() {
    return Consumer<SkillProvider>(
      builder: (context, skillProvider, _) {
        return DropdownButtonFormField<CategoryModel>(
          value: _selectedCategory,
          decoration: InputDecoration(
            labelText: 'Kategori Keahlian',
            labelStyle: TextStyle(color: Colors.grey[600]),
            prefixIcon: Icon(
              Icons.category_rounded,
              color: Theme.of(context).primaryColor.withOpacity(0.7),
            ),
            filled: true,
            fillColor: Colors.grey.shade50,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.grey.shade200, width: 1.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: Theme.of(context).primaryColor,
                width: 2,
              ),
            ),
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
          validator: (value) => value == null ? 'Kategori wajib dipilih' : null,
        );
      },
    );
  }

  Widget _buildDropdown({
    required dynamic value,
    required String label,
    required IconData icon,
    required List<Map<String, dynamic>> items,
    required Function(dynamic) onChanged,
  }) {
    return DropdownButtonFormField<dynamic>(
      value: value,
      items: items.map((item) {
        return DropdownMenuItem(
          value: item['value'],
          child: Text(item['label']),
        );
      }).toList(),
      onChanged: onChanged,
      dropdownColor: Colors.white,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.grey[600]),
        prefixIcon: Icon(
          icon,
          color: Theme.of(context).primaryColor.withOpacity(0.7),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.shade200, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: Theme.of(context).primaryColor,
            width: 2,
          ),
        ),
      ),
    );
  }

  Widget _buildDatePicker() {
    return InkWell(
      onTap: () => _selectExpiryDate(context),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: 'Tanggal Berakhir (Opsional)',
          labelStyle: TextStyle(color: Colors.grey[600]),
          prefixIcon: Icon(
            Icons.event_rounded,
            color: Theme.of(context).primaryColor.withOpacity(0.7),
          ),
          filled: true,
          fillColor: Colors.grey.shade50,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.grey.shade200, width: 1.5),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: Theme.of(context).primaryColor,
              width: 2,
            ),
          ),
        ),
        child: Text(
          _expiryDate != null
              ? DateFormat('dd MMMM yyyy', 'id_ID').format(_expiryDate!)
              : 'Pilih Tanggal',
          style: TextStyle(
            color: _expiryDate != null ? Colors.black87 : Colors.grey[500],
            fontSize: 16,
          ),
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

// === WAVE ANIMATION HEADER ===

class _WaveHeader extends StatefulWidget {
  const _WaveHeader();

  @override
  State<_WaveHeader> createState() => _WaveHeaderState();
}

class _WaveHeaderState extends State<_WaveHeader>
    with SingleTickerProviderStateMixin {
  late AnimationController _waveController;

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _waveController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _waveController,
      builder: (context, child) {
        return Stack(
          children: [
            // Background Gradient
            Container(
              height: 280,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFF1565C0), // Deep Blue
                    Theme.of(context).primaryColor, // Primary
                    const Color(0xFF42A5F5), // Light Blue
                  ],
                ),
              ),
            ),

            // Wave 1 (Behind, Slower, Smoother)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: ClipPath(
                clipper: WaveClipper(
                  animationValue: _waveController.value,
                  waveHeight: 20,
                  offset: 0,
                ),
                child: Container(
                  height: 100,
                  color: Colors.white.withOpacity(0.1),
                ),
              ),
            ),

            // Wave 2 (Front, Faster)
            Positioned(
              bottom: -10, // Slightly lower
              left: 0,
              right: 0,
              child: ClipPath(
                clipper: WaveClipper(
                  animationValue: _waveController.value,
                  waveHeight: 30, // Higher wave
                  offset: 0.5, // Phase shift
                ),
                child: Container(
                  height: 100,
                  color: const Color(0xFFF8F9FD), // Matches scaffold background
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class WaveClipper extends CustomClipper<Path> {
  final double animationValue;
  final double waveHeight;
  final double offset; // 0.0 to 1.0 (phase shift)

  WaveClipper({
    required this.animationValue,
    this.waveHeight = 20,
    this.offset = 0,
  });

  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height);

    final width = size.width;
    final height = size.height;

    // Moving Wave Calculation
    // y = A * sin(kx - wt + phi)
    // animationValue moves from 0 to 1 repeatedly.
    // We multiply it by 2*pi so it completes a full cycle.

    final double phase = (animationValue + offset) * 2 * math.pi;

    for (double x = 0; x <= width; x++) {
      // kx: (x / width) * 2 * pi -> One full wave across the screen width
      // You can multiply by 2 for two waves, etc.
      double kx = (x / width) * 2 * math.pi;

      // Calculate y
      // We start from a base height (e.g. 50% or near bottom)
      double y = height - waveHeight - (math.sin(kx + phase) * waveHeight);

      // Draw point
      if (x == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    // Close the path at the bottom
    path.lineTo(width, height);
    path.lineTo(0, height);
    path.close();

    return path;
  }

  @override
  bool shouldReclip(WaveClipper oldClipper) {
    return oldClipper.animationValue != animationValue;
  }
}
