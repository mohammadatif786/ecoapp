import 'dart:convert';
import 'dart:math' as math;

import 'package:shared_preferences/shared_preferences.dart';

class WalletCurrency {
  final String code;
  final String symbol;
  final String mode;
  final double rate;
  final int bps;
  final bool active;

  const WalletCurrency({
    required this.code,
    required this.symbol,
    required this.mode,
    required this.rate,
    required this.bps,
    this.active = true,
  });

  factory WalletCurrency.fromJson(Map<String, dynamic> json) {
    return WalletCurrency(
      code: (json['code'] ?? '').toString().toUpperCase(),
      symbol: (json['sym'] ?? json['symbol'] ?? '').toString(),
      mode: (json['mode'] ?? json['fx_mode'] ?? 'pegged').toString(),
      rate: WalletDemoService._asDouble(json['rate'] ?? json['rate_to_base'], 1),
      bps: WalletDemoService._asInt(json['bps'] ?? json['spread_bps'], 0),
      active: json['active'] != false,
    );
  }
}

class WalletSendLimits {
  final double standard;
  final double premium;

  const WalletSendLimits({required this.standard, required this.premium});
}

class WalletContact {
  final String name;
  final String tag;
  final String imageAsset;
  final String currency;
  final String country;
  final String? imageUrl;
  final int? userId;

  const WalletContact({
    required this.name,
    required this.tag,
    required this.imageAsset,
    required this.currency,
    required this.country,
    this.imageUrl,
    this.userId,
  });

  String get shortName {
    final parts = name.trim().split(RegExp(r'\s+'));
    return parts.isEmpty || parts.first.isEmpty ? name : parts.first;
  }

  factory WalletContact.fromUserMap(
    Map<String, dynamic>? user, {
    String? fallbackName,
  }) {
    if (user == null) {
      return const WalletContact(
        name: 'Recipient',
        tag: '',
        imageAsset: 'assets/profile2.jpg',
        currency: WalletDemoService.myCurrency,
        country: '',
      );
    }
    final name = (user['name'] ?? fallbackName ?? '').toString().trim();
    var tag = (user['linkup_id'] ?? user['link_up_id'] ?? user['username'] ?? '').toString().trim();
    if (tag.isNotEmpty && !tag.startsWith('@')) tag = '@$tag';
    final avatar = (user['avatar'] ?? user['image'] ?? user['photo'] ?? '').toString().trim();
    final country = (user['country'] ?? user['city'] ?? '').toString();
    final id = user['id'];
    return WalletContact(
      name: name.isEmpty ? tag.replaceAll('@', '') : name,
      tag: tag,
      imageAsset: 'assets/profile2.jpg',
      imageUrl: avatar.startsWith('http') ? avatar : null,
      currency: 'USD',
      country: country,
      userId: id is int ? id : int.tryParse(id?.toString() ?? ''),
    );
  }
}

class WalletDemoService {
  static const String myCurrency = 'BSD';
  static const double fallbackWalletBalance = 181.04;

  static const List<WalletCurrency> fallbackCurrencies = [
    WalletCurrency(code: 'USD', symbol: r'$', mode: 'pegged', rate: 1, bps: 0),
    WalletCurrency(code: 'BSD', symbol: r'B$', mode: 'pegged', rate: 1, bps: 0),
    WalletCurrency(code: 'XCD', symbol: r'EC$', mode: 'pegged', rate: 2.70, bps: 0),
    WalletCurrency(code: 'BBD', symbol: r'Bds$', mode: 'pegged', rate: 2.00, bps: 0),
    WalletCurrency(code: 'KYD', symbol: r'CI$', mode: 'pegged', rate: 0.82, bps: 0),
    WalletCurrency(code: 'TTD', symbol: r'TT$', mode: 'floating', rate: 6.78, bps: 150),
    WalletCurrency(code: 'JMD', symbol: r'J$', mode: 'floating', rate: 157, bps: 150),
    WalletCurrency(code: 'HTG', symbol: 'G', mode: 'floating', rate: 132, bps: 200),
    WalletCurrency(code: 'DOP', symbol: r'RD$', mode: 'floating', rate: 59, bps: 150),
  ];

  static const List<WalletContact> contacts = [
    WalletContact(name: 'Cassius', tag: '@cassius', imageAsset: 'assets/profile2.jpg', currency: 'BSD', country: 'Bahamas'),
    WalletContact(name: 'Aaliyah', tag: '@aaliyah', imageAsset: 'assets/profile2.jpg', currency: 'JMD', country: 'Jamaica'),
    WalletContact(name: 'Renee', tag: '@renee', imageAsset: 'assets/profile2.jpg', currency: 'XCD', country: 'St. Lucia'),
  ];

