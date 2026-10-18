import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:link_up/get_controller/ChatController.dart';
import 'package:link_up/get_controller/auth_controller.dart';
import 'package:link_up/get_controller/social_controller.dart';
import 'package:link_up/helper/router/route_path.dart';
import 'package:link_up/model/user_model.dart';

class LikesMePage extends StatefulWidget {
  @override
  _LikesMePageState createState() => _LikesMePageState();
}

class _LikesMePageState extends State<LikesMePage> {
  AuthController authController = Get.find(tag: AuthController().toString());
  ChatController chatController = Get.find(tag: ChatController().toString());
  SocialController socialController = Get.find<SocialController>();

  String _flagFor(UserModel user) {
    final apiFlag = (user.countryFlag ?? '').trim();
    if (apiFlag.isNotEmpty) return apiFlag;
    return countryFlagEmoji(user.countryCode.trim());
  }

  String countryFlagEmoji(String iso2) {
    if (iso2.length != 2) return '';
    final upper = iso2.toUpperCase();
    if (!RegExp(r'^[A-Z]{2}$').hasMatch(upper)) return '';
    return upper.replaceAllMapped(
      RegExp(r'[A-Z]'),
      (m) => String.fromCharCode(m.group(0)!.codeUnitAt(0) + 127397),
    );
  }

  @override
  void initState() {
    super.initState();
    socialController.fetchLikes();
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    double height = MediaQuery.of(context).size.height;
    return WillPopScope(
      onWillPop: () async {
        Navigator.pushNamed(context, RoutePath.home_screen);
        return false;
      },
      child: Scaffold(
        body: ListView(children: [
          Stack(children: [
            Image.asset("assets/image/Group 163959 (2).png"),
            Padding(
              padding: const EdgeInsets.only(top: 30, left: 110),
              child: Text(
                "who_likes_me".tr,
                style: TextStyle(color: Colors.white, fontSize: 25),
              ),
            )
          ]),
          Obx(() {
            if (socialController.isLoadingLikes.value) {
              return Container(
                height: height * 0.5,
                alignment: Alignment.center,
                child: CircularProgressIndicator(),
              );
            }

            final users = socialController.likesList;
            if (users.isEmpty) {
              return Container(
                height: height * 0.8,
                alignment: Alignment.center,
                child: Center(
                  child: Text(
                    'there_is_no_someone'.tr,
                    style: TextStyle(fontFamily: "OpenSans", fontSize: 16),
                  ),
                ),
              );
            }

            return Container(
              width: width,
              height: height,
              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 20),
              child: GridView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: users.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 8.0,
                      mainAxisSpacing: 8.0,
                      childAspectRatio: 0.75),
                  itemBuilder: (BuildContext context, int index) {
                    final user = users[index];
                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => _LinkUpWebProfilePage(
                              user: user,
                              ui: (ctx, v) => v, // Fallback helpers if not passed properly
                              font: (ctx, v) => v,
                              icon: (ctx, v) => v,
                              countryText: user.country,
                            ),
                          ),
                        );
                      },
                      child: Container(
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.all(Radius.circular(15)),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                            image: DecorationImage(
                                image: NetworkImage(user.avatar),
                                fit: BoxFit.cover)),
                        child: Stack(
                          children: <Widget>[
                            Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.all(Radius.circular(15)),
                                gradient: LinearGradient(
                                  colors: [Colors.transparent, Colors.black87],
                                  begin: Alignment.center,
                                  end: Alignment.bottomCenter,
                                ),
                              ),
                            ),
                            Positioned(
                              top: 8,
                              right: 8,
                              child: GestureDetector(
                                onTap: () {
                                  Navigator.pushNamed(context, RoutePath.user_detail_page,
                                      arguments: {'end_user': user});
                                },
                                child: Container(
                                  width: 34,
                                  height: 34,
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.4),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.visibility_outlined,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                              ),
                            ),
                            Align(
                              alignment: Alignment.bottomLeft,
                              child: Container(
                                padding: EdgeInsets.all(10),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Text(
                                      '${user.firstName}, ${user.age ?? 25}',
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                      style: TextStyle(
                                          fontFamily: "OpenSans",
                                          color: Colors.white,
                                          fontSize: 16.0,
                                          fontWeight: FontWeight.w900),
                                    ),
                                    SizedBox(height: 2),
                                    Row(
                                      children: [
                                        Text(
                                          _flagFor(user),
                                          style: TextStyle(fontSize: 12),
                                        ),
                                        SizedBox(width: 4),
                                        Expanded(
                                          child: Text(
                                            user.country,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                                color: Colors.white70,
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            Positioned(
                                bottom: 8,
                                right: 8,
                                child: GestureDetector(
                                  onTap: () async {
                                    final success = await chatController.matchesLike(
                                        context, user.uid ?? user.laravelId?.toString() ?? '', user.avatar);
                                    if (success && mounted) {
                                      Navigator.pushNamed(
                                        context,
                                        RoutePath.matching_page,
                                        arguments: {
                                          'friendID': user.uid ?? user.laravelId?.toString() ?? '',
                                          'avatar': user.avatar,
                                        },
                                      );
                                    }
                                  },
                                  child: Container(
                                    width: 38,
                                    height: 38,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black26,
                                          blurRadius: 4,
                                          offset: Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Icon(
                                      Icons.favorite,
                                      color: Colors.pinkAccent,
                                      size: 22,
                                    ),
                                  ),
                                ))
                          ],
                        ),
                      ),
                    );
                  }),

            );
          }),
        ]),
      ),
    );
  }
}
