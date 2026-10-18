import 'package:link_up/mappers/api_user_mapper.dart';

class NotificationsResult {
  final List<LinkUpNotificationItem> notifications;
  final String appUrl;
  final int? unreadCount;

  const NotificationsResult({
    required this.notifications,
    required this.appUrl,
    this.unreadCount,
  });

  factory NotificationsResult.fromJson(Map<String, dynamic> json) {
    final raw = json['allnotifications'] ??
        json['notifications'] ??
        json['data'];
    return NotificationsResult(
      notifications: raw is List
          ? raw
              .whereType<Map>()
              .map((item) => LinkUpNotificationItem.fromJson(
                    Map<String, dynamic>.from(item),
                  ))
              .toList()
          : const [],
      appUrl: (json['appURL'] ?? json['appUrl'] ?? '').toString(),
      unreadCount: _asIntOrNull(
        json['unread_count'] ?? json['unreadCount'],
      ),
    );
  }
}

class LinkUpNotificationSender {
  final int id;
  final String name;
  final String firstName;
  final String lastName;
  final String avatarUrl;

  const LinkUpNotificationSender({
    required this.id,
    required this.name,
    required this.firstName,
    required this.lastName,
    required this.avatarUrl,
  });

  String get displayName {
    if (name.trim().isNotEmpty) return name.trim();
    final combined = '$firstName $lastName'.trim();
    return combined;
  }

  factory LinkUpNotificationSender.fromJson(Map<String, dynamic> json) {
    return LinkUpNotificationSender(
      id: _asInt(json['id']),
      name: (json['name'] ?? '').toString().trim(),
      firstName: (json['first_name'] ?? '').toString().trim(),
      lastName: (json['last_name'] ?? '').toString().trim(),
      avatarUrl: ApiUserMapper.resolveMediaUrl(
        (json['avatar'] ?? json['image'] ?? '').toString(),
      ),
    );
  }
}

class LinkUpNotificationItem {
  final int id;
  final int userId;
  final String title;
  final String message;
  final int sendBy;
  final String type;
  final String category;
  final String? context;
  bool unread;
  final bool priority;
  final String? icon;
  final String avatarUrl;
  final Map<String, dynamic> metadata;
  final DateTime? createdAt;
  final LinkUpNotificationSender? sender;

  LinkUpNotificationItem({
    required this.id,
    required this.userId,
    required this.title,
    required this.message,
    required this.sendBy,
    required this.type,
    required this.category,
    required this.context,
    required this.unread,
    required this.priority,
    required this.icon,
    required this.avatarUrl,
    required this.metadata,
    required this.createdAt,
    required this.sender,
  });

  String get body => message.trim();

  String get tab {
    final fromCategory = notificationCategoryLabel(category);
    if (fromCategory.isNotEmpty) return fromCategory;
    final fromType = notificationCategoryLabel(type);
    if (fromType.isNotEmpty) return fromType;
    final fromContext = notificationCategoryLabel(context ?? '');
    if (fromContext.isNotEmpty) return fromContext;
    final fromIcon = notificationCategoryLabel(icon ?? '');
    if (fromIcon.isNotEmpty) return fromIcon;
    return 'Notification';
  }

  String get initials {
    final source = sender?.displayName.trim().isNotEmpty == true
        ? sender!.displayName
        : title;
    final parts = source
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();
    if (parts.isEmpty) return 'LU';
    if (parts.length == 1) {
      final value = parts.first.replaceAll(RegExp(r'[^A-Za-z0-9]'), '');
      if (value.isEmpty) return 'LU';
      return value.substring(0, value.length >= 2 ? 2 : 1).toUpperCase();
    }
    final first = parts[0].replaceAll(RegExp(r'[^A-Za-z0-9]'), '');
    final second = parts[1].replaceAll(RegExp(r'[^A-Za-z0-9]'), '');
    if (first.isEmpty && second.isEmpty) return 'LU';
    return '${first.isNotEmpty ? first[0] : ''}${second.isNotEmpty ? second[0] : ''}'
        .toUpperCase();
  }

