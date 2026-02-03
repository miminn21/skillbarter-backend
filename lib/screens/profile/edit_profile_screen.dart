import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/profile_service.dart';
import '../../models/user_model.dart'; // Import UserModel
import '../../widgets/status_dialog.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // Controllers
  late TextEditingController _namaPanggilanController;
  late TextEditingController _bioController;
  late TextEditingController _pekerjaanController;
  late TextEditingController _instansiController;
  late TextEditingController _pendidikanController;
  late TextEditingController _bahasaController;

  // Dropdown values
  String? _selectedLokasi; // 'online', 'offline', 'keduanya'

  final ProfileService _profileService = ProfileService();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );
    _animationController.forward();

    final user = context.read<AuthProvider>().user!;
    _namaPanggilanController = TextEditingController(text: user.namaPanggilan);
    _bioController = TextEditingController(text: user.bio);
    _pekerjaanController = TextEditingController(text: user.pekerjaan);
    _instansiController = TextEditingController(text: user.namaInstansi);
    _pendidikanController = TextEditingController(
      text: user.pendidikanTerakhir,
    );
    _bahasaController = TextEditingController(text: user.bahasa);
    _selectedLokasi = user.preferensiLokasi;
  }

  @override
  void dispose() {
    _animationController.dispose();
    _namaPanggilanController.dispose();
    _bioController.dispose();
    _pekerjaanController.dispose();
    _instansiController.dispose();
    _pendidikanController.dispose();
    _bahasaController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final response = await _profileService.updateProfile({
        'nama_panggilan': _namaPanggilanController.text.trim(),
        'bio': _bioController.text.trim().isEmpty
            ? null
            : _bioController.text.trim(),
        'pekerjaan': _pekerjaanController.text.trim().isEmpty
            ? null
            : _pekerjaanController.text.trim(),
        'nama_instansi': _instansiController.text.trim().isEmpty
            ? null
            : _instansiController.text.trim(),
        'pendidikan_terakhir': _pendidikanController.text.trim().isEmpty
            ? null
            : _pendidikanController.text.trim(),
        'bahasa': _bahasaController.text.trim().isEmpty
            ? null
            : _bahasaController.text.trim(),
        'preferensi_lokasi': _selectedLokasi,
      });

      if (!mounted) return;
      Navigator.pop(context); // Close loading

      if (response.success) {
        // Refresh provider
        await context.read<AuthProvider>().loadProfile();

        if (!mounted) return;
        StatusDialog.show(
          context,
          success: true,
          title: 'Berhasil',
          message: 'Profil Berhasil Diperbarui',
        );
      } else {
        StatusDialog.show(
          context,
          success: false,
          title: 'Gagal',
          message: response.message,
        );
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Close loading
      StatusDialog.show(
        context,
        success: false,
        title: 'Error',
        message: 'Terjadi kesalahan: $e',
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      body: Stack(
        children: [
          // 1. Fixed Background (Does not scroll)
          const Positioned(top: 0, left: 0, right: 0, child: _AnimatedHeader()),

          // 2. Scrollable Content
          Positioned.fill(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.only(
                  top: 140, // Space for the fixed header title
                  left: 20,
                  right: 20,
                  bottom: 30,
                ),
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Form(
                    key: _formKey,
                    child: Card(
                      elevation: 10,
                      shadowColor: Colors.black.withOpacity(0.05),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSectionTitle('Informasi Dasar'),
                            const SizedBox(height: 16),
                            _buildTextField(
                              controller: _namaPanggilanController,
                              label: 'Nama Panggilan',
                              icon: Icons.person_rounded, // Premium Icon
                              validator: (v) =>
                                  v?.isEmpty == true ? 'Wajib diisi' : null,
                            ),
                            const SizedBox(height: 16),
                            _buildTextField(
                              controller: _bioController,
                              label: 'Bio Singkat',
                              icon: Icons.edit_note_rounded,
                              maxLines: 3,
                              hint: 'Ceritakan sedikit tentang dirimu...',
                            ),

                            const SizedBox(height: 32),
                            _buildSectionTitle('Pekerjaan & Pendidikan'),
                            const SizedBox(height: 16),
                            _buildTextField(
                              controller: _pekerjaanController,
                              label: 'Pekerjaan',
                              icon: Icons.work_rounded, // Premium Icon
                              hint: 'Contoh: Freelance Desainer',
                            ),
                            const SizedBox(height: 16),
                            _buildTextField(
                              controller: _instansiController,
                              label: 'Nama Instansi / Sekolah',
                              icon: Icons.business_rounded,
                              hint: 'Nama tempat kerja atau sekolah',
                            ),
                            const SizedBox(height: 16),
                            _buildTextField(
                              controller: _pendidikanController,
                              label: 'Pendidikan Terakhir',
                              icon: Icons.school_rounded,
                              hint: 'Contoh: S1 Teknik Informatika',
                            ),

                            const SizedBox(height: 32),
                            _buildSectionTitle('Preferensi & Lainnya'),
                            const SizedBox(height: 16),
                            _buildTextField(
                              controller: _bahasaController,
                              label: 'Bahasa yang Dikuasai',
                              icon: Icons.translate_rounded, // Premium Icon
                              hint: 'Contoh: Indonesia, Inggris',
                            ),
                            const SizedBox(height: 16),
                            _buildDropdown(
                              value: _selectedLokasi,
                              label: 'Preferensi Lokasi',
                              icon: Icons.location_on_rounded, // Premium Icon
                              items: [
                                {'label': 'Online', 'value': 'online'},
                                {
                                  'label': 'Offline (Bertemu Langsung)',
                                  'value': 'offline',
                                },
                                {
                                  'label': 'Keduanya (Fleksibel)',
                                  'value': 'keduanya',
                                },
                              ],
                              onChanged: (v) =>
                                  setState(() => _selectedLokasi = v),
                            ),

                            const SizedBox(height: 40),
                            SizedBox(
                              width: double.infinity,
                              height: 54,
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _handleSave,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Theme.of(
                                    context,
                                  ).primaryColor,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  elevation: 8,
                                  shadowColor: Theme.of(
                                    context,
                                  ).primaryColor.withOpacity(0.4),
                                ),
                                child: _isLoading
                                    ? const SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: const [
                                          Icon(Icons.check_circle_rounded),
                                          SizedBox(width: 8),
                                          Text(
                                            'Simpan Perubahan',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
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
                  ),
                ),
              ),
            ),
          ),

          // 3. Custom Fixed Header (Title & Back Button) - Lowered Position
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Theme.of(context).primaryColor,
                    Theme.of(context).primaryColor.withOpacity(0.95),
                    Theme.of(context).primaryColor.withOpacity(0.0),
                  ],
                  stops: const [0.0, 0.6, 1.0],
                ),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.only(
                    top: 20,
                    left: 20,
                    right: 20,
                  ), // More top padding
                  child: Row(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(
                            0.25,
                          ), // More visible glass
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        child: IconButton(
                          icon: const Icon(
                            Icons.arrow_back_ios_new_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),
                      const SizedBox(width: 20),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'Edit Profil',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                              shadows: [
                                Shadow(
                                  color: Colors.black26,
                                  offset: Offset(0, 2),
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                          ),
                          Text(
                            'Perbarui informasi data diri Anda',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 12,
                              shadows: const [
                                Shadow(
                                  color: Colors.black26,
                                  offset: Offset(0, 1),
                                  blurRadius: 2,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 18,
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
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
    String? hint,
    String? Function(String?)? validator,
  }) {
    // Premium Field Style
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        alignLabelWithHint: maxLines > 1,
        labelStyle: TextStyle(
          color: Colors.grey[600],
          fontWeight: FontWeight.normal,
        ),
        hintStyle: TextStyle(color: Colors.grey.withOpacity(0.5)),
        prefixIcon: Icon(
          icon,
          color: Theme.of(context).primaryColor.withOpacity(0.7),
        ), // Colored Icon
        filled: true,
        fillColor: Colors.white, // White fill for crisp look in Card
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
          borderSide: BorderSide(color: Colors.red.withOpacity(0.8), width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.red, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 18,
        ),
      ),
      validator: validator,
    );
  }

  Widget _buildDropdown({
    required String? value,
    required String label,
    required IconData icon,
    required List<Map<String, String>> items,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      items: items.map((item) {
        return DropdownMenuItem(
          value: item['value'],
          child: Text(item['label']!),
        );
      }).toList(),
      onChanged: onChanged,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: Colors.black87,
      ),
      dropdownColor: Colors.white,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: Colors.grey[600],
          fontWeight: FontWeight.normal,
        ),
        prefixIcon: Icon(
          icon,
          color: Theme.of(context).primaryColor.withOpacity(0.7),
        ),
        filled: true,
        fillColor: Colors.white,
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
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 16,
        ),
      ),
    );
  }
}

