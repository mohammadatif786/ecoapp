import 'dart:math' as math;

import 'package:link_up/services/wallet_demo_service.dart';

/// Parsed payload from `GET /api/regular-user/user/wallet`.
class WalletResult {
  final double currentBalance;
  final int coinBalance;
  final List<WalletTransaction> transactions;
  final List<WalletContact> contacts;
  final List<WalletContact> suggestedUsers;
  final List<WalletMoneyRequest> sentRequests;
  final WalletActiveAsue? activeAsue;

  const WalletResult({
    required this.currentBalance,
    required this.coinBalance,
    required this.transactions,
    required this.contacts,
    this.suggestedUsers = const [],
    this.sentRequests = const [],
    this.activeAsue,
  });

  static const empty = WalletResult(
    currentBalance: 0,
    coinBalance: 0,
    transactions: [],
    contacts: [],
    suggestedUsers: [],
    sentRequests: [],
    activeAsue: null,
  );

  factory WalletResult.fromJson(Map<String, dynamic> json) {
    final transactions = _mapList(json['transactions'])
        .map(WalletTransaction.fromJson)
        .toList();

    final contacts = <WalletContact>[];
    final suggestedUsers = <WalletContact>[];
    final savedIds = <int>{};

    WalletContact? parseContact(Map<String, dynamic>? user, {String? fallbackName}) {
      if (user == null) return null;
      final contact = WalletContact.fromUserMap(user, fallbackName: fallbackName);
      if (contact.userId == null && contact.name.trim().isEmpty && contact.tag.trim().isEmpty) {
        return null;
      }
      return contact;
    }

    for (final row in _mapList(json['contacts'])) {
      final contact = parseContact(
        _map(row['contact_user'] ?? row['contactUser']),
        fallbackName: row['name']?.toString(),
      );
      if (contact == null) continue;
      if (contact.userId != null) savedIds.add(contact.userId!);
      contacts.add(contact);
    }

    for (final row in _mapList(json['users'])) {
      final user = parseContact(_map(row['user']) ?? row);
      if (user == null || user.userId == null) continue;
      if (savedIds.contains(user.userId)) continue;
      suggestedUsers.add(user);
    }

    return WalletResult(
      currentBalance: _asDouble(json['currentBalance']),
      coinBalance: _asInt(json['coinBalance']),
      transactions: transactions,
      contacts: contacts,
      suggestedUsers: suggestedUsers,
      sentRequests: _mapList(json['sentRequests'] ?? json['sent_requests'])
          .map(WalletMoneyRequest.fromJson)
          .toList(),
      activeAsue: WalletActiveAsue.tryFromJson(json['activeAsue'] ?? json['active_asue']),
    );
  }

  static Map<String, dynamic>? _map(dynamic value) {
    if (value is Map) return Map<String, dynamic>.from(value);
    return null;
  }

  static List<Map<String, dynamic>> _mapList(dynamic value) {
    if (value is! List) return const [];
    return value
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  static double _asDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  static int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.round();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static bool _asBool(dynamic value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    final raw = value?.toString().trim().toLowerCase() ?? '';
    return raw == '1' || raw == 'true' || raw == 'yes';
  }
}

class WalletTransaction {
  final int id;
  final double amount;
  final String currency;
  final String status;
  final String processorId;
  final bool isPositive;
  final DateTime? createdAt;
  final Map<String, dynamic> meta;
  final String recipientName;
  final String recipientTag;

  const WalletTransaction({
    required this.id,
    required this.amount,
    required this.currency,
    required this.status,
    required this.processorId,
    required this.isPositive,
    required this.createdAt,
    required this.meta,
    required this.recipientName,
    required this.recipientTag,
  });