  static Future<List<WalletCurrency>> loadCurrencies() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('lk_currencies');
    if (raw == null || raw.trim().isEmpty) return fallbackCurrencies;

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return fallbackCurrencies;
      final currencies = decoded
          .whereType<Map>()
          .map((m) => WalletCurrency.fromJson(Map<String, dynamic>.from(m)))
          .where((c) => c.code.isNotEmpty && c.rate > 0 && c.active)
          .toList();
      return currencies.isEmpty ? fallbackCurrencies : currencies;
    } catch (_) {
      return fallbackCurrencies;
    }
  }

  static WalletCurrency? currencyFrom(List<WalletCurrency> currencies, String code) {
    final normalized = code.toUpperCase();
    for (final currency in currencies) {
      if (currency.code == normalized) return currency;
    }
    return null;
  }

  static String symbolFor(List<WalletCurrency> currencies, String code) {
    return currencyFrom(currencies, code)?.symbol ?? '$code ';
  }

  static double? fxQuote(List<WalletCurrency> currencies, double amount, String from, String to) {
    if (from == to) return _roundMoney(amount);
    final source = currencyFrom(currencies, from);
    final destination = currencyFrom(currencies, to);
    if (source == null || destination == null) return null;
    final converted = (amount / source.rate) * destination.rate * (1 - destination.bps / 10000);
    return _roundMoney(converted);
  }

  static String formatCurrency(List<WalletCurrency> currencies, double? amount, String code) {
    if (amount == null) return '—';
    return '${symbolFor(currencies, code)}${_withCommas(amount)}';
  }

  static String money(double amount) => '\$${_withCommas(amount)}';

  static WalletContact resolveContact(String input, {List<WalletContact>? pool}) {
    final list = (pool != null && pool.isNotEmpty) ? pool : contacts;
    final normalized = input.trim().toLowerCase();
    if (normalized.isEmpty) {
      return list.isNotEmpty
          ? list.first
          : const WalletContact(
              name: 'Recipient',
              tag: '',
              imageAsset: 'assets/profile2.jpg',
              currency: myCurrency,
              country: '',
            );
    }
    for (final contact in list) {
      if (normalized == contact.name.toLowerCase() ||
          normalized == contact.tag.toLowerCase() ||
          normalized.contains(contact.name.toLowerCase()) ||
          normalized.contains(contact.tag.toLowerCase())) {
        return contact;
      }
    }
    return WalletContact(
      name: input.trim().isEmpty ? 'Recipient' : input.trim().replaceAll('@', ''),
      tag: input.trim().startsWith('@') ? input.trim() : '@${input.trim().toLowerCase().replaceAll(' ', '')}',
      imageAsset: 'assets/profile2.jpg',
      currency: myCurrency,
      country: 'Bahamas',
    );
  }

  static Future<WalletSendLimits> loadSendLimits() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('lk_send_limits');
    if (raw == null || raw.trim().isEmpty) {
      return const WalletSendLimits(standard: 2500, premium: 10000);
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return const WalletSendLimits(standard: 2500, premium: 10000);
      return WalletSendLimits(
        standard: _asDouble(decoded['standard'], 2500),
        premium: _asDouble(decoded['premium'], 10000),
      );
    } catch (_) {
      return const WalletSendLimits(standard: 2500, premium: 10000);
    }
  }

  static Future<double> sent24h() async {
    final log = await _sendLog();
    final cutoff = DateTime.now().millisecondsSinceEpoch - const Duration(hours: 24).inMilliseconds;
    return log
        .where((entry) => (entry['ts'] as int) > cutoff)
        .fold<double>(0, (sum, entry) => sum + (entry['amount'] as double));
  }

  static Future<double> remaining24h({required bool isPremium}) async {
    final limits = await loadSendLimits();
    final limit = isPremium ? limits.premium : limits.standard;
    return math.max(0, limit - await sent24h());
  }

  static Future<void> recordSend(double amount) async {
    final prefs = await SharedPreferences.getInstance();
    final cutoff = DateTime.now().millisecondsSinceEpoch - const Duration(hours: 24).inMilliseconds;
    final log = List<Map<String, dynamic>>.from(
      (await _sendLog()).where((entry) => (entry['ts'] as int) > cutoff),
    );
    log.add(<String, dynamic>{
      'ts': DateTime.now().millisecondsSinceEpoch,
      'amount': _roundMoney(amount),
    });
    await prefs.setString('lk_send_log', jsonEncode(log));
  }

  static Future<String> getPin() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('lk_send_pin') ?? '';
  }

  static Future<bool> hasPin() async => RegExp(r'^\d{4}$').hasMatch(await getPin());

  static Future<void> setPin(String pin) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('lk_send_pin', pin);
  }

  static Future<List<Map<String, dynamic>>> _sendLog() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('lk_send_log');
    if (raw == null || raw.trim().isEmpty) return [];

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return [];
      return decoded.whereType<Map>().map((m) {
        return <String, dynamic>{
          'ts': _asInt(m['ts'], 0),
          'amount': _asDouble(m['amount'], 0),
        };
      }).where((entry) => (entry['ts'] as int) > 0 && (entry['amount'] as double) > 0).toList();
    } catch (_) {
      return [];
    }
  }

  static double _asDouble(dynamic value, double fallback) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? fallback;
  }

  static int _asInt(dynamic value, int fallback) {
    if (value is int) return value;
    if (value is num) return value.round();
    return int.tryParse(value?.toString() ?? '') ?? fallback;
  }

  static double _roundMoney(double value) => (value * 100).round() / 100;

  static String _withCommas(double value) {
    final fixed = value.toStringAsFixed(2);
    final parts = fixed.split('.');
    final intPart = parts.first.replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (match) => ',');
    return "$intPart.${parts.length > 1 ? parts[1] : '00'}";
  }
}
