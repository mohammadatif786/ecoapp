class ChatMessageModel {
  final int id;
  final int fromUserId;
  final int toUserId;
  final String content;
  final String type;
  final dynamic meta;
  final DateTime createdAt;
  final int isRead;

  ChatMessageModel({
    required this.id,
    required this.fromUserId,
    required this.toUserId,
    required this.content,
    required this.type,
    this.meta,
    required this.createdAt,
    required this.isRead,
  });

  factory ChatMessageModel.fromJson(Map<String, dynamic> json) {
    return ChatMessageModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      fromUserId: (json['from_user_id'] as num?)?.toInt() ?? 0,
      toUserId: (json['to_user_id'] as num?)?.toInt() ?? 0,
      content: json['content']?.toString() ?? '',
      type: json['type']?.toString() ?? 'text',
      meta: json['meta'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      isRead: (json['is_read'] as num?)?.toInt() ?? 0,
    );
  }

  bool isMe(int? currentUserId) => fromUserId == currentUserId;
  
  String? get imageUrl {
    if ((type == 'photo' || type == 'image') && meta is Map) {
      return meta['url']?.toString();
    }
    // Fallback if URL is directly in content for photos
    if ((type == 'photo' || type == 'image') && content != null && content!.startsWith('http')) {
      return content;
    }
    return null;
  }

  bool get isTicket => type == 'ticket' && meta is Map;

  String? get ticketEvent => isTicket ? meta['event']?.toString() : null;
  String? get ticketIdLabel => isTicket ? meta['ticket_id']?.toString() : null;
  String? get ticketDate => isTicket ? meta['date_label']?.toString() : null;
  String? get ticketVenue => isTicket ? meta['venue']?.toString() : null;
  String? get ticketToken => isTicket ? meta['token']?.toString() : null;
}
