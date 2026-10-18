import 'package:cloud_firestore/cloud_firestore.dart';

class MessageModel {
  static const int TYPE_TEXT = 0;
  static const int TYPE_IMAGE = 1;
  static const int TYPE_TICKET = 2;
  static const int TYPE_VIDEO_CALL = 3;
  static const int TYPE_AUDIO_CALL = 4;
  static const int TYPE_CALL_ENDED = 5;
  static const int TYPE_STICKER = 6;
  static const int TYPE_PDF = 7;
  static const int TYPE_GIF = 8;

  String? id;
  String? senderID;
  String? receiverToken;
  String? content;
  String? attachmentUrl;
  int? type;

  DateTime? time;
  Map<String, dynamic>? ticket;

  MessageModel({
    this.id,
    this.content,
    this.attachmentUrl,
    this.senderID,
    this.type,
    this.receiverToken,
    this.time,
    this.ticket,
  });

  factory MessageModel.fromMap(dynamic map) {
    DateTime? parsedTime;
    if (map['time'] is DateTime) {
      parsedTime = map['time'];
    } else if (map['time'] is Timestamp) {
      parsedTime = map['time'].toDate();
    } else if (map['time'] is int) {
      parsedTime = DateTime.fromMillisecondsSinceEpoch(map['time']);
    } else if (map['time'] is String) {
      parsedTime = DateTime.tryParse(map['time']);
    }

    return MessageModel(
      senderID: map['senderID'],
      receiverToken: map['receiverToken'],
      content: map['content'],
      time: parsedTime,
      id: map['id'],
      type: map['type'],
    );
  }

  Map<String, dynamic> toMap() {
    Map<String, dynamic> map = <String, dynamic>{};
    map['content'] = content;
    map['receiverToken'] = receiverToken;
    map['type'] = type;
    map['senderID'] = senderID;
    map['time'] = time != null ? Timestamp.fromDate(time!) : null;
    map['id'] = id;
    return map;
  }
}
