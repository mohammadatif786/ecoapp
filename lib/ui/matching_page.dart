import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:link_up/get_controller/ChatController.dart';
import 'package:link_up/get_controller/auth_controller.dart';
import 'package:link_up/helper/router/route_path.dart';
import 'package:link_up/ui/chat/chat_message_page.dart';

class MatchingPage extends StatefulWidget {
  final String friendID;
  final String avatar;
  const MatchingPage({required this.friendID, required this.avatar, Key? key})
      : super(key: key);

  @override
  _MatchingPageState createState() => _MatchingPageState();
}

class _MatchingPageState extends State<MatchingPage> {
  AuthController authController = Get.find(tag: AuthController().toString());
  ChatController chatController = Get.find(tag: ChatController().toString());

  TextEditingController _textController = new TextEditingController();
  String friendName = '';

  _sendText(String text) async {
    await chatController.sendMessage(widget.friendID, text);
    
    Get.offNamed(
      RoutePath.chat_message_page,
      arguments: {
        'endUserID': widget.friendID,
        'endUserName': friendName,
        'chatID': '',
      },
    );
  }

  @override
  void initState() {
    super.initState();
    _textController.text = '';
    // We could fetch friend name here if needed, but for now we'll use a placeholder
    // or wait for the chat page to load it.
    friendName = 'New Match'; 
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    double height = MediaQuery.of(context).size.height;
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: GetBuilder(
          init: authController,
          builder: (_) {
            return Container(
                width: width,
                height: height,
                decoration: BoxDecoration(
                    image: new DecorationImage(
                        image: NetworkImage(widget.avatar), fit: BoxFit.fill)),
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Column(
                            children: [
                              Container(
                                margin: EdgeInsets.only(left: 30, top: 40),
                                alignment: Alignment.centerLeft,
                                child: GestureDetector(
                                  onTap: () {
                                    Get.offAllNamed(RoutePath.chat_home_page);
                                  },
                                  child: Container(
                                    width: 30,
                                    height: 30,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius:
                                          BorderRadius.all(Radius.circular(30)),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.grey.withOpacity(0.3),
                                          spreadRadius: 7,
                                          blurRadius: 7,
                                          offset: Offset(0,
                                              3), // changes position of shadow
                                        ),
                                      ],
                                    ),
                                    child: Icon(Icons.clear, color: Colors.black),
                                  ),
                                ),
                              ),
                              SizedBox(
                                height: height * 0.2,
                              ),
                              Text(
                                'bingo'.tr,
                                style: TextStyle(
                                    fontFamily: "OpenSans",
                                    color: Colors.tealAccent[400],
                                    fontSize: 100,
                                    fontWeight: FontWeight.bold,
                                    fontStyle: FontStyle.italic),
                              ),
                              SizedBox(
                                height: 10,
                              ),
                              Text(
                                "you_got_match".tr,
                                style: TextStyle(
                                    fontFamily: "OpenSans",
                                    color: Colors.tealAccent[400],
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold),
                              ),
                              SizedBox(
                                height: height * 0.2,
                              ),
                              Container(
                                margin: const EdgeInsets.symmetric(
                                    horizontal: 20.0),
                                padding: const EdgeInsets.symmetric(
                                    vertical: 20, horizontal: 15),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(10.0)),
                                ),
                                child: new Row(
                                  children: <Widget>[
                                    new Flexible(
                                      child: new Container(
                                        alignment: Alignment.center,
                                        child: new TextField(
                                          controller: _textController,
                                          onChanged: (String messageText) {
                                            setState(() {});
                                          },
                                          maxLines: null,
                                          decoration:
                                              new InputDecoration.collapsed(
                                            hintText: "chat_me_up".tr,
                                          ),
                                          style: TextStyle(
                                              fontFamily: "OpenSans",
                                              fontSize: 20),
                                        ),
                                      ),
                                    ),
                                    new GestureDetector(
                                      onTap: () {
                                        if (_textController.text.length > 0) {
                                          _sendText(_textController.text.trim());
                                        }
                                      },
                                      child: Text(
                                        'send'.tr,
                                        style: TextStyle(
                                            fontFamily: "OpenSans",
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                            color:
                                                _textController.text.length > 0
                                                    ? Colors.blue
                                                    : Colors.grey),
                                      ),
                                    )
                                  ],
                                ),
                              ),
                              SizedBox(
                                height: 20,
                              ),
                              Container(
                                margin: const EdgeInsets.symmetric(
                                    horizontal: 20.0),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          _textController.text =
                                              _textController.text + '👋';
                                        });
                                      },
                                      child: Container(
                                        padding: EdgeInsets.symmetric(
                                            vertical: 5, horizontal: 15),
                                        decoration: BoxDecoration(
                                            color: Colors.transparent,
                                            borderRadius: BorderRadius.all(
                                                Radius.circular(20.0)),
                                            border: Border.all(
                                                color: Colors.white, width: 2)),
                                        child: Text(
                                          '👋',
                                          style: TextStyle(
                                              fontFamily: "OpenSans",
                                              fontSize: 22),
                                        ),
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          _textController.text =
                                              _textController.text + '😒';
                                        });
                                      },
                                      child: Container(
                                        padding: EdgeInsets.symmetric(
                                            vertical: 5, horizontal: 15),
                                        decoration: BoxDecoration(
                                            color: Colors.transparent,
                                            borderRadius: BorderRadius.all(
                                                Radius.circular(20.0)),
                                            border: Border.all(
                                                color: Colors.white, width: 2)),
                                        child: Text(
                                          '😒',
                                          style: TextStyle(
                                              fontFamily: "OpenSans",
                                              fontSize: 22),
                                        ),
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          _textController.text =
                                              _textController.text + '❤';
                                        });
                                      },
                                      child: Container(
                                        padding: EdgeInsets.symmetric(
                                            vertical: 5, horizontal: 15),
                                        decoration: BoxDecoration(
                                            color: Colors.transparent,
                                            borderRadius: BorderRadius.all(
                                                Radius.circular(20.0)),
                                            border: Border.all(
                                                color: Colors.white, width: 2)),
                                        child: Text(
                                          '❤',
                                          style: TextStyle(
                                              fontFamily: "OpenSans",
                                              fontSize: 22),
                                        ),
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          _textController.text =
                                              _textController.text + '😍';
                                        });
                                      },
                                      child: Container(
                                        padding: EdgeInsets.symmetric(
                                            vertical: 5, horizontal: 15),
                                        decoration: BoxDecoration(
                                            color: Colors.transparent,
                                            borderRadius: BorderRadius.all(
                                                Radius.circular(20.0)),
                                            border: Border.all(
                                                color: Colors.white, width: 2)),
                                        child: Text(
                                          '😍',
                                          style: TextStyle(
                                              fontFamily: "OpenSans",
                                              fontSize: 22),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            ],
                          ),
                        ],
                      )
                    ],
                  ),
                ));
          }),
    );
  }
}
