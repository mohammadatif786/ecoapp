import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:open_file/open_file.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:link_up/get_controller/ChatController.dart';
import 'package:link_up/get_controller/auth_controller.dart';
import 'package:link_up/helper/router/route_path.dart';
import 'package:link_up/model/chatModel.dart';
import 'package:link_up/model/user_model.dart';
import 'package:pretty_qr_code/pretty_qr_code.dart';
import 'package:intl/intl.dart';
import 'package:link_up/ui/api_eticket.dart';
import 'package:link_up/widgets/pdf_screen.dart';
import 'package:link_up/ui/chat/chat_composer_actions.dart';
import 'package:link_up/services/linkup_api_service.dart';

class ChatMessagePage extends StatefulWidget {
  final String endUserID;
  final String endUserName;
  final String chatID;

  const ChatMessagePage({
    required this.endUserID,
    required this.endUserName,
    required this.chatID,
    Key? key,
  }) : super(key: key);

  @override
  _ChatMessagePageState createState() => _ChatMessagePageState();
}

class _ChatMessagePageState extends State<ChatMessagePage> {
  AuthController authController = Get.find(tag: AuthController().toString());
  ChatController chatController = Get.find(tag: ChatController().toString());

  bool _isWriting = false;
  bool _showEmoji = false;
  TextEditingController _textController = TextEditingController();
  ScrollController _scrollController = ScrollController();
  Timer? _timer;
  final ImagePicker _picker = ImagePicker();

  File? _preparedFile;
  String? _preparedFileType;
  String? _preparedFileName;

  @override
  void initState() {
    super.initState();
    _fetchMessages();
    _timer = Timer.periodic(Duration(seconds: 5), (timer) {
      _fetchMessages();
    });
  }

