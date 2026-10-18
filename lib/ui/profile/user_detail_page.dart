import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:link_up/get_controller/auth_controller.dart';
import 'package:link_up/model/regular_user_detail_result.dart';
import 'package:link_up/services/linkup_api_service.dart';
import 'package:link_up/ui/home_page.dart';
import 'package:link_up/helper/router/route_path.dart';

import '../../get_controller/ChatController.dart';
import '../../model/user_model.dart';

class UserDetailPage extends StatefulWidget {
  final UserModel endUser;
  UserDetailPage({required this.endUser});

  @override
  State<UserDetailPage> createState() => _UserDetailPageState();
}

class _UserDetailPageState extends State<UserDetailPage> {
  UserModel? _loadedUser;
  RegularUserDetailResult? _detail;
  bool _loading = true;
  bool _actionBusy = false;

  @override
  void initState() {
    super.initState();
    _loadProfileFromApi();
  }

  UserModel get endUser => _loadedUser ?? widget.endUser;

  int? get _targetUserId =>
      endUser.laravelId ?? int.tryParse(endUser.uid ?? '');

  String _resolveDisplayName(UserModel user) =>
      '${user.firstName} ${user.lastName}'.trim();

  String get _displayName => _resolveDisplayName(endUser);

  String _formatDistance(int? meters) {
    if (meters == null || meters <= 0) return '';
    final miles = (meters / 1609.34).round();
    if (miles <= 0) return 'Nearby';
    return '$miles Miles away';
  }

  String get _genderLabel {
    final orientation = endUser.linkMeWith.trim();
    final gender = endUser.gender.trim();
    if (orientation.isEmpty) return gender;
    if (gender.isEmpty) return orientation;
    return '$orientation $gender';
  }