class _HeaderClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    var path = Path();
    path.lineTo(0, size.height - 80); // Deeper curve
    var firstControlPoint = Offset(size.width / 2, size.height + 20);
    var firstEndPoint = Offset(size.width, size.height - 80);
    path.quadraticBezierTo(
      firstControlPoint.dx,
      firstControlPoint.dy,
      firstEndPoint.dx,
      firstEndPoint.dy,
    );
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

class _AnimatedHeader extends StatefulWidget {
  const _AnimatedHeader();

  @override
  State<_AnimatedHeader> createState() => _AnimatedHeaderState();
}

class _AnimatedHeaderState extends State<_AnimatedHeader>
    with TickerProviderStateMixin {
  late AnimationController _controller1;
  late AnimationController _controller2;
  late AnimationController _controller3;

  @override
  void initState() {
    super.initState();
    // Faster, smoother animations
    _controller1 = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
    _controller2 = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat(reverse: true);
    _controller3 = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller1.dispose();
    _controller2.dispose();
    _controller3.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 340, // Expanded height requested
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor, // Fallback
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
      child: Stack(
        children: [
          // Decorative Blobs
          AnimatedBuilder(
            animation: _controller1,
            builder: (_, __) {
              return Positioned(
                top: -60 + (_controller1.value * 20),
                left: -60 + (_controller1.value * 30),
                child: Container(
                  width: 250,
                  height: 250,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        Colors.white.withOpacity(0.1),
                        Colors.blueAccent.withOpacity(0.0),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blueAccent.withOpacity(0.1),
                        blurRadius: 40,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          AnimatedBuilder(
            animation: _controller2,
            builder: (_, __) {
              return Positioned(
                bottom: 50 + (_controller2.value * 30),
                right: -80 + (_controller2.value * 40),
                child: Container(
                  width: 300,
                  height: 300,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.05),
                  ),
                ),
              );
            },
          ),
          AnimatedBuilder(
            animation: _controller3,
            builder: (_, __) {
              return Positioned(
                top: 80 + (_controller3.value * 10),
                right: 50 + (_controller2.value * -20),
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.03),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.white.withOpacity(0.05),
                        blurRadius: 30,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

          // Clip applied to the container itself if needed, but we use Full Bleed here
          // and let the Clipper in parent handle the bottom edge if we used ClipPath there.
          // Wait, the parent uses ClipPath.
          // Since we moved ClipPath to be a child of Positioned in parent?
          // No, logic was: Stack -> Positioned -> _AnimatedHeader.
          // If we want the CURVE at the bottom, we need ClipPath wrapping this Container content or applied in parent.

          // Let's modify the parent usage in `build`:
          // Previous: ClipPath(clipper: _HeaderClipper(), child: const _AnimatedHeader())
          // New: We should keep that wrap!
        ],
      ),
    );
  }
}
