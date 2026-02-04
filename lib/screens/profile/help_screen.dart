import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import 'dart:io';
import 'package:flutter/foundation.dart'; // for kIsWeb
import '../../services/api_service.dart';
import '../../widgets/custom_notification.dart';

class HelpScreen extends StatefulWidget {
  const HelpScreen({super.key});

  @override
  State<HelpScreen> createState() => _HelpScreenState();
}

class _HelpScreenState extends State<HelpScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  final _formKey = GlobalKey<FormState>();
  final _messageController = TextEditingController();
  XFile? _image;
  bool _isSubmitting = false;

  // Entrance Animations
  late AnimationController _entranceController;
  late Animation<Offset> _headerSlideAnimation;
  late Animation<Offset> _contentSlideAnimation;

  // Form Specific Animation
  late AnimationController _formController;
  late Animation<Offset> _formSlideAnimation;

  final List<Map<String, dynamic>> _faqs = [
    {
      'question': 'Apa itu SkillCoin?',
      'answer':
          'SkillCoin adalah mata uang digital dalam aplikasi yang digunakan untuk membayar jasa atau memberikan apresiasi kepada partner barter.',
      'icon': Icons.monetization_on_rounded,
      'color': Colors.amber,
    },
    {
      'question': 'Bagaimana cara mendapatkan SkillCoin?',
      'answer':
          'Anda akan mendapatkan SkillCoin saat pertama kali mendaftar (Bonus), atau dengan menyelesaikan misi dan membantu orang lain.',
      'icon': Icons.account_balance_wallet_rounded,
      'color': Colors.green,
    },
    {
      'question': 'Apakah saya bisa membatalkan transaksi?',
      'answer':
          'Ya, selama status transaksi masih "Menunggu" atau "Berlangsung", Anda bisa membatalkannya. Namun koin mungkin akan dikembalikan atau hangus tergantung kondisi.',
      'icon': Icons.cancel_rounded,
      'color': Colors.redAccent,
    },
    {
      'question': 'Bagaimana sistem rating bekerja?',
      'answer':
          'Rating diberikan setelah transaksi selesai. Rating mempengaruhi reputasi Anda agar lebih dipercaya oleh pengguna lain.',
      'icon': Icons.star_rounded,
      'color': Colors.orange,
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // Listen to tab changes to trigger form animation
    _tabController.addListener(() {
      if (_tabController.index == 1 && !_tabController.indexIsChanging) {
        _formController.forward(from: 0.0);
      }
    });

    // Initialize Entrance Animations
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _headerSlideAnimation =
        Tween<Offset>(
          begin: const Offset(0, -0.5), // Reduced distance
          end: Offset.zero,
        ).animate(
          CurvedAnimation(
            parent: _entranceController,
            curve: Curves.easeOutQuart,
          ),
        );

    _contentSlideAnimation =
        Tween<Offset>(
          begin: const Offset(0, 0.15), // Reduced distance
          end: Offset.zero,
        ).animate(
          CurvedAnimation(
            parent: _entranceController,
            curve: Curves.easeOutQuart,
          ),
        );

    // Initialize Form Animation
    _formController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _formSlideAnimation =
        Tween<Offset>(
          begin: const Offset(0, 0.2), // Reduced distance
          end: Offset.zero,
        ).animate(
          CurvedAnimation(
            parent: _formController,
            curve: Curves.easeOutQuart, // No bounce
          ),
        );

    // Start Main Animation
    _entranceController.forward();

    // Start Form Animation with delay
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _formController.forward();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _messageController.dispose();
    _entranceController.dispose();
    _formController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => _image = picked);
    }
  }

  // Animation State
  bool _isSent = false;
  bool _isAnimating = false;
  double _planePosition = 0.0;

  Future<void> _animateAndSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final api = ApiService();
      Map<String, dynamic> formDataMap = {
        'deskripsi': _messageController.text,
        'jenis_laporan': 'lainnya',
      };

      if (_image != null) {
        if (kIsWeb) {
          final bytes = await _image!.readAsBytes();
          formDataMap['bukti'] = MultipartFile.fromBytes(
            bytes,
            filename: _image!.name,
          );
        } else {
          formDataMap['bukti'] = await MultipartFile.fromFile(_image!.path);
        }
      }

      FormData formData = FormData.fromMap(formDataMap);
      final response = await api.post('/help/submit', data: formData);

      if (response.statusCode == 200 || response.statusCode == 201) {
        // 1. Start Animation: Hide Spinner, Show Flying Plane
        setState(() {
          _isSubmitting = false;
          _isAnimating = true;
        });

        // 2. Fly plane to the right
        for (int i = 0; i < 20; i++) {
          await Future.delayed(const Duration(milliseconds: 20));
          if (!mounted) return;
          setState(() {
            _planePosition += 20.0;
          });
        }

        // 3. Animation Done: Show "Terkirim"
        setState(() {
          _isAnimating = false;
          _isSent = true;
          _image = null;
          _messageController.clear();
        });

        // 4. Reset to Idle after delay
        await Future.delayed(const Duration(seconds: 3));
        if (!mounted) return;
        setState(() {
          _isSent = false;
          _planePosition = 0.0;
        });
      }
    } catch (e) {
      setState(() => _isSubmitting = false);
      if (!mounted) return;
      CustomNotification.showError(context, 'Gagal mengirim laporan: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          'Pusat Bantuan',
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
          // 1. Background Gradient Header with Entrance Animation
          SlideTransition(
            position: _headerSlideAnimation,
            child: Align(
              alignment: Alignment.topCenter,
              child: ClipPath(
                clipper: _HeaderClipper(),
                child: const _AnimatedHeader(),
              ),
            ),
          ),

          // 2. Main Content with Entrance Animation
          SlideTransition(
            position: _contentSlideAnimation,
            child: Column(
              children: [
                SizedBox(
                  height:
                      kToolbarHeight +
                      MediaQuery.of(context).padding.top +
                      80, // Moved down significantly
                ),

                // Tab Bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    height: 50,
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: TabBar(
                      controller: _tabController,
                      dividerColor: Colors.transparent,
                      indicatorSize: TabBarIndicatorSize.tab,
                      indicator: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(26),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      labelColor: Theme.of(context).primaryColor,
                      unselectedLabelColor: Colors.white,
                      labelStyle: const TextStyle(fontWeight: FontWeight.bold),
                      tabs: const [
                        Tab(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.quiz_rounded, size: 20),
                              SizedBox(width: 8),
                              Text('FAQ'),
                            ],
                          ),
                        ),
                        Tab(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.support_agent_rounded, size: 20),
                              SizedBox(width: 8),
                              Text('Hubungi Kami'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Scrollable Content
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [_buildFAQList(), _buildContactForm()],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFAQList() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      itemCount: _faqs.length,
      itemBuilder: (context, index) {
        final item = _faqs[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: (item['color'] as Color).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(item['icon'], color: item['color'], size: 24),
              ),
              title: Text(
                item['question'],
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              childrenPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              children: [
                Text(
                  item['answer'],
                  style: TextStyle(color: Colors.grey[600], height: 1.5),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildContactForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 30),
      child: SlideTransition(
        position: _formSlideAnimation,
        child: Container(
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
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        Icons.headset_mic_rounded,
                        color: Theme.of(context).primaryColor,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Butuh Bantuan?',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Ceritakan masalah Anda, tim kami akan segera membantu.',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Text Field
                TextFormField(
                  controller: _messageController,
                  maxLines: 5,
                  decoration: InputDecoration(
                    labelText: 'Deskripsi Masalah',
                    alignLabelWithHint: true,
                    hintText: 'Jelaskan kendala Anda...',
                    floatingLabelBehavior: FloatingLabelBehavior.always,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
                    contentPadding: const EdgeInsets.all(20),
                  ),
                  validator: (v) =>
                      v!.isEmpty ? 'Mohon jelaskan kendala Anda' : null,
                ),

                const SizedBox(height: 20),

                // Image Picker
                InkWell(
                  onTap: _pickImage,
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    height: 150,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.grey[200]!,
                        style: BorderStyle.solid,
                      ),
                      image: _image != null
                          ? DecorationImage(
                              image: kIsWeb
                                  ? NetworkImage(_image!.path)
                                  : FileImage(File(_image!.path))
                                        as ImageProvider,
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: _image == null
                        ? Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.add_photo_alternate_rounded,
                                size: 40,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Upload Screenshot (Opsional)',
                                style: TextStyle(
                                  color: Colors.grey[500],
                                  fontWeight: FontWeight.w500,
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
                                  onTap: () => setState(() => _image = null),
                                  child: Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: const BoxDecoration(
                                      color: Colors.red,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.close,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                  ),
                ),

                const SizedBox(height: 32),

                // ANIMATED BUTTON
                GestureDetector(
                  onTap: (_isSubmitting || _isAnimating || _isSent)
                      ? null
                      : _animateAndSubmit,
                  child: Container(
                    width: double.infinity,
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: _isSent
                            ? [Colors.green, Colors.green.shade700]
                            : [
                                Theme.of(context).primaryColor,
                                const Color(0xFF1565C0),
                              ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color:
                              (_isSent
                                      ? Colors.green
                                      : Theme.of(context).primaryColor)
                                  .withOpacity(0.3),
                          blurRadius: 15,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        if (!_isSubmitting && !_isAnimating && !_isSent)
                          const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.send_rounded, color: Colors.white),
                              SizedBox(width: 12),
                              Text(
                                'Kirim Laporan',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        if (_isSubmitting)
                          const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          ),
                        if (_isAnimating)
                          Transform.translate(
                            offset: Offset(_planePosition, 0),
                            child: const Icon(
                              Icons.send_rounded,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                        if (_isSent)
                          const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.check_circle_rounded,
                                color: Colors.white,
                              ),
                              SizedBox(width: 12),
                              Text(
                                'Terkirim',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
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
    );
  }
}

// Reusable Header Components
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