  factory WalletTransaction.fromJson(Map<String, dynamic> json) {
    final meta = json['meta'] is Map
        ? Map<String, dynamic>.from(json['meta'] as Map)
        : <String, dynamic>{};
    final recipient = json['recipient'] is Map
        ? Map<String, dynamic>.from(json['recipient'] as Map)
        : <String, dynamic>{};

    if (json['type'] != null && meta['type'] == null) {
      meta['type'] = json['type'];
    }
    if (json['title'] != null && meta['title'] == null) {
      meta['title'] = json['title'];
    }
    if (json['description'] != null && meta['description'] == null) {
      meta['description'] = json['description'];
    }
    if (json['purpose'] != null && meta['purpose'] == null) {
      meta['purpose'] = json['purpose'];
    }

    final String rawType = (meta['type'] ?? json['type'] ?? json['purpose'] ?? meta['purpose'] ?? '').toString().toLowerCase();
    final bool isDepositType = rawType == 'cash_deposit' ||
        rawType == 'coin_deposit' ||
        rawType == 'cash_topup' ||
        rawType == 'wallet_topup' ||
        rawType == 'recharge' ||
        rawType == 'buy_coins' ||
        rawType == 'coin_purchase';

    return WalletTransaction(
      id: WalletResult._asInt(json['id']),
      amount: WalletResult._asDouble(json['amount'] ?? json['received']),
      currency: (json['currency'] ?? 'USD').toString().toUpperCase(),
      status: (json['status'] ?? '').toString(),
      processorId: (json['processor_id'] ?? '').toString(),
      isPositive: json['is_positive'] == true || isDepositType,
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? ''),
      meta: meta,
      recipientName: (recipient['name'] ?? meta['recipient_name'] ?? '').toString(),
      recipientTag: (recipient['linkup_id'] ?? meta['recipient_linkup_id'] ?? '').toString(),
    );
  }

  String get type => (meta['type'] ?? '').toString();
  String get note {
    final value = (meta['note'] ?? '').toString().trim();
    return value;
  }

  String get senderName => (meta['sender_name'] ?? '').toString();

  String get title {
    final explicitTitle = (meta['title'] ?? meta['description'] ?? '').toString().trim();
    if (explicitTitle.isNotEmpty &&
        explicitTitle != 'Top Up - Card' &&
        explicitTitle != 'wallet_topup' &&
        explicitTitle != 'buy_coins') {
      return explicitTitle;
    }

    final String t = type.toLowerCase();
    final String p = processorId.toLowerCase();
    final String purp = (meta['purpose'] ?? '').toString().toLowerCase();

    if (t == 'coin_deposit' ||
        t == 'coin_purchase' ||
        t == 'buy_coins' ||
        purp == 'buy_coins' ||
        purp == 'coin_deposit') {
      return 'Coin Deposit';
    }

    if (t == 'cash_deposit' ||
        t == 'cash_topup' ||
        t == 'wallet_topup' ||
        t == 'recharge' ||
        purp == 'cash_deposit' ||
        purp == 'wallet_topup' ||
        p == 'deposit') {
      return 'Cash Deposit';
    }

    switch (t) {
      case 'p2p_transfer':
        if (isPositive) {
          return senderName.isNotEmpty ? 'Received from $senderName' : 'Received money';
        }
        return recipientName.isNotEmpty ? 'Sent to $recipientName' : 'Sent money';
      case 'money_request_payment':
        return isPositive ? 'Request paid to you' : 'Paid a request';
      case 'asue_contribution':
        return 'Asue contribution';
      case 'asue_payout':
        return 'Asue payout';
      case 'bank_withdrawal':
        return 'Bank withdrawal';
      case 'bank_withdrawal_refund':
        return 'Withdrawal refund';
      case 'seller_cash_out_payout':
        return 'Seller payout';
    }

    if (p.contains('card') || p.contains('stripe')) {
      if (t.contains('coin') || purp.contains('coin')) {
        return 'Coin Deposit';
      }
      return 'Cash Deposit';
    }

    return isPositive ? 'Cash Deposit' : 'Sent money';
  }

  String get counterparty {
    if (recipientName.isNotEmpty) return recipientName;
    if (senderName.isNotEmpty) return senderName;
    if (processorId == 'deposit' || type == 'recharge') return 'Wallet';
    if (type.startsWith('asue')) return 'Asue';
    if (type.startsWith('bank_withdrawal')) return 'Bank';
    return 'Wallet';
  }

