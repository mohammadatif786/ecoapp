import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:link_up/services/linkup_api_service.dart';

class EventBookingService {
  final String baseUrl;
  final String? userToken;

  EventBookingService({
    this.userToken,
    this.baseUrl = 'https://linkupvibes.com/api/regular-user/events',
  });

  Future<Map<String, String>> get _headers async {
    final token = userToken ?? await LinkupApiService.getToken();
    return {
      if (token != null && token.isNotEmpty)
        'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
  }

  // 1. Fetch Active Bookings
  Future<List<dynamic>> fetchActiveBookings() async {
    try {
      final headers = await _headers;
      final response = await http.get(
        Uri.parse('$baseUrl/bookings'),
        headers: headers,
      );
      final data = jsonDecode(response.body);
      if (data['success'] == true && data['data'] != null) {
        return data['data'] as List<dynamic>;
      }
      return [];
    } catch (e) {
      debugPrint('Fetch Active Bookings Error: $e');
      return [];
    }
  }

  // 2. Fetch Cancelled Bookings
  Future<List<dynamic>> fetchCancelledBookings() async {
    try {
      final headers = await _headers;
      final response = await http.get(
        Uri.parse('$baseUrl/bookings/cancelled'),
        headers: headers,
      );
      final data = jsonDecode(response.body);
      if (data['success'] == true && data['data'] != null) {
        return data['data'] as List<dynamic>;
      }
      return [];
    } catch (e) {
      debugPrint('Fetch Cancelled Bookings Error: $e');
      return [];
    }
  }

  // 3. Show Booking Detail (E-Ticket)
  Future<Map<String, dynamic>?> showBookingDetail(int ticketSaleId) async {
    try {
      final headers = await _headers;
      final response = await http.get(
        Uri.parse('$baseUrl/bookings/$ticketSaleId'),
        headers: headers,
      );
      final data = jsonDecode(response.body);
      if (data['success'] == true && data['data'] != null) {
        return data['data'] as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      debugPrint('Show Booking Detail Error: $e');
      return null;
    }
  }

  // 4. Cancel Booking Immediately
  Future<Map<String, dynamic>> cancelBooking(int ticketSaleId) async {
    try {
      final headers = await _headers;
      final response = await http.post(
        Uri.parse('$baseUrl/bookings/$ticketSaleId/cancel'),
        headers: headers,
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'An error occurred: $e'};
    }
  }

  // 5. Submit Refund & Cancellation Request
  Future<Map<String, dynamic>> cancelBookingRequest({
    required int ticketSaleId,
    required double refundAmount,
    String? reason,
  }) async {
    try {
      final headers = await _headers;
      final response = await http.post(
        Uri.parse('$baseUrl/bookings/$ticketSaleId/cancel-request'),
        headers: headers,
        body: jsonEncode({
          'amount': refundAmount,
          if (reason != null && reason.isNotEmpty) 'reason': reason,
        }),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'An error occurred: $e'};
    }
  }
}
