import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:link_up/get_controller/auth_controller.dart';
import 'package:link_up/get_controller/base_controller.dart';
import 'package:link_up/helper/app_constant.dart';
import 'package:link_up/helper/router/route_path.dart';
import 'package:link_up/model/choice_model.dart';
import 'package:link_up/model/chat_list_model.dart';
import 'package:link_up/model/chat_detail_result.dart';
import 'package:link_up/model/user_model.dart';
import 'package:link_up/model/chatModel.dart';
import 'package:link_up/model/recent_chat.dart';
import 'package:link_up/services/linkup_api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class ChatController extends BaseController {
  AuthController authController = Get.find(tag: AuthController().toString());

  // List<ContactModel> contactsList = [];
  UserModel? endUser;

  List<Choice> choices = const <Choice>[
    const Choice(name: 'Wi-Fi', icon: Icons.wifi),
    const Choice(name: 'Bluetooth', icon: Icons.bluetooth),
    const Choice(name: 'Battery', icon: Icons.battery_alert),
    const Choice(name: 'Storage', icon: Icons.storage),
  ];

  List matchList = [];
  final recentChatList = <RecentChatModel>[].obs;
  List<ChatUser> allChats = [];
  final chatMessages = <MessageModel>[].obs;
  final isLoadingChats = false.obs;
  final chatsError = RxnString();

  Future<void> getMatchList() async {
    try {
      final matches = await LinkupApiService.fetchAllMatches();
      matchList = matches.map((u) {
        final map = u.toJson();
        map['chat_id'] = u.laravelId?.toString() ?? u.uid;
        map['laravel_id'] = u.laravelId?.toString();
        return map;
      }).toList();
      update();
    } catch (e) {
      print('getMatchList error: $e');
    }
  }

  Future<void> getMessageList() async {
    try {
      isLoadingChats.value = true;
      chatsError.value = null;
      final chats = await LinkupApiService.fetchChatList(
        currentUserId: authController.user?.value.laravelId,
      );
      chats.sort((a, b) {
        if (a.pinned != b.pinned) return a.pinned ? -1 : 1;
        return b.timestamp.compareTo(a.timestamp);
      });
      recentChatList.assignAll(chats);
      print('[Chat] list count=${chats.length} names=${chats.map((c) => c.withName).toList()}');
    } catch (e, stack) {
      chatsError.value = e.toString();
      print('getMessageList error: $e');
      print(stack);
    } finally {
      isLoadingChats.value = false;
    }
  }

  Future<void> getAllChats() async {
    try {
      allChats = await LinkupApiService.fetchAllChats();
      update();
    } catch (e) {
      print('getAllChats error: $e');
    }
  }

  Future<void> getChatHistory(String name, String uid) async {
    try {
      final res = await LinkupApiService.fetchChatDetail(name: name, uid: uid);
      chatMessages.assignAll(res.messages);
      if (res.otherUser != null) {
        endUser = res.otherUser;
      }
      update();
    } catch (e) {
      print(e);
    }
  }

  Future<void> sendMessage(
    String receiverId,
    String? content, {
    File? file,
    String? fileType,
    String? fileName,
    String? historyName,
    String? historyUid,
  }) async {
    try {
      final targetId = int.tryParse(receiverId) != null
          ? receiverId
          : (endUser?.laravelId?.toString() ?? receiverId);

      await LinkupApiService.sendChatMessage(
        receiverId: targetId,
        content: content,
        file: file,
        fileType: fileType,
        fileName: fileName,
      );

      int type = 0;
      if (fileType == 'photo' || fileType == 'image') type = 1;
      if (fileType == 'pdf') type = 7;
      if (fileType == 'gif') type = 8;
      final text = content ?? '';
      if (text.contains('giphy.com') || text.toLowerCase().endsWith('.gif')) type = 8;
      if (text.startsWith('📍') || text.contains('maps.google.com')) type = 0;

      chatMessages.insert(
        0,
        MessageModel(
          content: content,
          attachmentUrl: file?.path,
          senderID: authController.user?.value.laravelId?.toString() ??
              authController.user?.value.uid,
          type: type,
          time: DateTime.now(),
        ),
      );
      update();

      final name = historyName ?? endUser?.firstName ?? '';
      final uid = historyUid ?? endUser?.uid ?? '';
      if (name.isNotEmpty && uid.isNotEmpty) {
        await getChatHistory(name, uid);
      }
    } catch (e) {
      print('sendMessage error: $e');
      rethrow;
    }
  }

  void updateEndUser(UserModel user) {
    endUser = user;
    update();
  }

  // Future<void> contactsData() async {
  //   contactsList.clear();
  //   int index = 0;

  //   new Timer(const Duration(seconds: 5), () async {
  //     SharedPreferences pref = await SharedPreferences.getInstance();
  //     var _userid = pref.getString('user_id');
  //     String usrID = _userid ?? '';
  //     FirebaseFirestore.instance
  //         .collection('matches')
  //         .doc(usrID)
  //         .collection('matches')
  //         .where('me', isEqualTo: true)
  //         .where('friend', isEqualTo: true)
  //         .get()
  //         .then((result) {
  //       result.docs.forEach((doc) {
  //         FirebaseFirestore.instance
  //             .collection('users')
  //             .doc(doc.data()['friendId'])
  //             .get()
  //             .then((value) {
  //           contactsList.insert(
  //             index,
  //             ContactModel(
  //               contactId: doc.data()['friendId'],
  //               name: value.data()?['firstname'] +
  //                   ' ' +
  //                   value.data()?['lastname'],
  //               avatar: value.data()?['avatar'],
  //             ),
  //           );
  //           index++;
  //         });
  //       });
  //     });
  //   });
  // }

  String makeChatId(myID, selectedUserID) {
    String chatID;
    if (myID.hashCode > selectedUserID.hashCode) {
      chatID = '$selectedUserID-$myID';
    } else {
      chatID = '$myID-$selectedUserID';
    }
    return chatID;
  }

  matchesDislike(BuildContext context, String friendId) async {
    try {
      final laravelId = int.tryParse(friendId);
      if (laravelId != null) {
        await LinkupApiService.profileDislike(laravelId);
      }
    } catch (e) {
      print(e);
    }
  }

  // matchesDialog(BuildContext context) {
  //   double width = MediaQuery.of(context).size.width;
  //   double height = MediaQuery.of(context).size.height;
  //   showDialog(
  //     // barrierDismissible: false,
  //     context: context,
  //     builder: (BuildContext context) {
  //       return Scaffold(
  //         backgroundColor: Colors.transparent,
  //         body: Container(
  //           width: width,
  //           height: height,
  //           decoration: BoxDecoration(
  //               image: new DecorationImage(
  //                   image: AssetImage('assets/profile/a.jpg'),
  //                   fit: BoxFit.fill)),
  //           child: Column(
  //             children: [
  //               Column(
  //                 crossAxisAlignment: CrossAxisAlignment.center,
  //                 mainAxisAlignment: MainAxisAlignment.center,
  //                 children: [
  //                   Column(
  //                     children: [
  //                       Container(
  //                         margin: EdgeInsets.only(left: 30, top: 40),
  //                         alignment: Alignment.centerLeft,
  //                         child: GestureDetector(
  //                           onTap: () {
  //                             Navigator.of(context).pop();
  //                           },
  //                           child: Container(
  //                             width: 30,
  //                             height: 30,
  //                             decoration: BoxDecoration(
  //                               color: Colors.white,
  //                               borderRadius:
  //                                   BorderRadius.all(Radius.circular(30)),
  //                               boxShadow: [
  //                                 BoxShadow(
  //                                   color: Colors.grey.withOpacity(0.3),
  //                                   spreadRadius: 7,
  //                                   blurRadius: 7,
  //                                   offset: Offset(
  //                                       0, 3), // changes position of shadow
  //                                 ),
  //                               ],
  //                             ),
  //                             child: Icon(Icons.clear),
  //                           ),
  //                         ),
  //                       ),
  //                       SizedBox(
  //                         height: height * 0.3,
  //                       ),
  //                       Text(
  //                         'Bingo!',
  //                        style: TextStyle(
  //                             color: Colors.tealAccent[400],
  //                             fontSize: 100,
  //                             fontWeight: FontWeight.bold,
  //                             fontStyle: FontStyle.italic),
  //                       ),
  //                       SizedBox(
  //                         height: 10,
  //                       ),
  //                       Text(
  //                         "You've got a Match!",
  //                        style: TextStyle(
  //                             color: Colors.tealAccent[400],
  //                             fontSize: 20,
  //                             fontWeight: FontWeight.bold),
  //                       )
  //                     ],
  //                   ),
  //                 ],
  //               )
  //             ],
  //           ),
  //         ),
  //       );
  //     },
  //   );
  // }

  addSeenToDb({required String userId, required String friendId}) {
    // This previously used Firestore swipes collection.
    // If there is an API for it, we should use it.
  }

  Future<bool> matchesLike(
      BuildContext context, String friendId, String friendAvatar) async {
    try {
      final laravelId = int.tryParse(friendId);
      if (laravelId != null) {
        await LinkupApiService.profileLike(laravelId);
        return true;
      }
      return false;
    } catch (e) {
      print(e);
      return false;
    }
  }

  Future<void> sendGotMatchEmail(String to, String text, String subject) async {
    var response = await http.post(
        Uri.parse(
            'https://us-central1-linkup-cfa21.cloudfunctions.net/sendMail'),
        body: {
          "to": to,
          "subject": subject,
          "text": text,
        });
  }
}
