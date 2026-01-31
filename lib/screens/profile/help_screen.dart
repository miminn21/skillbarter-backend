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

class _HelpScreenState extends State<HelpScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _formKey = GlobalKey<FormState>();
  final _messageController = TextEditingController();
  XFile? _image; // Changed from File? to XFile? for Web support
  bool _isSubmitting = false;

  final List<Map<String, String>> _faqs = [
    {
      'question': 'Apa itu SkillCoin?',
      'answer':
          'SkillCoin adalah mata uang digital dalam aplikasi yang digunakan untuk membayar jasa atau memberikan apresiasi kepada partner barter.',
    },
    {
      'question': 'Bagaimana cara mendapatkan SkillCoin?',
      'answer':
          'Anda akan mendapatkan SkillCoin saat pertama kali mendaftar (Bonus), atau dengan menyelesaikan misi dan membantu orang lain.',
    },
    {
      'question': 'Apakah saya bisa membatalkan transaksi?',
      'answer':
          'Ya, selama status transaksi masih "Menunggu" atau "Berlangsung", Anda bisa membatalkannya. Namun koin mungkin akan dikembalikan atau hangus tergantung kondisi.',
    },
    {
      'question': 'Bagaimana sistem rating bekerja?',
      'answer':
          'Rating diberikan setelah transaksi selesai. Rating mempengaruhi reputasi Anda agar lebih dipercaya oleh pengguna lain.',
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => _image = picked);
    }
  }

  Future<void> _submitReport() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);

    try {
      final api = ApiService();

      // Prepare FormData
      Map<String, dynamic> formDataMap = {
        'deskripsi': _messageController.text,
        'jenis_laporan': 'lainnya',
      };

      if (_image != null) {
        if (kIsWeb) {
          // Web: Read bytes
          final bytes = await _image!.readAsBytes();
          formDataMap['bukti'] = MultipartFile.fromBytes(
            bytes,
            filename: _image!.name,
          );
        } else {
          // Mobile: Use path
          formDataMap['bukti'] = await MultipartFile.fromFile(_image!.path);
        }
      }

      FormData formData = FormData.fromMap(formDataMap);

      // Dio post automatically handles FormData content-type
      final response = await api.post('/help/submit', data: formData);

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (!mounted) return;
        CustomNotification.showSuccess(
          context,
          'Laporan terkirim! Terima kasih.',
        );
        _messageController.clear();
        setState(() => _image = null);
        _tabController.animateTo(0);
      }
    } catch (e) {
      if (!mounted) return;
      CustomNotification.showError(context, 'Gagal mengirim laporan: $e');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bantuan'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'FAQ'),
            Tab(text: 'Hubungi Kami'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildFAQList(), _buildContactForm()],
      ),
    );
  }

  Widget _buildFAQList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _faqs.length,
      itemBuilder: (context, index) {
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ExpansionTile(
            title: Text(
              _faqs[index]['question']!,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Text(_faqs[index]['answer']!),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildContactForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Ada masalah atau saran? Tuliskan di sini.',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _messageController,
              maxLines: 5,
              decoration: InputDecoration(
                hintText: 'Jelaskan masalah Anda...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[50],
              ),
              validator: (v) => v!.isEmpty ? 'Wajib diisi' : null,
            ),
            const SizedBox(height: 16),

            // Image Picker
            InkWell(
              onTap: _pickImage,
              child: Container(
                height: 150,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.grey[100],
                ),
                child: _image == null
                    ? const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.add_photo_alternate,
                            size: 40,
                            color: Colors.grey,
                          ),
                          Text(
                            'Sertakan Screenshot (Opsional)',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      )
                    : Stack(
                        fit: StackFit.expand,
                        children: [
                          kIsWeb
                              ? Image.network(_image!.path, fit: BoxFit.cover)
                              : Image.file(
                                  File(_image!.path),
                                  fit: BoxFit.cover,
                                ),
                          Positioned(
                            right: 8,
                            top: 8,
                            child: CircleAvatar(
                              backgroundColor: Colors.white,
                              child: IconButton(
                                icon: const Icon(
                                  Icons.close,
                                  color: Colors.red,
                                ),
                                onPressed: () => setState(() => _image = null),
                              ),
                            ),
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 24),

            ElevatedButton(
              onPressed: _isSubmitting ? null : _submitReport,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isSubmitting
                  ? const CircularProgressIndicator()
                  : const Text(
                      'Kirim Laporan',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
