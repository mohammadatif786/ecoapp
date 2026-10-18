class RecentChatModel {
  RecentChatModel({
    required this.lastText,
    required this.withAvatar,
    required this.withName,
    required this.withId,
    required this.chatId,
    required this.timestamp,
    this.countryCode = '',
    this.countryFlag = '',
    this.pinned = false,
    this.isUnread = false,
  });

  String lastText;
  String withAvatar;
  String withName;
  String withId;
  String chatId;
  int timestamp;
  String countryCode;
  String countryFlag;
  bool pinned;
  bool isUnread;

  String get apiName {
    final parts = withName.trim().split(RegExp(r'\s+'));
    return parts.isEmpty ? withName : parts.first;
  }

  static int parseInt(dynamic value) {
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static String previewFromContent(String? content, [String type = 'text']) {
    final raw = (content ?? '').trim();
    if (raw.isEmpty) return 'No messages yet';
    final lower = raw.toLowerCase();
    if (raw.startsWith('__CALL_END__')) {
      return lower.contains('video') ? 'Video call ended' : 'Call ended';
    }
    if (raw.startsWith('__CALL_INVITE_AUDIO__')) return 'Voice call';
    if (raw.startsWith('__CALL_INVITE__')) return 'Video call';
    if (raw.startsWith('📍') || lower.contains('maps.google.com') || lower.contains('maps.apple.com')) {
      return '📍 Location';
    }
    if (type == 'image' || type == 'photo') return '📷 Photo';
    if (type == 'pdf') return '📎 PDF';
    if (type == 'gif') return 'GIF';
    if (type == 'sticker') return 'Sticker';
    return raw;
  }

  factory RecentChatModel.fromJson(Map<String, dynamic> json) =>
      RecentChatModel(
        lastText: json["lastText"]?.toString() ?? "",
        withAvatar: json["withAvatar"]?.toString() ?? "",
        withName: json["withName"]?.toString() ?? "",
        withId: json["withID"]?.toString() ?? json["withId"]?.toString() ?? "",
        chatId: json['chatID']?.toString() ?? json['chatId']?.toString() ?? "",
        timestamp: json["timestamp"] is int ? json["timestamp"] : int.tryParse(json["timestamp"]?.toString() ?? '') ?? 0,
        countryCode: json["countryCode"]?.toString() ?? "",
        countryFlag: json["countryFlag"]?.toString() ?? "",
        pinned: json["pinned"] == true || json["pinned"] == 1,
        isUnread: json["isUnread"] == true || json["isUnread"] == 1,
      );

  Map<String, dynamic> toJson() => {
        "lastText": lastText,
        "withAvatar": withAvatar,
        "withName": withName,
        "withID": withId,
        "chatID": chatId,
        "timestamp": timestamp,
        "countryCode": countryCode,
        "countryFlag": countryFlag,
        "pinned": pinned,
        "isUnread": isUnread,
      };
}