  String get signedAmount {
    final value = amount.toStringAsFixed(2);
    return isPositive ? '+\$$value' : '-\$$value';
  }

  String get shortDate {
    if (createdAt == null) return '';
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final date = createdAt!;
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  String get monthLabel {
    if (createdAt == null) return '';
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    final date = createdAt!;
    return '${months[date.month - 1]} ${date.year}';
  }

  String get subtitle {
    final parts = <String>[];
    if (note.isNotEmpty) parts.add(note);
    if (shortDate.isNotEmpty) parts.add(shortDate);
    if (status.isNotEmpty) parts.add(status);
    return parts.join(' · ');
  }

  bool get isDeposit =>
      isPositive && (processorId == 'deposit' || type == 'recharge' || type == 'asue_payout');

  bool get isSent =>
      !isPositive &&
      (type == 'p2p_transfer' ||
          processorId == 'transfer' ||
          type == 'money_request_payment');

  bool get isReceived =>
      isPositive &&
      !isDeposit &&
      (type == 'p2p_transfer' ||
          processorId == 'transfer' ||
          type == 'money_request_payment');

  bool get isWithdrawal =>
      type.startsWith('bank_withdrawal') ||
      type == 'seller_cash_out_payout' ||
      processorId.toLowerCase().contains('withdraw');

  bool get isWalletOrCoin {
    final blob = '$type $processorId'.toLowerCase();
    return blob.contains('coin');
  }
}

class WalletMoneyRequest {
  final int id;
  final double amount;
  final String note;
  final String status;
  final DateTime? createdAt;
  final String recipientName;
  final String recipientTag;
  final String? recipientAvatar;

  const WalletMoneyRequest({
    required this.id,
    required this.amount,
    required this.note,
    required this.status,
    required this.createdAt,
    required this.recipientName,
    required this.recipientTag,
    this.recipientAvatar,
  });

  factory WalletMoneyRequest.fromJson(Map<String, dynamic> json) {
    final recipient = json['recipient'] is Map
        ? Map<String, dynamic>.from(json['recipient'] as Map)
        : <String, dynamic>{};
    final avatar = (recipient['avatar'] ?? recipient['image'] ?? recipient['photo'] ?? '').toString().trim();
    var tag = (recipient['linkup_id'] ?? recipient['link_up_id'] ?? '').toString().trim();
    if (tag.isNotEmpty && !tag.startsWith('@')) tag = '@$tag';

    return WalletMoneyRequest(
      id: WalletResult._asInt(json['id']),
      amount: WalletResult._asDouble(json['amount']),
      note: (json['note'] ?? '').toString().trim(),
      status: (json['status'] ?? '').toString(),
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? ''),
      recipientName: (recipient['name'] ?? '').toString().trim(),
      recipientTag: tag,
      recipientAvatar: avatar.startsWith('http') ? avatar : null,
    );
  }

  bool get isPaid {
    final value = status.toLowerCase();
    return value == 'accepted' || value == 'paid' || value == 'success';
  }

  String get subtitle {
    if (note.isNotEmpty) return note;
    if (status.trim().isEmpty) return 'requested';
    return status;
  }

  String get actionLabel => isPaid ? 'Paid' : 'Pending';

  String get monthLabel {
    if (createdAt == null) return 'Recent';
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    final date = createdAt!;
    return '${months[date.month - 1]} ${date.year}';
  }

  String get shortDate {
    if (createdAt == null) return '';
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final date = createdAt!;
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}

class WalletActivityItem {
  final String id;
  final String title;
  final double amount;
  final bool isPositive;
  final String status;
  final String type;
  final String counterparty;
  final String note;
  final double runningBalance;
  final DateTime? date;
  final String dateLabel;

  const WalletActivityItem({
    required this.id,
    required this.title,
    required this.amount,
    required this.isPositive,
    required this.status,
    required this.type,
    required this.counterparty,
    required this.note,
    required this.runningBalance,
    required this.date,
    required this.dateLabel,
  });

