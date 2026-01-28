import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../providers/skill_provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/skill_service.dart';
import '../../models/skill_model.dart';
import '../barter/create_offer_screen.dart';
import 'edit_skill_screen.dart';

class SkillDetailScreen extends StatefulWidget {
  final int skillId;

  const SkillDetailScreen({super.key, required this.skillId});

  @override
  State<SkillDetailScreen> createState() => _SkillDetailScreenState();
}

class _SkillDetailScreenState extends State<SkillDetailScreen> {
  final SkillService _skillService = SkillService();
  SkillModel? _skill;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadSkillDetail();
  }

  Future<void> _loadSkillDetail() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final response = await _skillService.getSkillDetail(widget.skillId);

    if (response.success && response.data != null) {
      setState(() {
        _skill = response.data;
        _isLoading = false;
      });
    } else {
      setState(() {
        _error = response.message;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Detail Skill')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null || _skill == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Detail Skill')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(_error ?? 'Skill tidak ditemukan'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Kembali'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Skill'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EditSkillScreen(skill: _skill!),
                ),
              );

              if (result == true) {
                _loadSkillDetail();
              }
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadSkillDetail,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Theme.of(
                                context,
                              ).colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              _getCategoryIcon(_skill!.kategoriIkon),
                              size: 32,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _skill!.namaKeahlian,
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _skill!.namaKategori ?? '',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (_skill!.statusVerifikasi)
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.green[100],
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.verified,
                                color: Colors.green[700],
                                size: 24,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Tags
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _buildChip(
                            _skill!.tipe == 'dikuasai' ? 'Dikuasai' : 'Dicari',
                            _skill!.tipe == 'dikuasai'
                                ? Colors.blue
                                : Colors.orange,
                          ),
                          _buildChip(
                            _getTingkatLabel(_skill!.tingkat),
                            _getTingkatColor(_skill!.tingkat),
                          ),
                          _buildChip(
                            '${_skill!.hargaPerJam} SC/jam',
                            Colors.amber,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Portfolio Image
              if (_skill!.portofolioGambar != null) ...[
                Card(
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          'Portfolio',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                      Image.memory(
                        base64Decode(_skill!.portofolioGambar!),
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Info Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Informasi',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),

                      if (_skill!.pengalaman != null) ...[
                        _buildInfoRow(
                          Icons.work,
                          'Pengalaman',
                          _skill!.pengalaman!,
                        ),
                        const Divider(height: 24),
                      ],

                      if (_skill!.deskripsi != null &&
                          _skill!.deskripsi!.isNotEmpty) ...[
                        _buildInfoRow(
                          Icons.description,
                          'Deskripsi',
                          _skill!.deskripsi!,
                        ),
                        const Divider(height: 24),
                      ],

                      if (_skill!.linkPortofolio != null &&
                          _skill!.linkPortofolio!.isNotEmpty) ...[
                        _buildInfoRow(
                          Icons.link,
                          'Link Portfolio',
                          _skill!.linkPortofolio!,
                          isLink: true,
                        ),
                        const Divider(height: 24),
                      ],

                      _buildInfoRow(
                        Icons.person,
                        'Pemilik',
                        _skill!.namaPemilik ?? 'Unknown',
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Verify Skill Button (for other users)
              if (_skill!.nikPengguna !=
                      context.read<AuthProvider>().user?.nik &&
                  !_skill!.statusVerifikasi)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _confirmVerifySkill,
                    icon: const Icon(Icons.verified_user),
                    label: const Text('Verifikasi Skill (10 SC)'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),

              // Upload Portfolio Button (for owner)
              if (_skill!.nikPengguna == context.read<AuthProvider>().user?.nik)
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _uploadPortfolio,
                    icon: const Icon(Icons.upload_file),
                    label: const Text('Upload Portfolio'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),

              const SizedBox(height: 8),

              // Delete Button
              if (_skill!.nikPengguna == context.read<AuthProvider>().user?.nik)
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _confirmDelete,
                    icon: const Icon(Icons.delete),
                    label: const Text('Hapus Skill'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildActionButtons(),
    );
  }

  Widget _buildChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          color: color.withOpacity(0.8),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    IconData icon,
    String label,
    String value, {
    bool isLink = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  color: isLink ? Colors.blue : Colors.black87,
                  decoration: isLink ? TextDecoration.underline : null,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  IconData _getCategoryIcon(String? icon) {
    switch (icon) {
      case 'computer':
        return Icons.computer;
      case 'palette':
        return Icons.palette;
      case 'language':
        return Icons.language;
      case 'music_note':
        return Icons.music_note;
      default:
        return Icons.star;
    }
  }

  String _getTingkatLabel(String tingkat) {
    switch (tingkat) {
      case 'pemula':
        return 'Pemula';
      case 'menengah':
        return 'Menengah';
      case 'mahir':
        return 'Mahir';
      case 'ahli':
        return 'Ahli';
      default:
        return tingkat;
    }
  }

  Color _getTingkatColor(String tingkat) {
    switch (tingkat) {
      case 'pemula':
        return Colors.blue;
      case 'menengah':
        return Colors.green;
      case 'mahir':
        return Colors.orange;
      case 'ahli':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Skill'),
        content: Text(
          'Apakah Anda yakin ingin menghapus "${_skill!.namaKeahlian}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final skillProvider = context.read<SkillProvider>();
      final success = await skillProvider.deleteSkill(_skill!.id);

      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Skill berhasil dihapus'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(skillProvider.error ?? 'Gagal menghapus skill'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _confirmVerifySkill() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Verifikasi Skill'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Verifikasi skill "${_skill!.namaKeahlian}"?'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.amber[700]),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Biaya verifikasi: 10 SkillCoin',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('Verifikasi'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      setState(() => _isLoading = true);

      final response = await _skillService.verifySkill(_skill!.id);

      if (!mounted) return;

      setState(() => _isLoading = false);

      // Show beautiful dialog instead of SnackBar
      if (response.success) {
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Success Icon
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.check_circle,
                      color: Colors.green.shade600,
                      size: 64,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Title
                  const Text(
                    'Verifikasi Berhasil!',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),

                  // Message
                  Text(
                    'Skill "${_skill!.namaKeahlian}" berhasil diverifikasi',
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),

                  // Skillcoin info
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.amber.shade200),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.monetization_on,
                          color: Colors.amber.shade700,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '10 SkillCoin telah dipotong',
                          style: TextStyle(
                            color: Colors.amber.shade900,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // OK Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'OK',
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
        );
        _loadSkillDetail();
      } else {
        // Show error dialog
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Error Icon
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.error_outline,
                      color: Colors.red.shade600,
                      size: 64,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Title
                  const Text(
                    'Verifikasi Gagal',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),

                  // Error Message
                  Text(
                    response.message,
                    style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),

                  // Skillcoin info if insufficient balance
                  if (response.message.contains('tidak cukup'))
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.orange.shade200),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: Colors.orange.shade700,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Anda memerlukan 10 SkillCoin untuk verifikasi',
                              style: TextStyle(
                                color: Colors.orange.shade900,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 24),

                  // OK Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'OK',
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
        );
      }
    }
  }

  Future<void> _uploadPortfolio() async {
    // Note: Image picker requires adding image_picker package
    // For now, show a message that this feature requires image picker
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Upload portfolio memerlukan image_picker package. '
          'Fitur ini akan tersedia setelah package ditambahkan.',
        ),
        duration: Duration(seconds: 3),
      ),
    );

    // TODO: Implement image picker
    // final ImagePicker picker = ImagePicker();
    // final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    //
    // if (image != null && mounted) {
    //   setState(() => _isLoading = true);
    //
    //   final skillProvider = context.read<SkillProvider>();
    //   final success = await skillProvider.uploadPortfolio(_skill!.id, image.path);
    //
    //   if (!mounted) return;
    //
    //   setState(() => _isLoading = false);
    //
    //   if (success) {
    //     ScaffoldMessenger.of(context).showSnackBar(
    //       const SnackBar(
    //         content: Text('Portfolio berhasil diupload'),
    //         backgroundColor: Colors.green,
    //       ),
    //     );
    //     _loadSkillDetail();
    //   } else {
    //     ScaffoldMessenger.of(context).showSnackBar(
    //       SnackBar(
    //         content: Text(skillProvider.error ?? 'Gagal upload portfolio'),
    //         backgroundColor: Colors.red,
    //       ),
    //     );
    //   }
    // }\r
  }

  Widget? _buildActionButtons() {
    final authProvider = context.read<AuthProvider>();

    // Don't show buttons for own skills
    if (_skill!.nikPengguna == authProvider.user?.nik) {
      return null;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CreateOfferScreen(
                    targetNik: _skill!.nikPengguna,
                    targetSkillId: _skill!.id,
                    targetSkillName: _skill!.namaKeahlian,
                    ownSkillId:
                        0, // Placeholder to trigger barter mode (user will select)
                  ),
                ),
              ),
              icon: const Icon(Icons.swap_horiz),
              label: const Text('Tukar Skill'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () {
                final cost = _skill!.hargaPerJam * 2;
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Minta Bantuan'),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Skill: ${_skill!.namaKeahlian}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text('Harga: ${_skill!.hargaPerJam} SC/jam'),
                        Text('Estimasi (2 jam): $cost SC'),
                        const SizedBox(height: 16),
                        Text(
                          'Anda akan membayar dengan SkillCoin tanpa perlu menawarkan skill Anda.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Batal'),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => CreateOfferScreen(
                                targetNik: _skill!.nikPengguna,
                                targetSkillId: _skill!.id,
                                targetSkillName: _skill!.namaKeahlian,
                                ownSkillId: null,
                              ),
                            ),
                          );
                        },
                        child: const Text('Lanjutkan'),
                      ),
                    ],
                  ),
                );
              },
              icon: const Icon(Icons.help_outline),
              label: const Text('Minta Bantuan'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
