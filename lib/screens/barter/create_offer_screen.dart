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
      appBar: AppBar(
        title: Text(isHelpRequest ? 'Minta Bantuan' : 'Buat Penawaran Barter'),
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Skills exchange preview (hide own skill for help requests)
            _buildSkillsPreview(),
            const SizedBox(height: 24),

            // Duration
            TextFormField(
              controller: _durationController,
              decoration: const InputDecoration(
                labelText: 'Durasi (jam)',
                prefixIcon: Icon(Icons.access_time),
                border: OutlineInputBorder(),
                helperText: 'Berapa lama sesi barter?',
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Durasi harus diisi';
                }
                final duration = int.tryParse(value);
                if (duration == null || duration <= 0) {
                  return 'Durasi harus lebih dari 0';
                }
                return null;
              },
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 16),

            // Date picker
            InkWell(
              onTap: _selectDate,
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Tanggal Pelaksanaan',
                  prefixIcon: Icon(Icons.calendar_today),
                  border: OutlineInputBorder(),
                ),
                child: Text(
                  _selectedDate != null
                      ? DateFormat('dd MMMM yyyy').format(_selectedDate!)
                      : 'Pilih tanggal',
                  style: TextStyle(
                    color: _selectedDate != null ? Colors.black : Colors.grey,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Time picker
            InkWell(
              onTap: _selectTime,
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Waktu Pelaksanaan',
                  prefixIcon: Icon(Icons.access_time),
                  border: OutlineInputBorder(),
                ),
                child: Text(
                  _selectedTime != null
                      ? _selectedTime!.format(context)
                      : 'Pilih waktu',
                  style: TextStyle(
                    color: _selectedTime != null ? Colors.black : Colors.grey,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Location type
            const Text(
              'Tipe Lokasi',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(
                  value: 'online',
                  label: Text('Online'),
                  icon: Icon(Icons.videocam),
                ),
                ButtonSegment(
                  value: 'offline',
                  label: Text('Offline'),
                  icon: Icon(Icons.location_on),
                ),
                ButtonSegment(
                  value: 'hybrid',
                  label: Text('Hybrid'),
                  icon: Icon(Icons.swap_horiz),
                ),
              ],
              selected: {_locationType},
              onSelectionChanged: (Set<String> newSelection) {
                setState(() {
                  _locationType = newSelection.first;
                });
              },
            ),
            const SizedBox(height: 16),

            // Location detail
            TextFormField(
              controller: _locationController,
              decoration: InputDecoration(
                labelText: _locationType == 'online'
                    ? 'Link Meeting (Google Meet, Zoom, dll)'
                    : 'Alamat Lokasi',
                prefixIcon: Icon(
                  _locationType == 'online' ? Icons.link : Icons.place,
                ),
                border: const OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16),

            // Notes
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Catatan Tambahan (Opsional)',
                prefixIcon: Icon(Icons.note),
                border: OutlineInputBorder(),
                helperText: 'Informasi tambahan untuk partner',
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 24),

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
            const SizedBox(height: 24),

            // Submit button
            Consumer<BarterProvider>(
              builder: (context, provider, child) {
                return ElevatedButton(
                  onPressed: provider.isLoading ? null : _submitOffer,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: provider.isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(
                          isHelpRequest
                              ? 'Kirim Permintaan Bantuan'
                              : 'Kirim Penawaran',
                          style: const TextStyle(fontSize: 16),
                        ),
                );
              },
            ),
          ],
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

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isHelpRequest ? 'Permintaan Bantuan' : 'Pertukaran Skill',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            // Only show own skill section for barter
            if (!isHelpRequest) ...[
              Row(
                children: [
                  // Own skill
                  Expanded(
                    child: GestureDetector(
                      onTap: canSelectSkill ? _showSkillSelectionDialog : null,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: canSelectSkill
                              ? Colors.blue.shade50
                              : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: canSelectSkill
                                ? Colors.blue.shade200
                                : Colors.grey.shade300,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Anda Tawarkan',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    ownSkillName,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                      color: ownSkillName == 'Pilih skill Anda'
                                          ? Colors.grey[600]
                                          : Colors.black87,
                                    ),
                                  ),
                                ),
                                if (canSelectSkill)
                                  const Icon(
                                    Icons.arrow_drop_down,
                                    color: Colors.blue,
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Icon(Icons.swap_horiz, color: Colors.blue),
                  const SizedBox(width: 12),
                  // Requested skill
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Anda Minta',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.targetSkillName ?? 'Skill partner',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],

            // For help request, show only requested skill
            if (isHelpRequest)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Skill yang Diminta',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.targetSkillName ?? 'Skill partner',
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

  Future<void> _submitOffer() async {
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

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    final success = await provider.createOffer(offer);

    // Close loading
    if (mounted) Navigator.of(context).pop();

    if (!mounted) return;

    if (success) {
      BeautifulNotification.show(
        context,
        title: 'Berhasil!',
        message: _tipeTransaksi == 'bantuan'
            ? 'Permintaan bantuan berhasil dikirim!'
            : 'Penawaran barter berhasil dikirim!',
        type: NotificationType.success,
      );

      // Delay to show notification before closing screen
      await Future.delayed(const Duration(milliseconds: 1500));

      if (mounted) Navigator.pop(context);
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

        // Show selection dialog
        final selected = await showDialog<Map<String, dynamic>>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Pilih Skill Anda'),
            content: SizedBox(
              width: double.maxFinite,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: skills.length,
                itemBuilder: (context, index) {
                  final skill = skills[index];
                  return ListTile(
                    title: Text(skill['nama']),
                    subtitle: Text('${skill['harga']} SC/jam'),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () => Navigator.pop(context, skill),
                  );
                },
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Batal'),
              ),
            ],
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
