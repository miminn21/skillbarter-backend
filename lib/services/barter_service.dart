import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/barter_offer.dart';
import '../models/barter_confirmation_model.dart';
import '../models/skillcoin_transaction.dart';
import '../models/confirmation_model.dart';

class BarterService {
  final String baseUrl;
  final String Function() getToken;

  BarterService({required this.baseUrl, required this.getToken});

  /// Create new barter offer
  Future<BarterOffer> createOffer(BarterOffer offer) async {
    try {
      final token = getToken();
      final body = offer.toJson();

      print('[BarterService] Creating offer...');
      print(
        '[BarterService] Token: ${token.isNotEmpty ? "${token.substring(0, 10)}..." : "EMPTY"}',
      );
      print('[BarterService] Body: $body');

      final response = await http.post(
        Uri.parse('$baseUrl/barter/offers'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode(body),
      );

      print('[BarterService] Response status: ${response.statusCode}');
      print('[BarterService] Response body: ${response.body}');

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        print('[BarterService] Offer created successfully!');
        return BarterOffer.fromJson(data['data']);
      } else {
        final error = json.decode(response.body);
        print('[BarterService] Error: ${error['message']}');
        throw Exception(error['message'] ?? 'Failed to create offer');
      }
    } catch (e) {
      print('[BarterService] Exception: $e');
      throw Exception('Error creating offer: $e');
    }
  }

