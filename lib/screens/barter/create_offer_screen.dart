import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../models/barter_offer.dart';
import '../../providers/barter_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/skillcoin_calculator.dart';
import '../../widgets/help_request_cost_calculator.dart';
import '../../widgets/beautiful_notification.dart';
import '../../services/api_service.dart';

class CreateOfferScreen extends StatefulWidget {
  final String? targetNik;
  final int? targetSkillId;
  final int? ownSkillId;
  final int? skillRequestId;
  final String? targetSkillName;
  final String? ownSkillName;
  final int? suggestedDuration;
  final String? suggestedLocation;

  const CreateOfferScreen({
    Key? key,
    this.targetNik,
    this.targetSkillId,
    this.ownSkillId,
    this.skillRequestId,
    this.targetSkillName,
    this.ownSkillName,
    this.suggestedDuration,
    this.suggestedLocation,
  }) : super(key: key);

  @override
  State<CreateOfferScreen> createState() => _CreateOfferScreenState();
}

class _CreateOfferScreenState extends State<CreateOfferScreen> {
  final _formKey = GlobalKey<FormState>();

  // Form fields
  late TextEditingController _durationController;
  late TextEditingController _locationController;
  late TextEditingController _notesController;

  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  String _locationType = 'online';
  String _tipeTransaksi = 'barter'; // NEW: Transaction type

  // Skill prices (should be fetched from API)
  int _ownSkillPrice = 5;
  int _targetSkillPrice = 3;

  // Selected skills (for when user picks from dialog)
  int? _selectedOwnSkillId;
  String? _selectedOwnSkillName;

