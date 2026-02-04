import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../widgets/custom_notification.dart';
import '../../widgets/status_dialog.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _oldPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  bool _obscureOld = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  late AnimationController _entryController;

  @override
  void initState() {
    super.initState();
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..forward();
  }

  @override
  void dispose() {
    _entryController.dispose();
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final api = ApiService();
      final response = await api.put(
        '/auth/change-password',
        data: {
          'password_lama': _oldPasswordController.text,
          'password_baru': _newPasswordController.text,
        },
      );

      if (response.statusCode == 200) {
        if (!mounted) return;
        await StatusDialog.show(
          context,
          success: true,
          title: 'Berhasil',
          message: 'Kata sandi berhasil diubah',
        );
        if (mounted) Navigator.pop(context);
      }
    } catch (e) {
      if (!mounted) return;
      StatusDialog.show(
        context,
        success: false,
        title: 'Gagal',
        message: 'Gagal mengubah kata sandi. Cek password lama Anda.',
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Stack(
        children: [
          // 1. Animated Header (Slide Down)
          SlideTransition(
            position:
                Tween<Offset>(
                  begin: const Offset(0, -1.0),
                  end: Offset.zero,
                ).animate(
                  CurvedAnimation(
                    parent: _entryController,
                    curve: const Interval(0.0, 1.0, curve: Curves.easeOutQuart),
                  ),
                ),
            child: Align(
              alignment: Alignment.topCenter,
              child: ClipPath(
                clipper: _HeaderClipper(),
                child: const _AnimatedHeader(),
              ),
            ),
          ),

          // 2. Content
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Back Button & Title
                  Row(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(
                            Icons.arrow_back_ios_new,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Text(
                        'Ubah Password',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),

                  Padding(
                    padding: const EdgeInsets.only(
                      left: 12,
                      top: 16,
                      bottom: 30,
                    ),
                    child: Text(
                      'Amankan akun Anda dengan password yang kuat dan unik.',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.95),
                        height: 1.5,
                      ),
                    ),
                  ),

                  const SizedBox(height: 50), // Push card down
                  // Form Card (Slide Up)
                  SlideTransition(
                    position:
                        Tween<Offset>(
                          begin: const Offset(0, 1.0),
                          end: Offset.zero,
                        ).animate(
                          CurvedAnimation(
                            parent: _entryController,
                            curve: const Interval(
                              0.0,
                              1.0,
                              curve: Curves.easeOutQuart,
                            ),
                          ),
                        ),
                    child: Card(
                      elevation: 10,
                      shadowColor: Colors.black.withOpacity(0.1),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            children: [
                              // Icon Header inside card
                              Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: Theme.of(
                                    context,
                                  ).primaryColor.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.lock_reset_rounded,
                                  size: 48,
                                  color: Theme.of(context).primaryColor,
                                ),
                              ),
                              const SizedBox(height: 32),

                              _buildField(
                                label: 'Password Lama',
                                controller: _oldPasswordController,
                                obscure: _obscureOld,
                                icon: Icons.lock_outline_rounded,
                                onToggle: () =>
                                    setState(() => _obscureOld = !_obscureOld),
                                validator: (v) => v!.isEmpty
                                    ? 'Password lama wajib diisi'
                                    : null,
                              ),
                              const SizedBox(height: 20),
                              _buildField(
                                label: 'Password Baru',
                                controller: _newPasswordController,
                                obscure: _obscureNew,
                                icon: Icons.vpn_key_rounded,
                                onToggle: () =>
                                    setState(() => _obscureNew = !_obscureNew),
                                validator: (v) {
                                  if (v!.isEmpty)
                                    return 'Password baru wajib diisi';
                                  if (v.length < 6) return 'Minimal 6 karakter';
                                  return null;
                                },
                              ),
                              const SizedBox(height: 20),
                              _buildField(
                                label: 'Konfirmasi Password Baru',
                                controller: _confirmPasswordController,
                                obscure: _obscureConfirm,
                                icon: Icons.verified_user_rounded,
                                onToggle: () => setState(
                                  () => _obscureConfirm = !_obscureConfirm,
                                ),
                                validator: (v) {
                                  if (v!.isEmpty)
                                    return 'Konfirmasi wajib diisi';
                                  if (v != _newPasswordController.text) {
                                    return 'Password tidak sama';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 40),
                              SizedBox(
                                width: double.infinity,
                                height: 56,
                                child: ElevatedButton(
                                  onPressed: _isLoading ? null : _submit,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Theme.of(
                                      context,
                                    ).primaryColor,
                                    foregroundColor: Colors.white,
                                    elevation: 8,
                                    shadowColor: Theme.of(
                                      context,
                                    ).primaryColor.withOpacity(0.4),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                  child: _isLoading
                                      ? const SizedBox(
                                          height: 24,
                                          width: 24,
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2.5,
                                          ),
                                        )
                                      : const Text(
                                          'Simpan Password Baru',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildField({
    required String label,
    required TextEditingController controller,
    required bool obscure,
    required IconData icon,
    required VoidCallback onToggle,
    required String? Function(String?) validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: Colors.grey[600],
          fontWeight: FontWeight.normal,
        ),
        prefixIcon: Icon(icon, color: Colors.grey[400], size: 22),
        filled: true,
        fillColor: Colors.grey[50],
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.shade200),
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
          borderSide: const BorderSide(color: Colors.redAccent),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.redAccent, width: 2),
        ),
        suffixIcon: IconButton(
          icon: Icon(
            obscure ? Icons.visibility_rounded : Icons.visibility_off_rounded,
            color: Colors.grey[400],
            size: 22,
          ),
          onPressed: onToggle,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 18,
        ),
      ),
      validator: validator,
    );
  }
}

// Reusable Header Components (Copied to be self-contained in this file as per pattern)
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