  Future<void> _loadProfileFromApi() async {
    final token = await LinkupApiService.getToken();
    if (token == null || token.isEmpty) {
      if (mounted) setState(() => _loading = false);
      return;
    }

    final laravelId =
        widget.endUser.laravelId ?? int.tryParse(widget.endUser.uid ?? '');
    final name = _resolveDisplayName(widget.endUser);
    final uid = widget.endUser.uid ?? '';

    try {
      late RegularUserDetailResult detail;
      if (LinkupApiService.isFirebaseUid(uid) && name.isNotEmpty) {
        detail = await LinkupApiService.fetchRegularUserProfileDetail(
          name: name,
          uid: uid,
        );
      } else if (laravelId != null) {
        detail = await LinkupApiService.fetchUserProfileByLaravelId(laravelId);
        final firebaseUid = detail.user.uid ?? '';
        final loadedName = _resolveDisplayName(detail.user);
        if (LinkupApiService.isFirebaseUid(firebaseUid) &&
            loadedName.isNotEmpty) {
          try {
            detail = await LinkupApiService.fetchRegularUserProfileDetail(
              name: loadedName,
              uid: firebaseUid,
            );
          } catch (e) {
            debugPrint('regular-user detail enrich failed: $e');
          }
        }
      } else {
        if (mounted) setState(() => _loading = false);
        return;
      }

      if (!mounted) return;
      setState(() {
        _loadedUser = detail.user;
        _detail = detail;
        _loading = false;
      });
    } catch (e) {
      debugPrint('profile detail load failed: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _sendFriendRequest() async {
    final uid = endUser.uid ?? '';
    if (_displayName.isEmpty || uid.isEmpty || _actionBusy) return;
    setState(() => _actionBusy = true);
    try {
      await LinkupApiService.sendFriendRequest(name: _displayName, uid: uid);
      if (!mounted) return;
      setState(() {
        _detail = RegularUserDetailResult(
          user: endUser,
          isFriends: _detail?.isFriends ?? false,
          isFriendRequestSent: true,
          isHiddenByProfileOwner: _detail?.isHiddenByProfileOwner ?? false,
        );
      });
      Get.find<AuthController>(tag: AuthController().toString())
          .alert1('Friend request sent.');
    } catch (e) {
      Get.find<AuthController>(tag: AuthController().toString())
          .alert1(e.toString());
    } finally {
      if (mounted) setState(() => _actionBusy = false);
    }
  }

  Future<void> _profileLike() async {
    final id = _targetUserId;
    if (id == null || _actionBusy) return;
    setState(() => _actionBusy = true);
    try {
      await LinkupApiService.profileLike(id);

      // If we got here, check if it's a mutual match to show Bingo
      // We can check if the user is in the 'Likes Me' list if we have access to it,
      // or just show Bingo if we assume 'profileLike' on someone who liked us is a match.

      if (mounted) {
         Navigator.pushReplacementNamed(
          context,
          RoutePath.matching_page,
          arguments: {
            'friendID': endUser.uid ?? endUser.laravelId?.toString() ?? '',
            'avatar': endUser.avatar,
          },
        );
      }
    } catch (e) {
      Get.find<AuthController>(tag: AuthController().toString())
          .alert1(e.toString());
    } finally {
      if (mounted) setState(() => _actionBusy = false);
    }
  }

  Future<void> _profileDislike() async {
    final id = _targetUserId;
    if (id == null || _actionBusy) return;
    setState(() => _actionBusy = true);
    try {
      await LinkupApiService.profileDislike(id);
      Get.find<AuthController>(tag: AuthController().toString())
          .alert1('Passed.');
    } catch (e) {
      Get.find<AuthController>(tag: AuthController().toString())
          .alert1(e.toString());
    } finally {
      if (mounted) setState(() => _actionBusy = false);
    }
  }

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
  Widget build(BuildContext context) {
    AuthController authController = Get.find(tag: AuthController().toString());

    ChatController chatController = Get.find(tag: ChatController().toString());
    double height = MediaQuery.of(context).size.height;
    double width = MediaQuery.of(context).size.width;
    imagePickerDialog(BuildContext context) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return Dialog(
            // shape:
            //     RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            // insetPadding: EdgeInsets.all(19),
            child: Container(
              width: 190,
              height: 250,

              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10), color: Colors.white
                  //
                  ),
              child: Stack(children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 148),
                  child: Image.asset(
                    "assets/image/popup.jpg",
                    width: 320,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 20, left: 58),
                  child: Text(
                    "Upload Photos from",
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 19,
                        fontWeight: FontWeight.bold),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 140),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Column(
                        children: [
                          GestureDetector(
                            child: Icon(
                              Icons.folder,
                              size: 50,
                            ),
                            onTap: () {
                              Navigator.pop(context);
                              authController.getImage('gallery');
                            },
                          ),
                          Text(
                            // 'browse_image'.tr,
                            'Your Photos',
                            style: TextStyle(color: Colors.black),
                          )
                        ],
                      ),
                      SizedBox(
                        width: 50,
                      ),
                      Column(
                        children: [
                          GestureDetector(
                            child: Icon(
                              Icons.camera_alt,
                              size: 50,
                            ),
                            onTap: () {
                              Navigator.pop(context);
                              authController.getImage('camera');
                            },
                          ),
                          Text(
                            // 'take_photo'.tr,
                            'Camera',
                            style: TextStyle(color: Colors.black),
                          )
                        ],
                      ),
                    ],
                  ),
                ),
              ]),
              // child: Column(
              //   mainAxisAlignment: MainAxisAlignment.start,
              //   children: [
              //     Container(
              //       height: 100,
              //       width: double.infinity,
              //       decoration: BoxDecoration(
              //         shape: BoxShape.rectangle,
              //         borderRadius: BorderRadius.circular(10),
              //         color: Colors.blue,
              //         image: DecorationImage(
              //             image: AssetImage("assets/image/hjhhjhj.png"),
              //             fit: BoxFit.cover),
              //       ),
              //       child: Padding(
              //         padding: const EdgeInsets.only(top: 10, left: 35),
              //         child: Text(
              //           "Upload Photos from",
              //          style: TextStyle(color: Colors.white, fontSize: 16),
              //         ),
              //       ),
              //     ),
              //     SizedBox(
              //       height: 20,
              //     ),
              //     Row(
              //       crossAxisAlignment: CrossAxisAlignment.center,
              //       mainAxisAlignment: MainAxisAlignment.center,
              //       children: [
              //         Column(
              //           children: [
              //             GestureDetector(
              //               child: Icon(
              //                 Icons.folder,
              //                 size: 50,
              //               ),
              //               onTap: () {
              //                 Navigator.pop(context);
              //                 authController.getImage('gallery');
              //               },
              //             ),
              //             Text(
              //               // 'browse_image'.tr,
              //               'Your Photos',
              //              style: TextStyle(color: Colors.black),
              //             )
              //           ],
              //         ),
              //         SizedBox(
              //           width: 50,
              //         ),
              //         Column(
              //           children: [
              //             GestureDetector(
              //               child: Icon(
              //                 Icons.camera_alt,
              //                 size: 50,
              //               ),
              //               onTap: () {
              //                 Navigator.pop(context);
              //                 authController.getImage('camera');
              //               },
              //             ),
              //             Text(
              //               // 'take_photo'.tr,
              //               'Camera',
              //              style: TextStyle(color: Colors.black),
              //             )
              //           ],
              //         ),
              //       ],
              //     )
              //   ],
              // ),
            ),
          );
        },
      );
    }

    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      body: Stack(
        children: [
          ClipPath(
            clipper: MyClipper(),
            child: Container(
              height: 218,
              width: double.infinity,
              color: Color.fromARGB(255, 56, 171, 216),
              child: Container(
                height: 200,
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: NetworkImage(endUser.cardImageUrl.isNotEmpty
                        ? endUser.cardImageUrl
                        : endUser.avatar),
                    fit: BoxFit.cover,
                    colorFilter: ColorFilter.mode(
                        Color.fromARGB(255, 56, 171, 216), BlendMode.color),
                    opacity: 150,
                  ),
                ),
              ),
            ),
          ),

          // Column(
          //   children: [
          // Container(
          //   height: 218,
          //   decoration: BoxDecoration(
          //     image: DecorationImage(
          //       image: AssetImage(
          //         "assets/Group 163959 (2).png",
          //       ),
          //       fit: BoxFit.fill,
          //     ),
          //   ),
          //   child: Container(
          //     height: 200,
          //     decoration: BoxDecoration(
          //       image: DecorationImage(
          //         image: NetworkImage("${widget.endUser.avatar}"),
          //         fit: BoxFit.fill,
          //         colorFilter: ColorFilter.mode(
          //             Color.fromARGB(255, 56, 171, 216), BlendMode.color),
          //         opacity: 150,
          //       ),
          //     ),
          //   ),
          // ),
          //   ],
          // ),
          ListView(
            children: [
              Column(
                children: [
                  // Image.asset("assets/image/Vector Smart Object 2 (1).png"),
                ],
              ),
              SizedBox(
                height: 100,
              ),
              // ClipRRect(
              //   borderRadius: BorderRadius.circular(20),
              //   child: Image.network(
              //     "${widget.endUser.avatar}",
              //     height: 150,
              //     width: 150,
              //   ),
              // ),
              CircleAvatar(
                radius: 70,
                child: Container(
                  height: 200,
                  width: 140,
                  decoration: BoxDecoration(
                    border: Border.all(
                      width: 3,
                      color: Color.fromARGB(255, 56, 171, 216),
                    ),
                    color: Colors.amber,
                    borderRadius: BorderRadius.circular(100),
                    image: DecorationImage(
                      image: NetworkImage(endUser.cardImageUrl.isNotEmpty
                          ? endUser.cardImageUrl
                          : endUser.avatar),
                      fit: BoxFit.fill,
                    ),
                  ),
                ),
              ),

              // Container(
              //   height: 100,
              //   width: 50,
              //   decoration: BoxDecoration(
              //     color: Colors.amber,
              //     borderRadius: BorderRadius.circular(50),
              //     image: DecorationImage(
              //       image: NetworkImage(widget.endUser.avatar.toString()),
              //     ),
              //   ),
              // ),
              SizedBox(
                height: 10,
              ),
              Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _flagFor(endUser),
                        style: TextStyle(fontSize: 22),
                      ),
                      SizedBox(width: 8),
                      Text(
                        _displayName,
                        style: TextStyle(
                          color: Color.fromARGB(255, 56, 171, 216),
                          fontSize: 25,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(
                        width: 10,
                      ),
                      Text(
                        "${endUser.age}",
                        style: TextStyle(fontSize: 20),
                      ),
                    ],
                  ),
                  SizedBox(
                    height: 10,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        height: 26,
                        width: 120,
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(9),
                          border: Border.all(
                              width: 1.5,
                              color: Color.fromARGB(255, 56, 171, 216)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Image.asset("assets/image/male-gender (1).png"),
                            Flexible(
                              child: Text(
                                _genderLabel,
                                style: const TextStyle(fontSize: 12),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(
                        width: 10,
                      ),
                      Container(
                        height: 26,
                        width: 157,
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(9),
                          border: Border.all(
                              width: 1.5,
                              color: Color.fromARGB(255, 56, 171, 216)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Image.asset("assets/image/distance (1).png"),
                            Flexible(
                              child: Text(
                                endUser.country,
                                style: const TextStyle(fontSize: 12),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (_formatDistance(_detail?.distance).isNotEmpty) ...[
                    const SizedBox(height: 5),
                    Container(
                      height: 26,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(9),
                        border: Border.all(
                          width: 1.5,
                          color: const Color.fromARGB(255, 56, 171, 216),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset("assets/image/location(4) (3).png"),
                          const SizedBox(width: 6),
                          Text(
                            _formatDistance(_detail?.distance),
                            style: const TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                  SizedBox(
                    height: 10,
                  ),
                  Divider(
                    color: Color.fromARGB(255, 219, 239, 246),
                    indent: 10,
                    endIndent: 10,
                  ),
                  Text(
                    "Photos",
                    style: TextStyle(
                      fontSize: 20,
                      color: Color.fromARGB(255, 56, 171, 216),
                    ),
                  ),
                  SizedBox(
                    height: 5,
                  ),
                  // Image.asset("assets/image/Group 163989 (3).png"),
                  Container(
                    height: 100,
                    width: 100,
                    decoration: BoxDecoration(
                      color: Color.fromARGB(255, 56, 171, 216),
                      borderRadius: BorderRadius.circular(150),
                      image: DecorationImage(
                        image:
                            NetworkImage(
                              endUser.morePhotos.isNotEmpty
                                  ? endUser.morePhotos.first
                                  : endUser.cardImageUrl,
                            ),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  Divider(
                    color: Color.fromARGB(255, 219, 239, 246),
                    indent: 10,
                    endIndent: 10,
                  ),
                  SizedBox(
                    height: 10,
                  ),
                  Text(
                    "Why I am here",
                    style: TextStyle(
                      fontSize: 20,
                      color: Color.fromARGB(255, 56, 171, 216),
                    ),
                  ),
                  SizedBox(
                    height: 10,
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      endUser.whyarewehere,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                  SizedBox(
                    height: 10,
                  ),
                  Divider(
                    color: Color.fromARGB(255, 219, 239, 246),
                    indent: 10,
                    endIndent: 10,
                  ),
                  SizedBox(
                    height: 10,
                  ),
                  Text(
                    "About Me",
                    style: TextStyle(
                      fontSize: 20,
                      color: Color.fromARGB(255, 56, 171, 216),
                    ),
                  ),
                  SizedBox(
                    height: 10,
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      endUser.aboutMe,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                  SizedBox(
                    height: 10,
                  ),
                  Divider(
                    color: Color.fromARGB(255, 219, 239, 246),
                    indent: 10,
                    endIndent: 10,
                  ),

                  Text(
                    "What City Do You Live in",
                    style: TextStyle(
                      fontSize: 20,
                      color: Color.fromARGB(255, 56, 171, 216),
                    ),
                  ),
                  SizedBox(
                    height: 10,
                  ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        endUser.newCity1.isNotEmpty
                            ? endUser.newCity1
                            : endUser.newState1,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                  ),
                  Divider(
                    color: Color.fromARGB(255, 219, 239, 246),
                    indent: 10,
                    endIndent: 10,
                  ),
                  Text(
                    "Interests",
                    style: TextStyle(
                      fontSize: 20,
                      color: Color.fromARGB(255, 56, 171, 216),
                    ),
                  ),
                  SizedBox(
                    height: 10,
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: endUser.interests.isEmpty
                        ? const SizedBox.shrink()
                        : Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: endUser.interests
                                .map(
                                  (interest) => Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(9),
                                      border: Border.all(
                                        width: 1.5,
                                        color: const Color.fromARGB(
                                          255,
                                          56,
                                          171,
                                          216,
                                        ),
                                      ),
                                    ),
                                    child: Text(
                                      interest,
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                  ),
                  SizedBox(
                    height: 5,
                  ),
                  Divider(
                    color: Color.fromARGB(255, 219, 239, 246),
                    indent: 10,
                    endIndent: 10,
                  ),

                  Text(
                    "Job Title",
                    style: TextStyle(
                      fontSize: 20,
                      color: Color.fromARGB(255, 56, 171, 216),
                    ),
                  ),
                  SizedBox(
                    height: 10,
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      endUser.job,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                  Divider(
                    color: Color.fromARGB(255, 219, 239, 246),
                    indent: 10,
                    endIndent: 10,
                  ),
                  Text(
                    "University",
                    style: TextStyle(
                      fontSize: 20,
                      color: Color.fromARGB(255, 56, 171, 216),
                    ),
                  ),
                  SizedBox(
                    height: 10,
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      endUser.university,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                  SizedBox(
                    height: 5,
                  ),

                  SizedBox(
                    height: 10,
                  ),
                  if (_detail != null &&
                      !_detail!.isFriends &&
                      !_detail!.isFriendRequestSent)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: ElevatedButton.icon(
                        onPressed: _actionBusy ? null : _sendFriendRequest,
                        icon: const Icon(Icons.person_add),
                        label: const Text('Send friend request'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              const Color.fromARGB(255, 56, 171, 216),
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  if (_detail?.isFriendRequestSent == true)
                    const Padding(
                      padding: EdgeInsets.only(bottom: 12),
                      child: Text(
                        'Friend request sent',
                        style: TextStyle(
                          color: Color.fromARGB(255, 56, 171, 216),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      InkWell(
                        onTap: _actionBusy ? null : _profileDislike,
                        child: Image.asset("assets/image/Group 5 (1).png"),
                      ),
                      const SizedBox(width: 15),
                      InkWell(
                        onTap: _actionBusy ? null : _profileLike,
                        child: Image.asset("assets/image/Group 164006 (1).png"),
                      ),
                      const SizedBox(width: 15),
                      InkWell(
                        onTap: () => Get.to(HomePage()),
                        child: Image.asset("assets/image/Group 4 (1).png"),
                      ),
                    ],
                  ),
                  SizedBox(
                    height: 20,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class MyClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    return Path()
      ..lineTo(0, size.height)
      ..quadraticBezierTo(
          size.width / 4, size.height - 40, size.width / 2, size.height - 20)
      ..quadraticBezierTo(
          3 / 4 * size.width, size.height, size.width, size.height - 30)
      ..lineTo(size.width, 0);
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) {
    return false;
  }
}
