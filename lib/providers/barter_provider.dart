import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import '../models/barter_offer.dart';
import '../models/skillcoin_transaction.dart';
import '../models/confirmation_model.dart';
import '../services/barter_service.dart';

class BarterProvider with ChangeNotifier {
  BarterService _service;

  BarterProvider(this._service);

  // State
  List<BarterOffer> _sentOffers = [];
  List<BarterOffer> _receivedOffers = [];
  List<BarterOffer> _history = [];
  BarterOffer? _selectedOffer;
  int _skillcoinBalance = 0;
  List<SkillcoinTransaction> _skillcoinHistory = [];
  SkillcoinStatistics? _skillcoinStats;
  List<ConfirmationModel> _confirmations = [];
  bool _isLoading = false;
  bool _isUploadingProof = false;
  String? _error;

  // Getters
  List<BarterOffer> get sentOffers => _sentOffers;
  List<BarterOffer> get receivedOffers => _receivedOffers;
  List<BarterOffer> get history => _history;
  BarterOffer? get selectedOffer => _selectedOffer;
  int get skillcoinBalance => _skillcoinBalance;
  List<SkillcoinTransaction> get skillcoinHistory => _skillcoinHistory;
  SkillcoinStatistics? get skillcoinStats => _skillcoinStats;
  List<ConfirmationModel> get confirmations => _confirmations;
  bool get isLoading => _isLoading;
  bool get isUploadingProof => _isUploadingProof;
  String? get error => _error;

