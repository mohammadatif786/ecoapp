import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:link_up/services/linkup_api_service.dart';

class AsueService {
  final String baseUrl;
  final String? userToken;

  AsueService({
    this.userToken,
    this.baseUrl = 'https://linkupvibes.com/api/regular-user/wallet',
  });

  Future<Map<String, String>> _getHeaders() async {
    final token = userToken ?? await LinkupApiService.getToken();
    return {
      if (token != null && token.isNotEmpty)
        'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
  }

  // =================================================================
  // 📊 1. Fetch Active ASUE Circle
  // =================================================================
  Future<Map<String, dynamic>?> fetchActiveAsue() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/asues/active'),
        headers: headers,
      );

      final data = jsonDecode(response.body);
      if (data['success'] == true && data['activeAsue'] != null) {
        return data['activeAsue'] as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      debugPrint('Fetch Active ASUE Error: $e');
      return null;
    }
  }

  // =================================================================
  // ➕ 2. Create New ASUE Circle
  // =================================================================
  Future<Map<String, dynamic>> createAsue({
    required String name,
    required String frequency, // "weekly" or "monthly"
    required double handAmount,
    required String startDate, // "YYYY-MM-DD"
    required int maxMembers,
    required List<int> memberUserIds,
  }) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/asues/store'),
        headers: headers,
        body: jsonEncode({
          'name': name,
          'frequency': frequency,
          'hand_amount': handAmount,
          'start_date': startDate,
          'max_members': maxMembers,
          'user_ids': memberUserIds,
          'disclaimerAgreed': true,
        }),
      );

      final data = jsonDecode(response.body);
      return {
        'success': (response.statusCode == 200 || response.statusCode == 201) && data['success'] == true,
        'message': data['message'] ?? 'Asue created successfully.',
        'asue': data['asue'],
      };
    } catch (e) {
      debugPrint('Create ASUE Error: $e');
      return {'success': false, 'message': 'An error occurred: $e'};
    }
  }

  // =================================================================
  // ✅ 3. Accept ASUE Participation Invitation
  // =================================================================
  Future<Map<String, dynamic>> acceptParticipation(int asueId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/asues/$asueId/accept-participation'),
        headers: headers,
      );

      final data = jsonDecode(response.body);
      return {
        'success': data['success'] == true,
        'message': data['message'] ?? 'Participation accepted.',
      };
    } catch (e) {
      debugPrint('Accept Participation Error: $e');
      return {'success': false, 'message': 'An error occurred: $e'};
    }
  }

  // =================================================================
  // 🔄 4. Simulate Cycle Payout
  // =================================================================
  Future<Map<String, dynamic>> simulateCycle(int asueId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/asues/$asueId/simulate-cycle'),
        headers: headers,
      );

      final data = jsonDecode(response.body);
      return {
        'success': data['success'] == true,
        'message': data['message'] ?? 'Cycle executed.',
      };
    } catch (e) {
      debugPrint('Simulate Cycle Error: $e');
      return {'success': false, 'message': 'An error occurred: $e'};
    }
  }

  // =================================================================
  // 🎁 5. Simulate Accept Payout
  // =================================================================
  Future<Map<String, dynamic>> simulateAccept(int asueId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/asues/$asueId/simulate-accept'),
        headers: headers,
      );

      final data = jsonDecode(response.body);
      return {
        'success': data['success'] == true,
        'message': data['message'] ?? 'Payout accepted.',
      };
    } catch (e) {
      debugPrint('Simulate Accept Error: $e');
      return {'success': false, 'message': 'An error occurred: $e'};
    }
  }
}
