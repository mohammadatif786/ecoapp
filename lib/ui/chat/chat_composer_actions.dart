import 'dart:io';

import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';

class ChatPickedFile {
  final File file;
  final String type;
  final String name;

  const ChatPickedFile({required this.file, required this.type, required this.name});
}

class ChatComposerActions {
  static const gifs = [
    'https://i.giphy.com/media/3o7TKQH37v29f0J8Z6/giphy.gif',
    'https://i.giphy.com/media/l0HlU0S6vH4YyM1O0/giphy.gif',
    'https://i.giphy.com/media/3o7TKVUn7iM8FMEU24/giphy.gif',
    'https://i.giphy.com/media/l0Exv63f7r1K4T596/giphy.gif',
    'https://i.giphy.com/media/3o7TKDkDbIDJieKbVm/giphy.gif',
    'https://i.giphy.com/media/l0HlU7m6U6q9P3u6E/giphy.gif',
  ];

  static Future<void> showEmojiPicker({
    required BuildContext context,
    required TextEditingController controller,
    VoidCallback? onChanged,
  }) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => Container(
        height: 360,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 10, bottom: 6),
              height: 5,
              width: 40,
              decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10)),
            ),
            Expanded(
              child: EmojiPicker(
                onEmojiSelected: (category, emoji) {
                  controller.text = '${controller.text}${emoji.emoji}';
                  controller.selection = TextSelection.collapsed(offset: controller.text.length);
                  onChanged?.call();
                },
                config: Config(
                  height: 256,
                  checkPlatformCompatibility: true,
                  emojiViewConfig: EmojiViewConfig(
                    columns: 7,
                    emojiSizeMax: 32 * (Platform.isIOS ? 1.30 : 1.0),
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
                    indicatorColor: Color(0xff2f9bef),
                    iconColor: Colors.grey,
                    iconColorSelected: Color(0xff2f9bef),
                    backspaceColor: Color(0xff2f9bef),
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

  static Future<String?> showGifPicker(BuildContext context) {
    return showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) => Container(
        height: MediaQuery.of(sheetContext).size.height * 0.58,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 8, 8),
              child: Row(
                children: [
                  const Expanded(
                    child: Text('Send a GIF', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                  ),
                  IconButton(onPressed: () => Navigator.pop(sheetContext), icon: const Icon(Icons.close)),
                ],
              ),
            ),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                ),
                itemCount: gifs.length,
                itemBuilder: (_, index) {
                  final url = gifs[index];
                  return GestureDetector(
                    onTap: () => Navigator.pop(sheetContext, url),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        url,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: const Color(0xfff1f5f9),
                          child: const Icon(Icons.gif, size: 40, color: Colors.grey),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Future<ChatPickedFile?> pickPhoto() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 85, maxWidth: 1920);
    if (picked == null) return null;
    return ChatPickedFile(file: File(picked.path), type: 'photo', name: picked.name);
  }

  static Future<ChatPickedFile?> pickPdf() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['pdf'],
    );
    final path = result?.files.single.path;
    if (path == null) return null;
    return ChatPickedFile(
      file: File(path),
      type: 'pdf',
      name: result!.files.single.name,
    );
  }

  static Future<String?> currentLocationContent() async {
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
      return null;
    }
    final enabled = await Geolocator.isLocationServiceEnabled();
    if (!enabled) return null;
    final position = await Geolocator.getCurrentPosition(locationSettings: const LocationSettings(accuracy: LocationAccuracy.high));
    return '📍 https://maps.google.com/?q=${position.latitude},${position.longitude}';
  }
}