  // Create offer
  Future<bool> createOffer(BarterOffer offer) async {
    print('[BarterProvider] Creating offer...');
    print('[BarterProvider] Target NIK: ${offer.nikDitawar}');
    print('[BarterProvider] Own Skill: ${offer.idKeahlianPenawar}');
    print('[BarterProvider] Target Skill: ${offer.idKeahlianDiminta}');
    print('[BarterProvider] Duration: ${offer.durasiJam} hours');
    print('[BarterProvider] Date: ${offer.tanggalPelaksanaan}');

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final newOffer = await _service.createOffer(offer);
      print('[BarterProvider] Offer created successfully! ID: ${newOffer.id}');

      _sentOffers.insert(0, newOffer);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      print('[BarterProvider] Error creating offer: $e');
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Fetch sent offers
  Future<void> fetchSentOffers({String? status}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _sentOffers = await _service.getUserOffers(role: 'sent', status: status);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Fetch received offers
  Future<void> fetchReceivedOffers({String? status}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _receivedOffers = await _service.getUserOffers(
        role: 'received',
        status: status,
      );
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Fetch received offers excluding rejected (ditolak)
  Future<void> fetchReceivedOffersExcludingRejected({String? status}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Fetch all received offers
      final allReceived = await _service.getUserOffers(
        role: 'received',
        status: status,
      );

      // Filter out ditolak status
      _receivedOffers = allReceived
          .where((offer) => offer.status != 'ditolak')
          .toList();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Fetch all rejected offers (both sent and received)
  Future<void> fetchAllRejectedOffers() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Fetch all offers with status ditolak
      final allOffers = await _service.getUserOffers(status: 'ditolak');

      // Store in receivedOffers for display in rejected tab
      _receivedOffers = allOffers;

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Fetch all offers
  Future<void> fetchAllOffers() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final allOffers = await _service.getUserOffers();
      _sentOffers = allOffers.where((o) => o.role == 'sent').toList();
      _receivedOffers = allOffers.where((o) => o.role == 'received').toList();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Fetch offer detail
  Future<void> fetchOfferDetail(int id, {String? currentUserNik}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      var offer = await _service.getOfferDetail(id);

      // Calculate role if current user NIK is provided
      if (currentUserNik != null) {
        String role = 'unknown';
        String? namaPartner;
        String? fotoPartner;
        String? skillPartner;
        String? skillOwn;

        if (offer.nikPenawar == currentUserNik) {
          role = 'sent';
          namaPartner = offer.namaDitawar;
          fotoPartner = offer.fotoDitawar;
          skillPartner = offer.skillDiminta;
          skillOwn = offer.skillPenawar;
        } else if (offer.nikDitawar == currentUserNik) {
          role = 'received';
          namaPartner = offer.namaPenawar;
          fotoPartner = offer.fotoPenawar;
          skillPartner = offer.skillPenawar;
          skillOwn = offer.skillDiminta;
        }

        offer = offer.copyWith(
          role: role,
          namaPartner: namaPartner,
          fotoPartner: fotoPartner,
          skillPartner: skillPartner,
          skillOwn: skillOwn,
        );
      }

      _selectedOffer = offer;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Accept offer
  Future<bool> acceptOffer(int id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final updatedOffer = await _service.acceptOffer(id);
      _updateOfferInLists(updatedOffer);
      _selectedOffer = updatedOffer;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Reject offer
  Future<bool> rejectOffer(int id, {String? reason}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final updatedOffer = await _service.rejectOffer(id, reason: reason);
      _updateOfferInLists(updatedOffer);
      _selectedOffer = updatedOffer;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Cancel offer
  Future<bool> cancelOffer(int id, {String? reason}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final updatedOffer = await _service.cancelOffer(id, reason: reason);
      _updateOfferInLists(updatedOffer);
      _selectedOffer = updatedOffer;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Delete offer (permanent)
  Future<bool> deleteOffer(int id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _service.deleteOffer(id);

      // Remove from lists
      _sentOffers.removeWhere((o) => o.id == id);
      _receivedOffers.removeWhere((o) => o.id == id);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Start session
  Future<bool> startSession(int id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final updatedOffer = await _service.startSession(id);
      _updateOfferInLists(updatedOffer);
      _selectedOffer = updatedOffer;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Complete session
  Future<bool> completeSession(int id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final updatedOffer = await _service.completeSession(id);
      _updateOfferInLists(updatedOffer);
      _selectedOffer = updatedOffer;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Fetch history
  Future<void> fetchHistory() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _history = await _service.getHistory();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Fetch skillcoin balance
  Future<void> fetchSkillcoinBalance() async {
    try {
      _skillcoinBalance = await _service.getSkillcoinBalance();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  // Fetch skillcoin history
  Future<void> fetchSkillcoinHistory() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _skillcoinHistory = await _service.getSkillcoinHistory();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Helper: Update offer in lists
  void _updateOfferInLists(BarterOffer updatedOffer) {
    final sentIndex = _sentOffers.indexWhere((o) => o.id == updatedOffer.id);
    if (sentIndex != -1) {
      _sentOffers[sentIndex] = updatedOffer;
    }

    final receivedIndex = _receivedOffers.indexWhere(
      (o) => o.id == updatedOffer.id,
    );
    if (receivedIndex != -1) {
      _receivedOffers[receivedIndex] = updatedOffer;
    }
  }

  // Update service (for ProxyProvider)
  void updateService(BarterService newService) {
    _service = newService;
    // No need to notify listeners as this happens before any UI updates
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Clear selected offer
  void clearSelectedOffer() {
    _selectedOffer = null;
    notifyListeners();
  }

  // Fetch proof of completion
  Future<Map<String, dynamic>?> fetchProof(int id) async {
    try {
      return await _service.getProof(id);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  /// Upload proof photo
  Future<bool> uploadProof(
    int offerId,
    String fotoBase64,
    String? catatan,
  ) async {
    _isUploadingProof = true;
    _error = null;
    notifyListeners();

    try {
      await _service.uploadProof(offerId, fotoBase64, catatan);

      // Reload confirmations
      await loadConfirmations(offerId);

      _isUploadingProof = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isUploadingProof = false;
      notifyListeners();
      return false;
    }
  }

  /// Confirm completion
  Future<bool> confirmCompletion(int offerId, String? catatan) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _service.confirmCompletion(offerId, catatan);

      // Refresh offer detail and confirmations
      await Future.wait([
        fetchOfferDetail(offerId),
        loadConfirmations(offerId),
      ]);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Load confirmations
  Future<void> loadConfirmations(int offerId) async {
    try {
      _confirmations = await _service.getConfirmationsList(offerId);
      notifyListeners();
    } catch (e) {
      print('[BarterProvider] Error loading confirmations: $e');
      // Don't set error, this is not critical
    }
  }
}