  /// Get user's offers
  Future<List<BarterOffer>> getUserOffers({
    String? role,
    String? status,
  }) async {
    try {
      final token = getToken();

      var url = '$baseUrl/barter/offers';
      final queryParams = <String>[];
      if (role != null) queryParams.add('role=$role');
      if (status != null) queryParams.add('status=$status');
      if (queryParams.isNotEmpty) url += '?${queryParams.join('&')}';

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> offersJson = data['data'];
        return offersJson.map((json) => BarterOffer.fromJson(json)).toList();
      } else {
        final error = json.decode(response.body);
        throw Exception(error['message'] ?? 'Failed to fetch offers');
      }
    } catch (e) {
      throw Exception('Error fetching offers: $e');
    }
  }

  /// Get offer detail
  Future<BarterOffer> getOfferDetail(int id) async {
    try {
      final token = getToken();

      final response = await http.get(
        Uri.parse('$baseUrl/barter/offers/$id'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return BarterOffer.fromJson(data['data']);
      } else {
        final error = json.decode(response.body);
        throw Exception(error['message'] ?? 'Failed to fetch offer detail');
      }
    } catch (e) {
      throw Exception('Error fetching offer detail: $e');
    }
  }

  /// Accept offer
  Future<BarterOffer> acceptOffer(int id) async {
    try {
      final token = getToken();

      final response = await http.put(
        Uri.parse('$baseUrl/barter/offers/$id/accept'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return BarterOffer.fromJson(data['data']);
      } else {
        final error = json.decode(response.body);
        throw Exception(error['message'] ?? 'Failed to accept offer');
      }
    } catch (e) {
      throw Exception('Error accepting offer: $e');
    }
  }

  /// Reject offer
  Future<BarterOffer> rejectOffer(int id, {String? reason}) async {
    try {
      final token = getToken();

      final response = await http.put(
        Uri.parse('$baseUrl/barter/offers/$id/reject'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({'reason': reason}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return BarterOffer.fromJson(data['data']);
      } else {
        final error = json.decode(response.body);
        throw Exception(error['message'] ?? 'Failed to reject offer');
      }
    } catch (e) {
      throw Exception('Error rejecting offer: $e');
    }
  }

  /// Cancel offer
  Future<BarterOffer> cancelOffer(int id, {String? reason}) async {
    try {
      final token = getToken();

      final response = await http.put(
        Uri.parse('$baseUrl/barter/offers/$id/cancel'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({'reason': reason}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return BarterOffer.fromJson(data['data']);
      } else {
        final error = json.decode(response.body);
        throw Exception(error['message'] ?? 'Failed to cancel offer');
      }
    } catch (e) {
      throw Exception('Error cancelling offer: $e');
    }
  }

  /// Delete offer (permanent)
  Future<void> deleteOffer(int id) async {
    try {
      final token = getToken();

      final response = await http.delete(
        Uri.parse('$baseUrl/barter/offers/$id'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode != 200) {
        final error = json.decode(response.body);
        throw Exception(error['message'] ?? 'Failed to delete offer');
      }
    } catch (e) {
      throw Exception('Error deleting offer: $e');
    }
  }

  /// Start barter session
  Future<BarterOffer> startSession(int id) async {
    try {
      final token = getToken();

      final response = await http.put(
        Uri.parse('$baseUrl/barter/offers/$id/start'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return BarterOffer.fromJson(data['data']);
      } else {
        final error = json.decode(response.body);
        throw Exception(error['message'] ?? 'Failed to start session');
      }
    } catch (e) {
      throw Exception('Error starting session: $e');
    }
  }

  /// Complete barter session
  Future<BarterOffer> completeSession(int id) async {
    try {
      final token = getToken();

      final response = await http.put(
        Uri.parse('$baseUrl/barter/offers/$id/complete'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return BarterOffer.fromJson(data['data']);
      } else {
        final error = json.decode(response.body);
        throw Exception(error['message'] ?? 'Failed to complete session');
      }
    } catch (e) {
      throw Exception('Error completing session: $e');
    }
  }

  /// Get transaction history
  Future<List<BarterOffer>> getHistory({int limit = 50}) async {
    try {
      final token = getToken();

      final response = await http.get(
        Uri.parse('$baseUrl/barter/history?limit=$limit'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> historyJson = data['data'];
        return historyJson.map((json) => BarterOffer.fromJson(json)).toList();
      } else {
        final error = json.decode(response.body);
        throw Exception(error['message'] ?? 'Failed to fetch history');
      }
    } catch (e) {
      throw Exception('Error fetching history: $e');
    }
  }

  /// Get skillcoin balance
  Future<int> getSkillcoinBalance() async {
    try {
      final token = getToken();

      final response = await http.get(
        Uri.parse('$baseUrl/barter/skillcoin/balance'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['data']['balance'];
      } else {
        final error = json.decode(response.body);
        throw Exception(error['message'] ?? 'Failed to fetch balance');
      }
    } catch (e) {
      throw Exception('Error fetching balance: $e');
    }
  }

  /// Get skillcoin transaction history
  Future<List<SkillcoinTransaction>> getSkillcoinHistory() async {
    try {
      final token = getToken();

      final response = await http.get(
        Uri.parse('$baseUrl/barter/skillcoin/history'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return (data['data']['history'] as List)
            .map((json) => SkillcoinTransaction.fromJson(json))
            .toList();
      } else {
        final error = json.decode(response.body);
        throw Exception(error['message'] ?? 'Failed to load skillcoin history');
      }
    } catch (e) {
      throw Exception('Failed to get skillcoin history: $e');
    }
  }

  /// Get proof of completion
  Future<Map<String, dynamic>?> getProof(int id) async {
    try {
      final token = getToken();

      final response = await http.get(
        Uri.parse('$baseUrl/barter/offers/$id/proof'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['data'];
      } else if (response.statusCode == 404) {
        return null; // No proof uploaded yet
      } else {
        final error = json.decode(response.body);
        throw Exception(error['message'] ?? 'Failed to get proof');
      }
    } catch (e) {
      throw Exception('Error getting proof: $e');
    }
  }

  /// Start barter session
  Future<BarterOffer> startBarter(int id) async {
    try {
      final token = getToken();

      final response = await http.post(
        Uri.parse('$baseUrl/barter/$id/start'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return BarterOffer.fromJson(data['data']);
      } else {
        final error = json.decode(response.body);
        throw Exception(error['message'] ?? 'Failed to start barter');
      }
    } catch (e) {
      throw Exception('Error starting barter: $e');
    }
  }

  /// Get confirmations for a barter (both users)
  Future<Map<String, BarterConfirmation?>> getConfirmations(
    int barterId,
  ) async {
    try {
      final token = getToken();
      final response = await http.get(
        Uri.parse('$baseUrl/barter/$barterId/confirmations'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final confirmations = (data['data'] as List)
            .map((json) => BarterConfirmation.fromJson(json))
            .toList();

        BarterConfirmation? ownConfirmation;
        BarterConfirmation? partnerConfirmation;

        for (var conf in confirmations) {
          if (conf.confirmationType == 'own') {
            ownConfirmation = conf;
          } else {
            partnerConfirmation = conf;
          }
        }

        return {'own': ownConfirmation, 'partner': partnerConfirmation};
      } else {
        final error = json.decode(response.body);
        throw Exception(error['message'] ?? 'Failed to get confirmations');
      }
    } catch (e) {
      throw Exception('Error getting confirmations: $e');
    }
  }

  /// Upload proof photo for barter completion
  Future<void> uploadProof(
    int offerId,
    String fotoBase64,
    String? catatan,
  ) async {
    try {
      final token = getToken();

      final response = await http.put(
        Uri.parse('$baseUrl/barter/$offerId/upload-proof'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({'foto_bukti': fotoBase64, 'catatan': catatan}),
      );

      if (response.statusCode != 200) {
        final error = json.decode(response.body);
        throw Exception(error['message'] ?? 'Failed to upload proof');
      }
    } catch (e) {
      throw Exception('Error uploading proof: $e');
    }
  }

  /// Confirm barter completion
  Future<void> confirmCompletion(int offerId, String? catatan) async {
    try {
      final token = getToken();

      final response = await http.put(
        Uri.parse('$baseUrl/barter/offers/$offerId/confirm'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({'catatan': catatan}),
      );

      if (response.statusCode != 200) {
        final error = json.decode(response.body);
        throw Exception(error['message'] ?? 'Failed to confirm completion');
      }
    } catch (e) {
      throw Exception('Error confirming completion: $e');
    }
  }

  /// Get confirmation status as list
  Future<List<ConfirmationModel>> getConfirmationsList(int offerId) async {
    try {
      final token = getToken();

      final response = await http.get(
        Uri.parse('$baseUrl/barter/$offerId/confirmations'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> confirmationsJson = data['data'];
        return confirmationsJson
            .map((json) => ConfirmationModel.fromJson(json))
            .toList();
      } else {
        throw Exception('Failed to get confirmations');
      }
    } catch (e) {
      throw Exception('Error getting confirmations: $e');
    }
  }
}
