import 'package:link_up/model/chatModel.dart';
import 'package:link_up/model/user_model.dart';

class ChatDetailResult {
  final List<MessageModel> messages;
  final UserModel? otherUser;

  ChatDetailResult({
    required this.messages,
    this.otherUser,
  });
}
