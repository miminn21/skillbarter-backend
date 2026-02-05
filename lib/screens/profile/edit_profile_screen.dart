import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/profile_service.dart';
import '../../models/user_model.dart';
import '../../widgets/status_dialog.dart';
import '../../services/app_localizations.dart';

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
  late Animation<Offset> _headerSlideAnimation;
  late Animation<Offset> _contentSlideAnimation;

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
      duration: const Duration(milliseconds: 1000), // Smoother duration
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );

    _headerSlideAnimation =
        Tween<Offset>(begin: const Offset(0, -0.5), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOutQuart,
          ),
        );

    _contentSlideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOutQuart,
          ),
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
        if (!mounted) return;
        StatusDialog.show(
          context,
          success: true,
          title: AppLocalizations.of(context)!.translate('dialog_upload_title'),
          message: AppLocalizations.of(
            context,
          )!.translate('msg_profile_updated'),
        );
      } else {
        StatusDialog.show(
          context,
          success: false,
          title: AppLocalizations.of(context)!.translate('dialog_error_title'),
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
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SlideTransition(
              position: _headerSlideAnimation,
              child: const _AnimatedHeader(),
            ),
          ),

          // 2. Scrollable Content
          Positioned.fill(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: SlideTransition(
                position: _contentSlideAnimation,
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
                              _buildSectionTitle(
                                AppLocalizations.of(
                                  context,
                                )!.translate('info_title'),
                              ),
                              const SizedBox(height: 16),
                              _buildTextField(
                                controller: _namaPanggilanController,
                                label: AppLocalizations.of(
                                  context,
                                )!.translate('label_nickname'),
                                icon: Icons.person_rounded, // Premium Icon
                                validator: (v) => v?.isEmpty == true
                                    ? AppLocalizations.of(
                                        context,
                                      )!.translate('error_required')
                                    : null,
                              ),
                              const SizedBox(height: 16),
                              _buildTextField(
                                controller: _bioController,
                                label: AppLocalizations.of(
                                  context,
                                )!.translate('label_bio_short'),
                                icon: Icons.edit_note_rounded,
                                maxLines: 3,
                                hint: AppLocalizations.of(
                                  context,
                                )!.translate('hint_bio'),
                              ),

                              const SizedBox(height: 32),
                              _buildSectionTitle(
                                AppLocalizations.of(
                                  context,
                                )!.translate('section_job_edu'),
                              ),
                              const SizedBox(height: 16),
                              _buildTextField(
                                controller: _pekerjaanController,
                                label: AppLocalizations.of(
                                  context,
                                )!.translate('label_job'),
                                icon: Icons.work_rounded, // Premium Icon
                                hint: 'Contoh: Freelance Desainer',
                              ),
                              const SizedBox(height: 16),
                              _buildTextField(
                                controller: _instansiController,
                                label: AppLocalizations.of(
                                  context,
                                )!.translate('label_instance'),
                                icon: Icons.business_rounded,
                                hint: AppLocalizations.of(
                                  context,
                                )!.translate('hint_instance'),
                              ),
                              const SizedBox(height: 16),
                              _buildTextField(
                                controller: _pendidikanController,
                                label: AppLocalizations.of(
                                  context,
                                )!.translate('label_last_edu'),
                                icon: Icons.school_rounded,
                                hint: AppLocalizations.of(
                                  context,
                                )!.translate('hint_edu'),
                              ),

                              const SizedBox(height: 32),
                              _buildSectionTitle(
                                AppLocalizations.of(
                                  context,
                                )!.translate('section_pref_other'),
                              ),
                              const SizedBox(height: 16),
                              _buildTextField(
                                controller: _bahasaController,
                                label: AppLocalizations.of(
                                  context,
                                )!.translate('label_languages'),
                                icon: Icons.translate_rounded, // Premium Icon
                                hint: AppLocalizations.of(
                                  context,
                                )!.translate('hint_languages'),
                              ),
                              const SizedBox(height: 16),
                              _buildDropdown(
                                value: _selectedLokasi,
                                label: AppLocalizations.of(
                                  context,
                                )!.translate('label_pref_loc'),
                                icon: Icons.location_on_rounded, // Premium Icon
                                items: [
                                  {
                                    'label': 'Online',
                                    'value': 'online',
                                  }, // Static as value is logic related? No label should be localized.
                                  {
                                    'label': AppLocalizations.of(
                                      context,
                                    )!.translate('loc_meet'),
                                    'value': 'offline',
                                  },
                                  {
                                    'label': AppLocalizations.of(
                                      context,
                                    )!.translate('loc_both'),
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
                                          children: [
                                            Icon(Icons.check_circle_rounded),
                                            SizedBox(width: 8),
                                            Text(
                                              AppLocalizations.of(
                                                context,
                                              )!.translate('btn_save_changes'),
                                              style: const TextStyle(
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
          ),

          // 3. Custom Fixed Header (Title & Back Button) - Lowered Position
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SlideTransition(
              position: _headerSlideAnimation,
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
                            Text(
                              AppLocalizations.of(
                                context,
                              )!.translate('edit_profile_title'),
                              style: const TextStyle(
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
                              AppLocalizations.of(
                                context,
                              )!.translate('edit_profile_subtitle'),
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
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
            color: isDark ? Colors.white : Colors.grey[800],
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      style: TextStyle(
        fontWeight: FontWeight.w600,
        fontSize: 15,
        color: isDark ? Colors.white : Colors.black87,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        alignLabelWithHint: maxLines > 1,
        labelStyle: TextStyle(
          color: isDark ? Colors.grey[400] : Colors.grey[600],
          fontWeight: FontWeight.normal,
        ),
        hintStyle: TextStyle(
          color: isDark ? Colors.grey[600] : Colors.grey.withOpacity(0.5),
        ),
        prefixIcon: Icon(
          icon,
          color: isDark
              ? Colors.white
              : Theme.of(context).primaryColor.withOpacity(0.7),
        ), // Colored Icon
        filled: true,
        fillColor: isDark
            ? Theme.of(context).cardColor
            : Colors.white, // White fill for crisp look in Card
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: isDark ? Colors.grey[800]! : Colors.grey.shade200,
            width: 1.5,
          ),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return DropdownButtonFormField<String>(
      value: value,
      items: items.map((item) {
        return DropdownMenuItem(
          value: item['value'],
          child: Text(item['label']!),
        );
      }).toList(),
      onChanged: onChanged,
      style: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: isDark ? Colors.white : Colors.black87,
      ),
      dropdownColor: isDark ? Theme.of(context).cardColor : Colors.white,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: isDark ? Colors.grey[400] : Colors.grey[600],
          fontWeight: FontWeight.normal,
        ),
        prefixIcon: Icon(
          icon,
          color: isDark
              ? Colors.white
              : Theme.of(context).primaryColor.withOpacity(0.7),
        ),
        filled: true,
        fillColor: isDark ? Theme.of(context).cardColor : Colors.white,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: isDark ? Colors.grey[800]! : Colors.grey.shade200,
            width: 1.5,
          ),
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
