import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'dart:typed_data';

class ProofUploadDialog extends StatefulWidget {
  final Function(String fotoBase64, String? catatan) onUpload;

  const ProofUploadDialog({super.key, required this.onUpload});

  @override
  State<ProofUploadDialog> createState() => _ProofUploadDialogState();
}

class _ProofUploadDialogState extends State<ProofUploadDialog> {
  final _catatanController = TextEditingController();
  String? _fotoBase64;
  Uint8List? _imageBytes;
  bool _isLoading = false;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );

    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      setState(() {
        _imageBytes = bytes;
        _fotoBase64 = base64Encode(bytes);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Upload Bukti Pelaksanaan'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Upload foto sebagai bukti bahwa sesi barter telah dilaksanakan.',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),

            // Photo picker
            OutlinedButton.icon(
              onPressed: _pickImage,
              icon: const Icon(Icons.photo_library),
              label: Text(_fotoBase64 == null ? 'Pilih Foto' : 'Ganti Foto'),
            ),

            if (_imageBytes != null) ...[
              const SizedBox(height: 8),
              Container(
                height: 150,
                width: double.infinity,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.memory(_imageBytes!, fit: BoxFit.cover),
                ),
              ),
            ],

            const SizedBox(height: 16),

            // Notes
            TextField(
              controller: _catatanController,
              decoration: const InputDecoration(
                labelText: 'Catatan (Opsional)',
                hintText: 'Tambahkan catatan jika perlu',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        FilledButton(
          onPressed: _fotoBase64 == null || _isLoading
              ? null
              : () {
                  setState(() => _isLoading = true);
                  widget.onUpload(
                    _fotoBase64!,
                    _catatanController.text.trim().isEmpty
                        ? null
                        : _catatanController.text.trim(),
                  );
                },
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Upload'),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _catatanController.dispose();
    super.dispose();
  }
}