  factory WalletActivityItem.fromJson(Map<String, dynamic> json) {
    return WalletActivityItem(
      id: (json['id'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      amount: WalletResult._asDouble(json['amount']),
      isPositive: json['isPositive'] == true || json['is_positive'] == true,
      status: (json['status'] ?? '').toString(),
      type: (json['type'] ?? '').toString(),
      counterparty: (json['counterparty'] ?? '').toString(),
      note: (json['note'] ?? '').toString().trim(),
      runningBalance: WalletResult._asDouble(json['runningBalance'] ?? json['running_balance']),
      date: DateTime.tryParse(json['date']?.toString() ?? ''),
      dateLabel: (json['dateLabel'] ?? json['date_label'] ?? '').toString(),
    );
  }

  String get signedAmount {
    final value = amount.toStringAsFixed(2);
    return isPositive ? '+\$$value' : '-\$$value';
  }

  String get subtitle {
    final parts = <String>[];
    if (note.isNotEmpty) parts.add(note);
    if (dateLabel.isNotEmpty) parts.add(dateLabel);
    if (status.isNotEmpty) parts.add(status);
    return parts.join(' · ');
  }

  String get monthLabel {
    if (date == null) return dateLabel.isEmpty ? 'Recent' : dateLabel;
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    final value = date!;
    return '${months[value.month - 1]} ${value.year}';
  }

  bool get isDeposit =>
      type == 'recharge' || type == 'asue_payout' || (type == 'wallet' && isPositive);

  bool get isSent => type == 'p2p_transfer' && !isPositive;

  bool get isReceived => type == 'p2p_transfer' && isPositive;

  bool get isRequested => type == 'money_request_payment';

  bool get isWithdrawal =>
      type.contains('withdraw') || type == 'seller_cash_out_payout';

  bool get isWalletOrCoin =>
      type == 'wallet' || type.contains('coin') || type == 'asue_contribution';
}

class WalletActiveAsue {
  final int id;
  final String name;
  final String frequency;
  final double handAmount;
  final DateTime? startDate;
  final int maxMembers;
  final int coordinatorId;
  final String status;
  final int currentTurn;
  final bool payoutAccepted;
  final List<WalletAsueMember> invitedUsers;

  const WalletActiveAsue({
    required this.id,
    required this.name,
    required this.frequency,
    required this.handAmount,
    required this.startDate,
    required this.maxMembers,
    required this.coordinatorId,
    required this.status,
    required this.currentTurn,
    required this.payoutAccepted,
    required this.invitedUsers,
  });

  double get totalPot => handAmount * (maxMembers <= 0 ? invitedUsers.length : maxMembers);

  double get fee => totalPot * 0.03;

  double get payout => totalPot - fee;

  int get acceptedCount => invitedUsers.where((member) => member.isAccepted).length;

  bool get allMembersAccepted {
    if (invitedUsers.isEmpty) return false;
    if (invitedUsers.any((member) => !member.isAccepted)) return false;
    if (maxMembers > 0 && acceptedCount < maxMembers) return false;
    return true;
  }

  WalletAsueMember? get currentTurnMember {
    return memberAtTurn(currentTurn);
  }

  WalletAsueMember? memberAtTurn(int turn) {
    final members = membersByPosition;
    for (final member in members) {
      if (member.position == turn) return member;
    }
    return members.isEmpty ? null : members.first;
  }

  int get highlightTurn {
    final turn = currentTurn <= 0 ? 1 : currentTurn;
    if (payoutAccepted) {
      final next = turn + 1;
      final last = membersByPosition.isEmpty ? next : membersByPosition.last.position;
      return next > last ? last : next;
    }
    return turn;
  }

  WalletAsueMember? get highlightedMember => memberAtTurn(highlightTurn);

  bool isCurrentTurn(WalletAsueMember member) => member.position == highlightTurn;

  bool payoutDoneFor(WalletAsueMember member) {
    if (currentTurn > 0 && member.position < currentTurn) return true;
    return member.position == currentTurn && payoutAccepted;
  }

  bool get hasPaidPayout => invitedUsers.any(payoutDoneFor);

  List<WalletAsueMember> get membersByPosition {
    final members = [...invitedUsers];
    members.sort((a, b) => a.position.compareTo(b.position));
    return members;
  }

  WalletAsueMember? memberForUser({int? userId, String? tag, String? email}) {
    for (final member in invitedUsers) {
      if (userId != null && member.id == userId) return member;
      if (tag != null && tag.trim().isNotEmpty) {
        final needle = tag.trim().toLowerCase().replaceFirst(RegExp(r'^@'), '');
        final memberTag = member.tag.toLowerCase().replaceFirst(RegExp(r'^@'), '');
        if (needle.isNotEmpty && memberTag == needle) return member;
      }
      if (email != null && email.trim().isNotEmpty && member.email.toLowerCase() == email.trim().toLowerCase()) {
        return member;
      }
    }
    return null;
  }

  static WalletActiveAsue? tryFromJson(dynamic value) {
    if (value is! Map) return null;
    final json = Map<String, dynamic>.from(value);
    final id = WalletResult._asInt(json['id']);
    if (id <= 0) return null;
    final members = WalletResult._mapList(json['invited_users'] ?? json['invitedUsers'])
        .map(WalletAsueMember.fromJson)
        .toList();
    return WalletActiveAsue(
      id: id,
      name: (json['name'] ?? '').toString().trim(),
      frequency: (json['frequency'] ?? 'Weekly').toString().trim(),
      handAmount: WalletResult._asDouble(json['hand_amount'] ?? json['handAmount']),
      startDate: DateTime.tryParse((json['start_date'] ?? json['startDate'] ?? '').toString()),
      maxMembers: WalletResult._asInt(json['max_members'] ?? json['maxMembers']),
      coordinatorId: WalletResult._asInt(json['user_id'] ?? json['userId']),
      status: (json['status'] ?? '').toString().trim(),
      currentTurn: WalletResult._asInt(json['current_turn'] ?? json['currentTurn']),
      payoutAccepted: WalletResult._asBool(json['payout_accepted'] ?? json['payoutAccepted']),
      invitedUsers: members,
    );
  }

  DateTime? payoutDateFor(WalletAsueMember member) {
    if (startDate == null) return null;
    final index = math.max(0, member.position - 1);
    final start = DateTime(startDate!.year, startDate!.month, startDate!.day);
    switch (frequency.toLowerCase().replaceAll(' ', '')) {
      case 'bi-weekly':
      case 'biweekly':
        return start.add(Duration(days: 14 * index));
      case 'monthly':
        return DateTime(start.year, start.month + index, start.day);
      default:
        return start.add(Duration(days: 7 * index));
    }
  }
}

class WalletAsueMember {
  final int id;
  final String name;
  final String tag;
  final String email;
  final String? avatarUrl;
  final int asueId;
  final int position;
  final String participationStatus;

  const WalletAsueMember({
    required this.id,
    required this.name,
    required this.tag,
    required this.email,
    required this.avatarUrl,
    required this.asueId,
    required this.position,
    required this.participationStatus,
  });

  bool get isAccepted => participationStatus.toLowerCase() == 'accepted';

  bool get isInvited => participationStatus.toLowerCase() == 'invited';

  factory WalletAsueMember.fromJson(Map<String, dynamic> json) {
    final pivot = json['pivot'] is Map ? Map<String, dynamic>.from(json['pivot'] as Map) : const <String, dynamic>{};
    var tag = (json['linkup_id'] ?? json['link_up_id'] ?? '').toString().trim();
    if (tag.isNotEmpty && !tag.startsWith('@')) tag = '@$tag';
    final avatar = (json['avatar'] ?? json['image'] ?? '').toString().trim();
    return WalletAsueMember(
      id: WalletResult._asInt(json['id']),
      name: (json['name'] ?? '').toString().trim(),
      tag: tag,
      email: (json['email'] ?? '').toString().trim(),
      avatarUrl: avatar.startsWith('http') ? avatar : null,
      asueId: WalletResult._asInt(pivot['asue_id'] ?? pivot['asueId']),
      position: WalletResult._asInt(pivot['position']),
      participationStatus: (pivot['participation_status'] ?? pivot['participationStatus'] ?? '').toString().trim(),
    );
  }
}