  @override
  void initState() {
    super.initState();

    // Detect transaction type: bantuan if no own skill, barter otherwise
    _tipeTransaksi = widget.ownSkillId == null ? 'bantuan' : 'barter';

    _durationController = TextEditingController(
      text: widget.suggestedDuration?.toString() ?? '2',
    );
    _locationController = TextEditingController(
      text: widget.suggestedLocation ?? '',
    );
    _notesController = TextEditingController();

    // Fetch real skill prices
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchSkillPrices();
    });
  }

  Future<void> _fetchSkillPrices() async {
    try {
      final api = ApiService();

      // Fetch target skill price
      if (widget.targetSkillId != null) {
        final response = await api.get('/skills/${widget.targetSkillId}');
        if (response.statusCode == 200) {
          final data = response.data['data'];
          if (mounted) {
            setState(() {
              _targetSkillPrice = data['harga_per_jam'] ?? 1;
            });
          }
        }
      }

      // Fetch own skill price
      if (widget.ownSkillId != null) {
        final response = await api.get('/skills/${widget.ownSkillId}');
        if (response.statusCode == 200) {
          final data = response.data['data'];
          if (mounted) {
            setState(() {
              _ownSkillPrice = data['harga_per_jam'] ?? 1;
            });
          }
        }
      }
    } catch (e) {
      print('Error fetching skill prices: $e');
    }
  }

  @override
  void dispose() {
    _durationController.dispose();
    _locationController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isHelpRequest = _tipeTransaksi == 'bantuan';

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        iconTheme: const IconThemeData(
          color: Colors.white,
        ), // Back button white
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Theme.of(context).primaryColor,
                const Color(0xFF1E88E5), // Lighter blue
              ],
            ),
          ),
        ),
        title: Text(
          isHelpRequest ? 'Minta Bantuan' : 'Buat Penawaran',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          children: [
            // Skills exchange preview (hide own skill for help requests)
            _buildSkillsPreview(),
            const SizedBox(height: 32),

            _buildSectionTitle('Detail Sesi'),
            const SizedBox(height: 16),

            // Duration
            Container(
              decoration: _inputDecoration(),
              child: TextFormField(
                controller: _durationController,
                decoration: _inputFieldDecoration(
                  'Durasi (jam)',
                  Icons.timer_rounded,
                  helperText: 'Berapa lama sesi barter?',
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Wajib diisi';
                  final duration = int.tryParse(value);
                  if (duration == null || duration <= 0) {
                    return 'Min. 1 jam';
                  }
                  return null;
                },
                onChanged: (_) => setState(() {}),
              ),
            ),
            const SizedBox(height: 16),

            // Date & Time Row
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: _selectDate,
                    child: Container(
                      decoration: _inputDecoration(),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.calendar_today_rounded,
                            color: Theme.of(context).primaryColor,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Tanggal',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _selectedDate != null
                                      ? DateFormat(
                                          'dd MMM yyyy',
                                        ).format(_selectedDate!)
                                      : 'Pilih Tgl',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: InkWell(
                    onTap: _selectTime,
                    child: Container(
                      decoration: _inputDecoration(),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.access_time_rounded,
                            color: Theme.of(context).primaryColor,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Waktu',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _selectedTime != null
                                      ? _selectedTime!.format(context)
                                      : 'Pilih Jam',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            _buildSectionTitle('Lokasi & Preferensi'),
            const SizedBox(height: 16),

            // Location type
            LayoutBuilder(
              builder: (context, constraints) {
                return Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      _buildLocationOption(
                        'Online',
                        'online',
                        Icons.videocam_rounded,
                      ),
                      _buildLocationOption(
                        'Offline',
                        'offline',
                        Icons.location_on_rounded,
                      ),
                      _buildLocationOption(
                        'Hybrid',
                        'hybrid',
                        Icons.swap_horiz_rounded,
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 16),

            // Location detail
            Container(
              decoration: _inputDecoration(),
              child: TextFormField(
                controller: _locationController,
                decoration: _inputFieldDecoration(
                  _locationType == 'online'
                      ? 'Link Meeting (Zoom/GMeet)'
                      : 'Alamat Lengkap',
                  _locationType == 'online'
                      ? Icons.link_rounded
                      : Icons.map_rounded,
                ),
                maxLines: 2,
              ),
            ),
            const SizedBox(height: 16),

            // Notes
            Container(
              decoration: _inputDecoration(),
              child: TextFormField(
                controller: _notesController,
                decoration: _inputFieldDecoration(
                  'Catatan (Opsional)',
                  Icons.note_alt_rounded,
                  helperText: 'Info tambahan untuk partner',
                ),
                maxLines: 3,
              ),
            ),
            const SizedBox(height: 32),

            // Skillcoin calculator (conditional based on mode)
            if (_durationController.text.isNotEmpty &&
                int.tryParse(_durationController.text) != null) ...[
              if (isHelpRequest)
                // Help request: show simple cost calculator
                HelpRequestCostCalculator(
                  durasiJam: int.parse(_durationController.text),
                  hargaPerJam: _targetSkillPrice,
                  skillDiminta: widget.targetSkillName ?? 'Skill Partner',
                )
              else
                // Barter: show full skillcoin calculator
                SkillcoinCalculator(
                  durasiJam: int.parse(_durationController.text),
                  hargaPerJamAnda: _ownSkillPrice,
                  hargaPerJamPartner: _targetSkillPrice,
                  skillAnda: widget.ownSkillName ?? 'Skill Anda',
                  skillPartner: widget.targetSkillName ?? 'Skill Partner',
                ),
            ],
            const SizedBox(height: 32),

            // Submit button with Animation
            Consumer<BarterProvider>(
              builder: (context, provider, child) {
                return GestureDetector(
                  onTap: (provider.isLoading || _isAnimating || _isSent)
                      ? null
                      : _animateAndSubmit, // Use updated method
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
                        // Default State
                        if (!provider.isLoading && !_isAnimating && !_isSent)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                isHelpRequest
                                    ? Icons
                                          .send_rounded // Paper plane
                                    : Icons
                                          .handshake_rounded, // Handshake for Barter
                                color: Colors.white,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                isHelpRequest
                                    ? 'Kirim Permintaan'
                                    : 'Kirim Penawaran',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),

                        // Loading State (Provider)
                        if (provider.isLoading)
                          const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          ),

                        // Animation State (Paper Plane Flying)
                        if (_isAnimating)
                          Transform.translate(
                            offset: Offset(_planePosition, 0),
                            child: Icon(
                              isHelpRequest
                                  ? Icons.send_rounded
                                  : Icons.handshake_rounded,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),

                        // Success State
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
                                'Berhasil Dikirim',
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
                );
              },
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Color(0xFF2D3142),
      ),
    );
  }

  BoxDecoration _inputDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.04),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  InputDecoration _inputFieldDecoration(
    String label,
    IconData icon, {
    String? helperText,
  }) {
    return InputDecoration(
      labelText: label,
      helperText: helperText,
      prefixIcon: Icon(icon, color: Colors.grey[400]),
      border: InputBorder.none,
      contentPadding: const EdgeInsets.all(20),
      labelStyle: TextStyle(color: Colors.grey[600]),
    );
  }

  Widget _buildLocationOption(String label, String value, IconData icon) {
    final isSelected = _locationType == value;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _locationType = value;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: isSelected ? Theme.of(context).primaryColor : Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Theme.of(context).primaryColor.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [],
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: isSelected ? Colors.white : Colors.grey[400],
                size: 20,
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.grey[600],
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSkillsPreview() {
    final isHelpRequest = _tipeTransaksi == 'bantuan';

    // Use selected skill if available, otherwise use widget param
    final ownSkillName =
        _selectedOwnSkillName ?? widget.ownSkillName ?? 'Pilih skill Anda';
    final canSelectSkill =
        !isHelpRequest && (widget.ownSkillId == null || widget.ownSkillId == 0);

    return Container(
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
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.swap_calls_rounded,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(width: 8),
                Text(
                  isHelpRequest ? 'Permintaan Bantuan' : 'Pertukaran Skill',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2D3142),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Help Request: Single Card
            if (isHelpRequest)
              _buildSkillCard(
                label: 'Skill yang Diminta',
                skillName: widget.targetSkillName ?? 'Skill Partner',
                icon: Icons.download_rounded,
                color: Colors.orange,
              ),

            // Barter: Dual Card
            if (!isHelpRequest) ...[
              _buildSkillCard(
                label: 'Anda Tawarkan',
                skillName: ownSkillName,
                icon: Icons.upload_rounded,
                color: Colors.green,
                onTap: canSelectSkill ? _showSkillSelectionDialog : null,
                isSelectable: canSelectSkill,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.swap_vert_rounded,
                      color: Colors.grey[400],
                      size: 20,
                    ),
                  ),
                ),
              ),
              _buildSkillCard(
                label: 'Anda Minta',
                skillName: widget.targetSkillName ?? 'Skill Partner',
                icon: Icons.download_rounded,
                color: Colors.orange,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSkillCard({
    required String label,
    required String skillName,
    required IconData icon,
    required Color color,
    VoidCallback? onTap,
    bool isSelectable = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.2), width: 1.5),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          skillName,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: const Color(0xFF2D3142),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isSelectable)
                        Icon(
                          Icons.arrow_drop_down_circle_outlined,
                          size: 18,
                          color: color,
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  // Animation State
  bool _isAnimating = false;
  bool _isSent = false;
  double _planePosition = 0.0;

  Future<void> _animateAndSubmit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Validate balance for help requests
    if (_tipeTransaksi == 'bantuan') {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final currentBalance = authProvider.user?.saldoSkillcoin ?? 0;
      final totalCost = int.parse(_durationController.text) * _targetSkillPrice;

      if (currentBalance < totalCost) {
        BeautifulNotification.show(
          context,
          title: 'Saldo Tidak Cukup!',
          message:
              'Dibutuhkan: $totalCost coin\nSaldo Anda: $currentBalance coin\nKurang: ${totalCost - currentBalance} coin',
          type: NotificationType.error,
          duration: const Duration(seconds: 4),
        );
        return;
      }
    }

    // Validate own skill selection (only for barter, not for help requests)
    if (_tipeTransaksi == 'barter') {
      final effectiveOwnSkillId = _selectedOwnSkillId ?? widget.ownSkillId;
      if (effectiveOwnSkillId == null) {
        BeautifulNotification.show(
          context,
          title: 'Skill Belum Dipilih',
          message:
              'Silakan pilih skill Anda terlebih dahulu untuk melakukan barter',
          type: NotificationType.warning,
        );
        return;
      }
    }

    if (_selectedDate == null || _selectedTime == null) {
      BeautifulNotification.show(
        context,
        title: 'Data Belum Lengkap',
        message: 'Silakan pilih tanggal dan waktu pelaksanaan terlebih dahulu',
        type: NotificationType.warning,
      );
      return;
    }

    // For help requests, ownSkillId can be null
    if (widget.targetNik == null || widget.targetSkillId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Data skill tidak lengkap'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // For barter mode, ownSkillId is required
    if (_tipeTransaksi == 'barter' && widget.ownSkillId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pilih skill Anda untuk barter'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Combine date and time
    final dateTime = DateTime(
      _selectedDate!.year,
      _selectedDate!.month,
      _selectedDate!.day,
      _selectedTime!.hour,
      _selectedTime!.minute,
    );

    final effectiveOwnSkillId = _selectedOwnSkillId ?? widget.ownSkillId;
    final scheduledDateTime = dateTime;

    final offer = BarterOffer(
      nikPenawar: '', // Will be set by backend from token
      nikDitawar: widget.targetNik!,
      idKeahlianPenawar: effectiveOwnSkillId,
      idKeahlianDiminta: widget.targetSkillId!,
      idSkillRequest: widget.skillRequestId,
      tipeTransaksi: _tipeTransaksi,
      durasiJam: int.parse(_durationController.text),
      tanggalPelaksanaan: scheduledDateTime,
      tipeLokasi: _locationType,
      detailLokasi: _locationController.text.trim().isEmpty
          ? null
          : _locationController.text.trim(),
      catatanPenawar: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
    );

    final provider = Provider.of<BarterProvider>(context, listen: false);

    // Call Provider (Provider handles loading state but doesn't show dialog)
    // Note: If the provider logic inside 'createOffer' sets isLoading=true,
    // the button will show the spinner automatically because it listens to provider.

    final success = await provider.createOffer(offer);

    if (!mounted) return;

    if (success) {
      // 1. Start Fly Animation
      setState(() {
        _isAnimating = true;
      });

      // 2. Fly plane to right (Animation Loop)
      for (int i = 0; i < 20; i++) {
        await Future.delayed(const Duration(milliseconds: 20));
        if (!mounted) return;
        setState(() {
          _planePosition += 20.0;
        });
      }

      // 3. Show Success Text
      setState(() {
        _isAnimating = false;
        _isSent = true;
      });

      // 4. Wait a bit then close screen
      await Future.delayed(const Duration(milliseconds: 1500));

      if (!mounted) return;

      Navigator.pop(context); // Close screen

      BeautifulNotification.show(
        context,
        title: 'Berhasil!',
        message: _tipeTransaksi == 'bantuan'
            ? 'Permintaan bantuan berhasil dikirim!'
            : 'Penawaran barter berhasil dikirim!',
        type: NotificationType.success,
      );
    } else {
      BeautifulNotification.show(
        context,
        title: 'Gagal!',
        message:
            provider.error ?? 'Gagal mengirim penawaran. Silakan coba lagi.',
        type: NotificationType.error,
      );
    }
  }

  Future<void> _showSkillSelectionDialog() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    // Fetch user's skills
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final response = await http.get(
        Uri.parse('${ApiService.baseUrl}/skills?tipe=dikuasai'),
        headers: {'Authorization': 'Bearer ${authProvider.token}'},
      );

      if (!mounted) return;
      Navigator.pop(context); // Close loading

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final skills = (data['data'] as List)
            .map(
              (json) => {
                'id': json['id'],
                'nama': json['nama_keahlian'],
                'harga': json['harga_per_jam'],
              },
            )
            .toList();

        if (skills.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Anda belum memiliki skill. Tambahkan skill terlebih dahulu.',
              ),
              backgroundColor: Colors.orange,
            ),
          );
          return;
        }

        // Show custom selection dialog
        final selected = await showDialog<Map<String, dynamic>>(
          context: context,
          builder: (context) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            elevation: 10,
            backgroundColor: Colors.white,
            child: Container(
              padding: const EdgeInsets.all(0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Dialog Header
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Theme.of(context).primaryColor,
                          const Color(0xFF1E88E5),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(24),
                        topRight: Radius.circular(24),
                      ),
                    ),
                    child: const Column(
                      children: [
                        Icon(
                          Icons.auto_awesome_rounded,
                          size: 48,
                          color: Colors.white,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Pilih Skill Anda',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Pilih skill yang ingin Anda tawarkan',
                          style: TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                      ],
                    ),
                  ),

                  // Skills List
                  Flexible(
                    child: Container(
                      constraints: const BoxConstraints(maxHeight: 300),
                      child: ListView.separated(
                        shrinkWrap: true,
                        padding: const EdgeInsets.all(16),
                        itemCount: skills.length,
                        separatorBuilder: (ctx, i) =>
                            const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final skill = skills[index];
                          return Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () => Navigator.pop(context, skill),
                              borderRadius: BorderRadius.circular(16),
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF8F9FD),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: Colors.grey.shade200,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(12),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black12,
                                            blurRadius: 4,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: Icon(
                                        Icons.star_rounded,
                                        color: Colors.orange.shade400,
                                        size: 24,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            skill['nama'],
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                              color: Color(0xFF2D3142),
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.green.shade50,
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              '${skill['harga']} SC/jam',
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.green.shade700,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Icon(
                                      Icons.arrow_forward_ios_rounded,
                                      size: 16,
                                      color: Colors.grey.shade400,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),

                  // Divider
                  const Divider(height: 1),

                  // Footer / Cancel
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: SizedBox(
                      width: double.infinity,
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Batal',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );

        if (selected != null) {
          setState(() {
            _selectedOwnSkillId = selected['id'];
            _selectedOwnSkillName = selected['nama'];
            _ownSkillPrice = selected['harga'];
          });
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gagal memuat skill Anda'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Close loading if still open
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }
}
