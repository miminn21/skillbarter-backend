import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/auth_provider.dart';
import 'package:glossy/glossy.dart';

import '../../widgets/animated_background.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _pageController = PageController();
  int _currentPage = 0;

  // Form controllers
  final _nikController = TextEditingController();
  final _namaLengkapController = TextEditingController();
  final _namaPanggilanController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _alamatController = TextEditingController();
  final _kotaController = TextEditingController();
  final _bioController = TextEditingController();

  String _jenisKelamin = 'L';
  DateTime? _tanggalLahir;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _nikController.dispose();
    _namaLengkapController.dispose();
    _namaPanggilanController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _alamatController.dispose();
    _kotaController.dispose();
    _bioController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < 2) {
      if (_formKey.currentState!.validate()) {
        _pageController.nextPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    } else {
      _handleRegister();
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFFE94560), // Header text & selected circle color
              onPrimary: Colors.white, // Text inside selected circle
              surface: Color(0xFF16213E), // Calendar background
              onSurface: Colors.white, // Calendar text color
            ),
            dialogBackgroundColor: const Color(0xFF16213E),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFFE94560), // Button text color
              ),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _tanggalLahir = picked;
      });
    }
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;
    if (_tanggalLahir == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tanggal lahir wajib diisi'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final authProvider = context.read<AuthProvider>();

    final success = await authProvider.register(
      nik: _nikController.text.trim(),
      namaLengkap: _namaLengkapController.text.trim(),
      namaPanggilan: _namaPanggilanController.text.trim(),
      kataSandi: _passwordController.text,
      jenisKelamin: _jenisKelamin,
      tanggalLahir: DateFormat('yyyy-MM-dd').format(_tanggalLahir!),
      alamatLengkap: _alamatController.text.trim(),
      kota: _kotaController.text.trim(),
      bio: _bioController.text.trim().isEmpty
          ? null
          : _bioController.text.trim(),
    );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Registrasi berhasil! Selamat datang 🎉'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pushReplacementNamed(context, '/home');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.error ?? 'Registrasi gagal'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          'Daftar Akun',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: AnimatedBackground(
        child: SafeArea(
          child: Column(
            children: [
              // Progress Indicator
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: List.generate(3, (index) {
                    return Expanded(
                      child: Container(
                        margin: EdgeInsets.only(right: index < 2 ? 8 : 0),
                        height: 4,
                        decoration: BoxDecoration(
                          color: index <= _currentPage
                              ? Theme.of(context).colorScheme.primary
                              : Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    );
                  }),
                ),
              ),

              // Form Pages
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: GlossyContainer(
                    height: double.infinity,
                    width: double.infinity,
                    borderRadius: BorderRadius.circular(24),
                    strengthX: 12,
                    strengthY: 12,
                    opacity: 0.1,
                    border: Border.all(
                      color: Colors.white.withOpacity(0.2),
                      width: 1.5,
                    ),
                    child: Form(
                      key: _formKey,
                      child: PageView(
                        controller: _pageController,
                        physics: const NeverScrollableScrollPhysics(),
                        onPageChanged: (page) {
                          setState(() {
                            _currentPage = page;
                          });
                        },
                        children: [_buildPage1(), _buildPage2(), _buildPage3()],
                      ),
                    ),
                  ),
                ),
              ),

              // Navigation Buttons
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    if (_currentPage > 0)
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _previousPage,
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(
                              color: Colors.white.withOpacity(0.5),
                            ),
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Kembali'),
                        ),
                      ),
                    if (_currentPage > 0) const SizedBox(width: 16),
                    Expanded(
                      child: Consumer<AuthProvider>(
                        builder: (context, authProvider, _) {
                          return ElevatedButton(
                            onPressed: authProvider.isLoading
                                ? null
                                : _nextPage,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(
                                context,
                              ).colorScheme.primary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                              elevation: 5,
                            ),
                            child: authProvider.isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Text(
                                    _currentPage < 2 ? 'Lanjut' : 'Daftar',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPage1() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Data Pribadi',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 24),

          TextFormField(
            controller: _nikController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: 'NIK *',
              labelStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
              hintText: '16 digit NIK',
              hintStyle: TextStyle(color: Colors.white.withOpacity(0.4)),
              prefixIcon: Icon(
                Icons.badge,
                color: Colors.white.withOpacity(0.7),
              ),
              filled: true,
              fillColor: Colors.white.withOpacity(0.05),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
              ),
            ),
            keyboardType: TextInputType.number,
            maxLength: 16,
            validator: (value) {
              if (value == null || value.isEmpty) return 'NIK wajib diisi';
              if (value.length != 16) return 'NIK harus 16 digit';
              return null;
            },
          ),
          const SizedBox(height: 16),

          TextFormField(
            controller: _namaLengkapController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: 'Nama Lengkap *',
              labelStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
              prefixIcon: Icon(
                Icons.person,
                color: Colors.white.withOpacity(0.7),
              ),
              filled: true,
              fillColor: Colors.white.withOpacity(0.05),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
              ),
            ),
            textCapitalization: TextCapitalization.words,
            validator: (value) {
              if (value == null || value.isEmpty)
                return 'Nama lengkap wajib diisi';
              if (value.length < 3) return 'Nama minimal 3 karakter';
              return null;
            },
          ),
          const SizedBox(height: 16),

          TextFormField(
            controller: _namaPanggilanController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: 'Nama Panggilan *',
              labelStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
              prefixIcon: Icon(
                Icons.person_outline,
                color: Colors.white.withOpacity(0.7),
              ),
              filled: true,
              fillColor: Colors.white.withOpacity(0.05),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
              ),
            ),
            textCapitalization: TextCapitalization.words,
            validator: (value) {
              if (value == null || value.isEmpty)
                return 'Nama panggilan wajib diisi';
              if (value.length < 2) return 'Nama minimal 2 karakter';
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Jenis Kelamin
          DropdownButtonFormField<String>(
            value: _jenisKelamin,
            style: const TextStyle(color: Colors.white),
            dropdownColor: const Color(0xFF16213E),
            decoration: InputDecoration(
              labelText: 'Jenis Kelamin *',
              labelStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
              prefixIcon: Icon(Icons.wc, color: Colors.white.withOpacity(0.7)),
              filled: true,
              fillColor: Colors.white.withOpacity(0.05),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
              ),
            ),
            items: const [
              DropdownMenuItem(value: 'L', child: Text('Laki-laki')),
              DropdownMenuItem(value: 'P', child: Text('Perempuan')),
            ],
            onChanged: (value) {
              setState(() {
                _jenisKelamin = value!;
              });
            },
          ),
          const SizedBox(height: 16),

          // Tanggal Lahir
          InkWell(
            onTap: _selectDate,
            child: InputDecorator(
              decoration: InputDecoration(
                labelText: 'Tanggal Lahir *',
                labelStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
                prefixIcon: Icon(
                  Icons.calendar_today,
                  color: Colors.white.withOpacity(0.7),
                ),
                filled: true,
                fillColor: Colors.white.withOpacity(0.05),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
                ),
              ),
              child: Text(
                _tanggalLahir == null
                    ? 'Pilih tanggal lahir'
                    : DateFormat('dd MMMM yyyy').format(_tanggalLahir!),
                style: TextStyle(
                  color: _tanggalLahir == null
                      ? Colors.white.withOpacity(0.4)
                      : Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPage2() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Alamat',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 24),

          TextFormField(
            controller: _alamatController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: 'Alamat Lengkap *',
              labelStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
              hintText: 'Jl. Contoh No. 123',
              hintStyle: TextStyle(color: Colors.white.withOpacity(0.4)),
              prefixIcon: Icon(
                Icons.home,
                color: Colors.white.withOpacity(0.7),
              ),
              filled: true,
              fillColor: Colors.white.withOpacity(0.05),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
              ),
            ),
            maxLines: 3,
            textCapitalization: TextCapitalization.sentences,
            validator: (value) {
              if (value == null || value.isEmpty) return 'Alamat wajib diisi';
              if (value.length < 10) return 'Alamat minimal 10 karakter';
              return null;
            },
          ),
          const SizedBox(height: 16),

          TextFormField(
            controller: _kotaController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: 'Kota *',
              labelStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
              hintText: 'Jakarta',
              hintStyle: TextStyle(color: Colors.white.withOpacity(0.4)),
              prefixIcon: Icon(
                Icons.location_city,
                color: Colors.white.withOpacity(0.7),
              ),
              filled: true,
              fillColor: Colors.white.withOpacity(0.05),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
              ),
            ),
            textCapitalization: TextCapitalization.words,
            validator: (value) {
              if (value == null || value.isEmpty) return 'Kota wajib diisi';
              if (value.length < 3) return 'Kota minimal 3 karakter';
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPage3() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Keamanan & Bio',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 24),

          TextFormField(
            controller: _passwordController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: 'Password *',
              labelStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
              hintText: 'Minimal 6 karakter',
              hintStyle: TextStyle(color: Colors.white.withOpacity(0.4)),
              prefixIcon: Icon(
                Icons.lock,
                color: Colors.white.withOpacity(0.7),
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility : Icons.visibility_off,
                  color: Colors.white.withOpacity(0.7),
                ),
                onPressed: () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
              ),
              filled: true,
              fillColor: Colors.white.withOpacity(0.05),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
              ),
            ),
            obscureText: _obscurePassword,
            validator: (value) {
              if (value == null || value.isEmpty) return 'Password wajib diisi';
              if (value.length < 6) return 'Password minimal 6 karakter';
              return null;
            },
          ),
          const SizedBox(height: 16),

          TextFormField(
            controller: _confirmPasswordController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: 'Konfirmasi Password *',
              labelStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
              prefixIcon: Icon(
                Icons.lock_outline,
                color: Colors.white.withOpacity(0.7),
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureConfirmPassword
                      ? Icons.visibility
                      : Icons.visibility_off,
                  color: Colors.white.withOpacity(0.7),
                ),
                onPressed: () {
                  setState(() {
                    _obscureConfirmPassword = !_obscureConfirmPassword;
                  });
                },
              ),
              filled: true,
              fillColor: Colors.white.withOpacity(0.05),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
              ),
            ),
            obscureText: _obscureConfirmPassword,
            validator: (value) {
              if (value == null || value.isEmpty)
                return 'Konfirmasi password wajib diisi';
              if (value != _passwordController.text)
                return 'Password tidak cocok';
              return null;
            },
          ),
          const SizedBox(height: 16),

          TextFormField(
            controller: _bioController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: 'Bio (Opsional)',
              labelStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
              hintText: 'Ceritakan tentang diri Anda...',
              hintStyle: TextStyle(color: Colors.white.withOpacity(0.4)),
              prefixIcon: Icon(
                Icons.info_outline,
                color: Colors.white.withOpacity(0.7),
              ),
              filled: true,
              fillColor: Colors.white.withOpacity(0.05),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
              ),
            ),
            maxLines: 4,
            maxLength: 500,
            textCapitalization: TextCapitalization.sentences,
          ),
        ],
      ),
    );
  }
}