  void _fetchMessages() {
    chatController.getChatHistory(widget.endUserName, widget.endUserID).then((_) {
      _scrollToBottom();
    });
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0.0,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFE8F4FA),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Color.fromARGB(255, 56, 171, 216),
        title: Text(widget.endUserName),
      ),
      body: Column(
        children: [
          Expanded(
            child: GetBuilder<ChatController>(
              builder: (controller) {
                if (controller.chatMessages.isEmpty) {
                  return Center(child: Text('no_message'.tr));
                }
                return ListView.builder(
                  controller: _scrollController,
                  padding: EdgeInsets.all(10),
                  reverse: true,
                  itemCount: controller.chatMessages.length,
                  itemBuilder: (context, index) {
                    // Reverse because messages are usually returned newest first from APIs, 
                    // or we want them bottom-up.
                    final message = controller.chatMessages[index];
                    bool isMe = message.senderID == authController.user?.value.uid || 
                               message.senderID == authController.user?.value.laravelId?.toString();
                    return _buildMessageItem(message, isMe);
                  },
                );
              },
            ),
          ),
          Divider(height: 1),
          _buildTextComposer(),
        ],
      ),
    );
  }

  Widget _buildMessageItem(MessageModel message, bool isMe) {
    if (message.type == 2 && message.ticket != null) {
      return _buildTicketCard(message.ticket!);
    }
    if (message.type == 3) return _buildCallLog('Video call started', isMe, canJoin: true);
    if (message.type == 4) return _buildCallLog('Audio call started', isMe, canJoin: true);
    if (message.type == 5) return _buildCallLog('Call ended', isMe);
    if (message.type == 6) return _buildSticker(message, isMe);

    // Detect if content is a media URL (like Giphy) in a text message
    if ((message.type == 0 || message.type == null) && message.content != null && message.content!.startsWith('http')) {
      String url = message.content!.toLowerCase();
      if (url.contains('giphy.com') || url.contains('giphy.gif') || url.endsWith('.gif')) {
        return _buildGifCard(MessageModel(
          attachmentUrl: message.content,
          time: message.time,
          senderID: message.senderID,
          type: 8,
          id: message.id,
        ), isMe);
      }
      if (url.endsWith('.jpg') || url.endsWith('.jpeg') || url.endsWith('.png') || url.endsWith('.webp')) {
        return _buildPhotoCard(MessageModel(
          attachmentUrl: message.content,
          time: message.time,
          senderID: message.senderID,
          type: 1,
          id: message.id,
        ), isMe);
      }
    }

    // Photo Card
    if (message.type == 1 &&
        message.attachmentUrl != null &&
        message.attachmentUrl!.startsWith('http')) {
      return _buildPhotoCard(message, isMe);
    }

    // PDF Card
    if (message.type == 7 || (message.attachmentUrl != null && message.attachmentUrl!.toLowerCase().endsWith('.pdf'))) {
      return _buildPdfCard(message, isMe);
    }

    // GIF Card
    if (message.type == 8 || (message.attachmentUrl != null && message.attachmentUrl!.toLowerCase().endsWith('.gif'))) {
      return _buildGifCard(message, isMe);
    }

    return Container(
      margin: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
      child: Row(
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isMe ? Color(0xFFD6EEFF) : Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(15),
                topRight: Radius.circular(15),
                bottomLeft: isMe ? Radius.circular(15) : Radius.circular(0),
                bottomRight: isMe ? Radius.circular(0) : Radius.circular(15),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 5,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.7),
            child: Column(
              crossAxisAlignment:
                  isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Text(
                  message.content ?? '',
                  style: TextStyle(
                    color: Colors.black87,
                    fontSize: 14,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  message.time != null
                      ? DateFormat('HH:mm').format(message.time!)
                      : '',
                  style: TextStyle(fontSize: 10, color: Colors.black45),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoCard(MessageModel message, bool isMe) {
    String? url = message.attachmentUrl;
    String fileName = url?.split('/').last ?? 'image.jpg';
    if (fileName.contains('?')) fileName = fileName.split('?').first;

    return Container(
      margin: EdgeInsets.symmetric(vertical: 8, horizontal: 10),
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.75,
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Photo',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: Colors.black,
                  ),
                ),
                Expanded(
                  child: Text(
                    fileName,
                    textAlign: TextAlign.right,
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black87),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.network(
                url ?? '',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    Container(
                      height: 150,
                      color: Colors.grey[200],
                      child: Center(child: Icon(Icons.error_outline, color: Colors.grey)),
                    ),
              ),
            ),
            SizedBox(height: 8),
            Align(
              alignment: Alignment.bottomRight,
              child: Text(
                message.time != null ? DateFormat('HH:mm').format(message.time!) : '',
                style: TextStyle(fontSize: 10, color: Colors.black45, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPdfCard(MessageModel message, bool isMe) {
    String? url = message.attachmentUrl;
    String fileName = url?.split('/').last ?? 'Document.pdf';
    if (fileName.contains('?')) fileName = fileName.split('?').first;

    return Container(
      margin: EdgeInsets.symmetric(vertical: 8, horizontal: 10),
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.75,
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'PDF',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: Colors.black,
                  ),
                ),
                Expanded(
                  child: Text(
                    fileName,
                    textAlign: TextAlign.right,
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black87),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey[200]!, style: BorderStyle.solid),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      fileName,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Colors.black,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () async {
                      if (url != null && url.startsWith('http')) {
                        Get.to(() => PDFScreen(arg: {
                              'title': fileName,
                              'url': url,
                            }));
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[100],
                      foregroundColor: Colors.black,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(color: Colors.grey[300]!),
                      ),
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      minimumSize: Size(60, 36),
                    ),
                    child: Text(
                      'Open',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 8),
            Align(
              alignment: Alignment.bottomRight,
              child: Text(
                message.time != null ? DateFormat('HH:mm').format(message.time!) : '',
                style: TextStyle(fontSize: 10, color: Colors.black45, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGifCard(MessageModel message, bool isMe) {
    String? url = message.attachmentUrl;
    String fileName = url?.split('/').last ?? 'giphy.gif';
    if (fileName.contains('?')) fileName = fileName.split('?').first;

    return Container(
      margin: EdgeInsets.symmetric(vertical: 8, horizontal: 10),
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.75,
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'GIF',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: Colors.black,
                  ),
                ),
                Expanded(
                  child: Text(
                    fileName,
                    textAlign: TextAlign.right,
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black87),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.network(
                url ?? '',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    Icon(Icons.gif, size: 50, color: Colors.grey),
              ),
            ),
            SizedBox(height: 8),
            Align(
              alignment: Alignment.bottomRight,
              child: Text(
                message.time != null ? DateFormat('HH:mm').format(message.time!) : '',
                style: TextStyle(fontSize: 10, color: Colors.black45, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCallLog(String text, bool isMe, {bool canJoin = false}) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 8, horizontal: 10),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5, offset: Offset(0, 2))
              ],
              border: Border.all(color: Colors.grey[100]!),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.phone_callback, size: 16, color: Colors.grey),
                SizedBox(width: 8),
                Text(text, style: TextStyle(fontSize: 13, color: Colors.black87, fontWeight: FontWeight.w500)),
                if (canJoin) ...[
                  SizedBox(width: 12),
                  GestureDetector(
                    onTap: () {
                      // Action to join call
                    },
                    child: Text(
                      'Join Call',
                      style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ),
                ]
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSticker(MessageModel message, bool isMe) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: message.content != null && message.content!.startsWith('http')
          ? Image.network(
              message.content!,
              width: 120,
              height: 120,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => Icon(Icons.sentiment_satisfied_alt, size: 50, color: Colors.grey),
            )
          : Text('Sticker'),
    );
  }

  Widget _buildTicketCard(Map<String, dynamic> ticket) {
    final event = ticket['event'] ?? {};
    final eventTitle = event['title'] ?? 'Event';
    final eventSubtitle = event['category'] ?? 'Event Details';
    final eventDateStr =
        event['single_event_date'] ?? ticket['created_at'] ?? '';
    DateTime? eventDate;
    if (eventDateStr.isNotEmpty) {
      eventDate = DateTime.tryParse(eventDateStr);
    }
    final formattedDate = eventDate != null
        ? DateFormat('dd/MM/yyyy • hh:mm a').format(eventDate)
        : eventDateStr;

    final venue = event['venue'] ?? '';
    final city = event['city'] ?? '';
    final country = event['country'] ?? '';
    final location = [venue, city, country]
        .where((s) => s != null && s.isNotEmpty)
        .join(', ');

    final ticketId = ticket['ticket_qrcode'] ?? '';
    final ticketDisplayId = 'LU-TKT-${ticket['ticket_id'] ?? ticket['id']}';

    return Container(
      margin: EdgeInsets.symmetric(vertical: 8, horizontal: 10),
      alignment: Alignment.centerLeft,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        eventTitle,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Colors.black87,
                        ),
                      ),
                      Text(
                        eventSubtitle,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Color(0xFFE3F2FD),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Ticket',
                    style: TextStyle(
                      color: Color(0xFF1976D2),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 100,
                  height: 100,
                  padding: EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[100]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: PrettyQrView.data(
                    data: ticketId,
                    decoration: const PrettyQrDecoration(),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _ticketDetailRow(Icons.confirmation_number_outlined,
                          '🎟️ Ticket ID: $ticketDisplayId'),
                      _ticketDetailRow(Icons.location_on_outlined, '📍 $location'),
                      _ticketDetailRow(
                          Icons.check_circle_outline, '✅ QR is the key — scan to validate entry.',
                          color: Colors.green),
                      _ticketDetailRow(Icons.qr_code_scanner, '📂 QR payload = signed token.'),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Get.to(() => ApiETicket(ticket: ticket));
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF38ABD8),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: EdgeInsets.symmetric(vertical: 10),
                ),
                child: Text(
                  'Open Ticket',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
            SizedBox(height: 6),
            Align(
              alignment: Alignment.bottomRight,
              child: Text(
                ticket['created_at'] != null
                    ? DateFormat('HH:mm').format(DateTime.parse(ticket['created_at']))
                    : '',
                style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _ticketDetailRow(IconData icon, String text, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(icon, size: 14, color: color ?? Colors.black54),
          SizedBox(width: 5),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 10, color: color ?? Colors.black87),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextComposer() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildPreparedAttachment(),
          _buildAttachmentBar(),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 15),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _textController,
                            onTap: () {
                              if (_showEmoji) {
                                setState(() {
                                  _showEmoji = false;
                                });
                              }
                            },
                            onChanged: (text) {
                              setState(() {
                                _isWriting = text.trim().isNotEmpty;
                              });
                            },
                            style: TextStyle(fontSize: 14),
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              hintText: 'Type a message... add emojis and send attachments',
                              hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(width: 12),
                GestureDetector(
                  onTap: (_isWriting || _preparedFile != null)
                      ? () => _handleSubmitted(_textController.text)
                      : null,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    decoration: BoxDecoration(
                      color: (_isWriting || _preparedFile != null) ? Color(0xFF38ABD8) : Colors.grey[300],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Send',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_showEmoji)
            Offstage(
              offstage: !_showEmoji,
              child: EmojiPicker(
                onEmojiSelected: (category, emoji) {
                  _textController.text = _textController.text + emoji.emoji;
                  setState(() {
                    _isWriting = true;
                  });
                },
                config: Config(
                  height: 256,
                  checkPlatformCompatibility: true,
                  emojiViewConfig: EmojiViewConfig(
                    columns: 7,
                    emojiSizeMax: 32 * (Platform.isIOS ? 1.30 : 1.0),
                    verticalSpacing: 0,
                    horizontalSpacing: 0,
                    gridPadding: EdgeInsets.zero,
                    noRecents: const Text(
                      'No Recents',
                      style: TextStyle(fontSize: 20, color: Colors.black26),
                      textAlign: TextAlign.center,
                    ),
                    buttonMode: ButtonMode.MATERIAL,
                  ),
                  categoryViewConfig: const CategoryViewConfig(
                    initCategory: Category.RECENT,
                    backgroundColor: Color(0xFFF2F2F2),
                    indicatorColor: Colors.blue,
                    iconColor: Colors.grey,
                    iconColorSelected: Colors.blue,
                    backspaceColor: Colors.blue,
                  ),
                  bottomActionBarConfig: const BottomActionBarConfig(
                    buttonColor: Color(0xFFF2F2F2),
                    buttonIconColor: Colors.grey,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAttachmentBar() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Colors.grey[100]!),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _attachmentButton('😋 Emojis', Colors.white, () => _showEmojiModal()),
                SizedBox(width: 8),
                _attachmentButton('🏞️ GIF', Colors.white, () => _pickGif()),
                SizedBox(width: 8),
                _attachmentButton('🖼️ Photo', Colors.white, () => _pickImage()),
                SizedBox(width: 8),
                _attachmentButton('📎 PDF', Colors.white, () => _pickPdf()),
                SizedBox(width: 8),
                _attachmentButton('📍 Location', Colors.white, () => _sendLocation()),
                SizedBox(width: 8),
                _attachmentButton('🎟️ Ticket', Colors.white, () => _pickTicket()),
              ],
            ),
          ),
          SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Text(
                'Pick › preview › send',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreparedAttachment() {
    if (_preparedFile == null) return SizedBox.shrink();

    return Container(
      padding: EdgeInsets.all(12),
      margin: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: Offset(0, 5))
        ],
        border: Border.all(color: Colors.grey[100]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Attachments ready',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87),
              ),
              GestureDetector(
                onTap: () {
                  setState(() {
                    _preparedFile = null;
                    _preparedFileType = null;
                    _preparedFileName = null;
                  });
                },
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text('Clear', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 10)),
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[200]!, style: BorderStyle.solid),
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _preparedFileType == 'pdf' ? Icons.picture_as_pdf : Icons.image,
                    color: _preparedFileType == 'pdf' ? Colors.red : Colors.blue,
                    size: 24,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _preparedFileName ?? 'File',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '${(_preparedFile!.lengthSync() / 1024).toStringAsFixed(0)} KB',
                        style: TextStyle(fontSize: 10, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close, size: 18, color: Colors.grey[400]),
                  onPressed: () {
                    setState(() {
                      _preparedFile = null;
                      _preparedFileType = null;
                      _preparedFileName = null;
                    });
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showEmojiModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: 350,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              margin: EdgeInsets.only(top: 10, bottom: 5),
              height: 5,
              width: 40,
              decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10)),
            ),
            Expanded(
              child: EmojiPicker(
                onEmojiSelected: (category, emoji) {
                  _textController.text = _textController.text + emoji.emoji;
                  setState(() {
                    _isWriting = true;
                  });
                  Get.back();
                },
                config: Config(
                  height: 256,
                  checkPlatformCompatibility: true,
                  emojiViewConfig: EmojiViewConfig(
                    columns: 7,
                    emojiSizeMax: 32 * (Platform.isIOS ? 1.30 : 1.0),
                    verticalSpacing: 0,
                    horizontalSpacing: 0,
                    gridPadding: EdgeInsets.zero,
                    noRecents: const Text(
                      'No Recents',
                      style: TextStyle(fontSize: 20, color: Colors.black26),
                      textAlign: TextAlign.center,
                    ),
                    buttonMode: ButtonMode.MATERIAL,
                  ),
                  categoryViewConfig: const CategoryViewConfig(
                    initCategory: Category.RECENT,
                    backgroundColor: Color(0xFFF2F2F2),
                    indicatorColor: Colors.blue,
                    iconColor: Colors.grey,
                    iconColorSelected: Colors.blue,
                    backspaceColor: Colors.blue,
                  ),
                  bottomActionBarConfig: const BottomActionBarConfig(
                    buttonColor: Color(0xFFF2F2F2),
                    buttonIconColor: Colors.grey,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _attachmentButton(String label, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ),
    );
  }

  void _pickTicket() async {
    final token = await LinkupApiService.getToken();
    List<Map<String, dynamic>> myTickets = [];

    // Attempt to fetch tickets from ChatDetail response if available, 
    // or simulate fetching from a dedicated endpoint if one existed.
    // For now, we use the ones already in chat history to populate the list.
    final existingTickets = chatController.chatMessages
        .where((m) => m.type == 2 && m.ticket != null)
        .map((m) => m.ticket!)
        .toList();
    
    myTickets = List<Map<String, dynamic>>.from(existingTickets);

    Get.dialog(
      Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 40),
        child: Container(
          width: double.infinity,
          height: MediaQuery.of(context).size.height * 0.8,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: _TicketShareModal(
            tickets: myTickets,
            onSend: (ticket) async {
              Get.back();
              // Simulating sending a ticket via API
              // In a real app, you'd call a dedicated 'share ticket' endpoint
              await chatController.sendMessage(
                widget.chatID,
                'Ticket: ${ticket['event']?['title'] ?? 'Event'}',
                // Assuming type 2 is ticket
              );
              _fetchMessages();
            },
          ),
        ),
      ),
    );
  }

  void _pickGif() async {
    // Selection of GIF picking with simpler, more stable URLs
    final List<String> sampleGifs = [
      'https://i.giphy.com/media/3o7TKQH37v29f0J8Z6/giphy.gif',
      'https://i.giphy.com/media/l0HlU0S6vH4YyM1O0/giphy.gif',
      'https://i.giphy.com/media/3o7TKVUn7iM8FMEU24/giphy.gif',
      'https://i.giphy.com/media/l0Exv63f7r1K4T596/giphy.gif',
      'https://i.giphy.com/media/3o7TKDkDbIDJieKbVm/giphy.gif',
      'https://i.giphy.com/media/l0HlU7m6U6q9P3u6E/giphy.gif',
    ];

    Get.dialog(
      AlertDialog(
        title: Text('Select a GIF'),
        content: SizedBox(
          width: double.maxFinite,
          child: GridView.builder(
            shrinkWrap: true,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, mainAxisSpacing: 8, crossAxisSpacing: 8),
            itemCount: sampleGifs.length,
            itemBuilder: (context, index) {
              return GestureDetector(
                onTap: () async {
                  Get.back();
                  // Send directly as a text message containing the URL
                  // Our _buildMessageItem will catch this and render it as a GIF card
                  await chatController.sendMessage(
                    widget.chatID, 
                    sampleGifs[index],
                  );
                  _fetchMessages();
                },
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    sampleGifs[index], 
                    fit: BoxFit.cover, 
                    errorBuilder: (c, e, s) => Container(color: Colors.grey[100], child: Icon(Icons.gif, color: Colors.grey)),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  void _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _preparedFile = File(image.path);
        _preparedFileType = 'photo';
        _preparedFileName = image.name;
      });
    }
  }

  void _pickPdf() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (result != null && result.files.single.path != null) {
        setState(() {
          _preparedFile = File(result.files.single.path!);
          _preparedFileType = 'pdf';
          _preparedFileName = result.files.single.name;
        });
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to pick PDF: $e',
          snackPosition: SnackPosition.BOTTOM);
    }
  }

  void _handleSubmitted(String text) async {
    String? content = text.trim();
    if (content.isEmpty && _preparedFile == null) return;

    _textController.clear();
    File? fileToSend = _preparedFile;
    String? typeToSend = _preparedFileType;
    String? nameToSend = _preparedFileName;

    setState(() {
      _isWriting = false;
      _preparedFile = null;
      _preparedFileType = null;
      _preparedFileName = null;
    });

    try {
      if (content.isNotEmpty && fileToSend != null) {
        await chatController.sendMessage(widget.chatID, content);
        await chatController.sendMessage(
          widget.chatID,
          null,
          file: fileToSend,
          fileType: typeToSend,
          fileName: nameToSend,
        );
      } else {
        await chatController.sendMessage(
          widget.chatID,
          content.isNotEmpty ? content : null,
          file: fileToSend,
          fileType: typeToSend,
          fileName: nameToSend,
        );
      }
      _fetchMessages();
    } catch (e) {
      Get.snackbar('Error', 'Could not send message', snackPosition: SnackPosition.BOTTOM);
    }
  }

  Future<void> _sendLocation() async {
    try {
      final content = await ChatComposerActions.currentLocationContent();
      if (content == null) {
        Get.snackbar('Location', 'Allow location access to share it.', snackPosition: SnackPosition.BOTTOM);
        return;
      }
      await chatController.sendMessage(widget.chatID, content);
      _fetchMessages();
    } catch (e) {
      Get.snackbar('Error', 'Could not share location', snackPosition: SnackPosition.BOTTOM);
    }
  }
}

class _TicketShareModal extends StatefulWidget {
  final List<Map<String, dynamic>> tickets;
  final Function(Map<String, dynamic>) onSend;

  const _TicketShareModal({required this.tickets, required this.onSend});

  @override
  State<_TicketShareModal> createState() => _TicketShareModalState();
}

class _TicketShareModalState extends State<_TicketShareModal> {
  Map<String, dynamic>? selectedTicket;
  String searchQuery = '';
  String filter = 'All';

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Share a Ticket', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              IconButton(icon: Icon(Icons.close), onPressed: () => Get.back()),
            ],
          ),
        ),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              bool isMobile = constraints.maxWidth < 500;
              if (isMobile) {
                return Column(
                  children: [
                    Expanded(child: _buildListSection()),
                    if (selectedTicket != null)
                      Container(
                        height: 320,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border(top: BorderSide(color: Colors.grey[200]!)),
                          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
                        ),
                        child: SingleChildScrollView(child: _buildPreviewSection(isMobile: true)),
                      ),
                  ],
                );
              }
              return Row(
                children: [
                  Expanded(flex: 3, child: _buildListSection()),
                  Expanded(flex: 2, child: _buildPreviewSection()),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildListSection() {
    final filteredTickets = widget.tickets.where((t) {
      final title = (t['event']?['title'] ?? '').toString().toLowerCase();
      return title.contains(searchQuery.toLowerCase());
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('TICKET SECTION', style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
              Text('My Tickets', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              SizedBox(height: 10),
              TextField(
                onChanged: (v) => setState(() => searchQuery = v),
                decoration: InputDecoration(
                  hintText: 'Search tickets...',
                  prefixIcon: Icon(Icons.search, size: 20),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey[300]!)),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              SizedBox(height: 10),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: ['All', 'Upcoming', 'Past'].map((e) => Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ChoiceChip(
                      label: Text(e, style: TextStyle(fontSize: 12)),
                      selected: filter == e,
                      onSelected: (s) => setState(() => filter = e),
                      selectedColor: Colors.blue[50],
                      labelStyle: TextStyle(color: filter == e ? Colors.blue : Colors.black),
                    ),
                  )).toList(),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: filteredTickets.length,
            itemBuilder: (context, index) {
              final ticket = filteredTickets[index];
              final isSelected = selectedTicket == ticket;
              return Container(
                margin: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: isSelected ? Colors.blue : Colors.grey[200]!),
                  color: isSelected ? Colors.blue[50]?.withOpacity(0.1) : Colors.white,
                ),
                child: ListTile(
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  leading: Checkbox(
                    value: isSelected,
                    onChanged: (v) => setState(() => selectedTicket = ticket),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                  ),
                  title: Text(
                    ticket['event']?['title'] ?? 'Event',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text('LU-SALE-${ticket['id']}', style: TextStyle(fontSize: 11)),
                  trailing: ElevatedButton(
                    onPressed: () => setState(() => selectedTicket = ticket),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      minimumSize: Size(60, 30),
                    ),
                    child: Text('Preview ›', style: TextStyle(fontSize: 10)),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPreviewSection({bool isMobile = false}) {
    return Container(
      padding: EdgeInsets.all(16),
      color: isMobile ? Colors.white : Colors.grey[50],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('PREVIEW & SEND', style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
          Text('Ticket Preview (QR-first)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          SizedBox(height: 12),
          if (selectedTicket != null) ...[
            Text(selectedTicket!['event']?['title'] ?? '', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
            Text('Ticket ID: LU-SALE-${selectedTicket!['id']}', style: TextStyle(fontSize: 12, color: Colors.grey)),
            SizedBox(height: 10),
            Row(
              children: [
                _actionBtn(Icons.copy, 'Copy ID'),
                SizedBox(width: 8),
                _actionBtn(Icons.qr_code, 'Copy Token'),
              ],
            ),
            SizedBox(height: 12),
            Text('SIGNED TOKEN', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(10)),
              child: Text(
                selectedTicket!['ticket_qrcode'] ?? 'No Token',
                style: TextStyle(color: Colors.white, fontSize: 10, fontFamily: 'Courier', fontFamilyFallback: ['monospace']),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (!isMobile) Spacer(),
            if (isMobile) SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => widget.onSend(selectedTicket!),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                minimumSize: Size(double.infinity, 45),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: Text('Send to Chat'),
            ),
          ] else
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.confirmation_number_outlined, size: 48, color: Colors.grey[300]),
                    SizedBox(height: 10),
                    Text('Select a ticket to preview', style: TextStyle(color: Colors.grey)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _actionBtn(IconData icon, String label) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14),
          SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