  String get timeLabel {
    final date = createdAt;
    if (date == null) return '';
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return 'now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 60) return '${diff.inDays}d ago';
    final months = (diff.inDays / 30).floor();
    if (months < 12) return '${months}mo ago';
    return '${(diff.inDays / 365).floor()}y ago';
  }

  factory LinkUpNotificationItem.fromJson(Map<String, dynamic> json) {
    final senderRaw = json['sender'];
    final avatar = ApiUserMapper.resolveMediaUrl(json['avatar']?.toString());
    final sender = senderRaw is Map
        ? LinkUpNotificationSender.fromJson(Map<String, dynamic>.from(senderRaw))
        : null;
    final metadataRaw = json['metadata'];
    return LinkUpNotificationItem(
      id: _asInt(json['id']),
      userId: _asInt(json['user_id']),
      title: (json['title'] ?? '').toString().trim(),
      message: (json['message'] ?? '').toString().trim(),
      sendBy: _asInt(json['send_by']),
      type: (json['type'] ?? '').toString().trim(),
      category: _readCategory(json, metadataRaw),
      context: json['context']?.toString(),
      unread: _asBool(json['unread']),
      priority: _asBool(json['priority']),
      icon: json['icon']?.toString(),
      avatarUrl: avatar.isNotEmpty ? avatar : (sender?.avatarUrl ?? ''),
      metadata: metadataRaw is Map
          ? Map<String, dynamic>.from(metadataRaw)
          : const {},
      createdAt: DateTime.tryParse((json['created_at'] ?? '').toString())
          ?.toLocal(),
      sender: sender,
    );
  }
}

int _asInt(dynamic value) {
  if (value is int) return value;
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

String _readCategory(Map<String, dynamic> json, dynamic metadataRaw) {
  final raw = json['category'] ??
      json['category_name'] ??
      json['notification_category'] ??
      (metadataRaw is Map ? metadataRaw['category'] : null);
  if (raw is Map) {
    return (raw['name'] ??
            raw['label'] ??
            raw['slug'] ??
            raw['type'] ??
            raw['value'] ??
            '')
        .toString()
        .trim();
  }
  return (raw ?? '').toString().trim();
}

int? _asIntOrNull(dynamic value) {
  if (value == null || value is bool) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString().trim());
}

bool _asBool(dynamic value) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  final text = value?.toString().toLowerCase().trim();
  return text == 'true' || text == '1' || text == 'yes';
}

String notificationCategoryLabel(String raw) {
  final value = raw.trim();
  if (value.isEmpty) return '';
  switch (value.toLowerCase().replaceAll('_', '-')) {
    case 'all':
      return '';
    case 'unread':
      return 'Unread';
    case 'message':
    case 'messages':
    case 'quick-reply':
    case 'quick-replys':
    case 'live-invite':
    case 'live-stream':
      return 'Messages';
    case 'match':
    case 'matches':
    case 'match-context':
      return 'Matches';
    case 'payment':
    case 'payments':
    case 'money-transfer':
    case 'ticket-purchase':
    case 'money-request-payment':
    case 'coins-transfer':
      return 'Payments';
    case 'marketplace-order':
    case 'marketplace-orders':
      return 'Orders';
    case 'eat':
    case 'eats':
      return 'Eats';
    case 'event':
    case 'events':
    case 'event-message':
      return 'Events';
    case 'gift':
    case 'gifts':
      return 'Gifts';
    case 'request':
    case 'requests':
    case 'friend-request':
    case 'friend-request-accepted':
    case 'money request':
    case 'asue invitation':
      return 'Requests';
    case 'system':
      return 'System';
    case 'priority':
      return 'Priority';
    default:
      if (value.toLowerCase() == 'all') return '';
      return value
          .split(RegExp(r'[-_\s]+'))
          .where((part) => part.isNotEmpty)
          .map((part) =>
              '${part[0].toUpperCase()}${part.substring(1).toLowerCase()}')
          .join(' ');
  }
}
