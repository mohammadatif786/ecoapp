import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:link_up/services/linkup_api_service.dart';

class WalletContactService {
  final String baseUrl;
  final String? userToken;

  WalletContactService({
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

  // 1. Fetch Contacts
  Future<List<dynamic>> fetchContacts() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/contact'),
        headers: headers,
      );
      final data = jsonDecode(response.body);
      if (data['success'] == true && data['contacts'] != null) {
        return data['contacts'] as List<dynamic>;
      }
      return [];
    } catch (e) {
      debugPrint('Fetch Contacts Error: $e');
      return [];
    }
  }

  // 2. Add Contact
  Future<Map<String, dynamic>> addContact({
    required int contactUserId,
    String? name,
  }) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/contact'),
        headers: headers,
        body: jsonEncode({
          'contact_user_id': contactUserId,
          if (name != null && name.isNotEmpty) 'name': name,
        }),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'An error occurred: $e'};
    }
  }

  // 3. Remove Contact
  Future<Map<String, dynamic>> removeContact(int contactId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.delete(
        Uri.parse('$baseUrl/contact/$contactId'),
        headers: headers,
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'An error occurred: $e'};
    }
  }
}
