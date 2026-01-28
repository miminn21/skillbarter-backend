import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/profile_service.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _profileService = ProfileService();

  late TextEditingController _namaPanggilanController;
  late TextEditingController _bioController;
  late TextEditingController _pekerjaanController;
  late TextEditingController _namaInstansiController;
  late TextEditingController _pendidikanController;
  late TextEditingController _bahasaController;

  String _preferensiLokasi = 'keduanya';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().user;

    _namaPanggilanController = TextEditingController(text: user?.namaPanggilan);
    _bioController = TextEditingController(text: user?.bio);
    _pekerjaanController = TextEditingController(text: user?.pekerjaan);
    _namaInstansiController = TextEditingController(text: user?.namaInstansi);
    _pendidikanController = TextEditingController(
      text: user?.pendidikanTerakhir,
    );
    _bahasaController = TextEditingController(text: user?.bahasa);
    _preferensiLokasi = user?.preferensiLokasi ?? 'keduanya';
  }

  @override
  void dispose() {
    _namaPanggilanController.dispose();
    _bioController.dispose();
    _pekerjaanController.dispose();
    _namaInstansiController.dispose();
    _pendidikanController.dispose();
    _bahasaController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await _profileService.updateProfile({
        'nama_panggilan': _namaPanggilanController.text.trim(),
        'bio': _bioController.text.trim().isEmpty
            ? null
            : _bioController.text.trim(),
        'pekerjaan': _pekerjaanController.text.trim().isEmpty
            ? null
            : _pekerjaanController.text.trim(),
        'nama_instansi': _namaInstansiController.text.trim().isEmpty
            ? null
            : _namaInstansiController.text.trim(),
        'pendidikan_terakhir': _pendidikanController.text.trim().isEmpty
            ? null
            : _pendidikanController.text.trim(),
        'bahasa': _bahasaController.text.trim().isEmpty
            ? null
            : _bahasaController.text.trim(),
        'preferensi_lokasi': _preferensiLokasi,
      });

      if (!mounted) return;

      if (response.success) {
        // Reload profile
        await context.read<AuthProvider>().loadProfile();

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profil berhasil diperbarui'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response.message),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profil'),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _handleSave,
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Simpan'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _namaPanggilanController,
              decoration: const InputDecoration(
                labelText: 'Nama Panggilan',
                prefixIcon: Icon(Icons.person_outline),
              ),
              textCapitalization: TextCapitalization.words,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Nama panggilan wajib diisi';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _bioController,
              decoration: const InputDecoration(
                labelText: 'Bio',
                hintText: 'Ceritakan tentang diri Anda...',
                prefixIcon: Icon(Icons.info_outline),
              ),
              maxLines: 4,
              maxLength: 500,
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _pekerjaanController,
              decoration: const InputDecoration(
                labelText: 'Pekerjaan',
                prefixIcon: Icon(Icons.work_outline),
              ),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _namaInstansiController,
              decoration: const InputDecoration(
                labelText: 'Nama Instansi',
                prefixIcon: Icon(Icons.business),
              ),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _pendidikanController,
              decoration: const InputDecoration(
                labelText: 'Pendidikan Terakhir',
                prefixIcon: Icon(Icons.school),
              ),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _bahasaController,
              decoration: const InputDecoration(
                labelText: 'Bahasa',
                hintText: 'Indonesia, English',
                prefixIcon: Icon(Icons.language),
              ),
            ),
            const SizedBox(height: 16),

            DropdownButtonFormField<String>(
              value: _preferensiLokasi,
              decoration: const InputDecoration(
                labelText: 'Preferensi Lokasi',
                prefixIcon: Icon(Icons.location_on),
              ),
              items: const [
                DropdownMenuItem(value: 'online', child: Text('Online')),
                DropdownMenuItem(value: 'offline', child: Text('Offline')),
                DropdownMenuItem(value: 'keduanya', child: Text('Keduanya')),
              ],
              onChanged: (value) {
                setState(() {
                  _preferensiLokasi = value!;
                });
              },
            ),
          ],
        ),
      ),
    );
  }
}
