import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:link_up/events/AllEvents.dart';
import 'package:link_up/events/CurrentLocation.dart';
import 'package:link_up/get_controller/auth_controller.dart';
import 'package:link_up/helper/router/route_path.dart';
import 'package:link_up/model/user_model.dart';
import 'package:link_up/theme/linkup_colors.dart';
import 'package:link_up/ui/Balance.dart';
import 'package:link_up/ui/contactus.dart';
import 'package:link_up/ui/help.dart';
import 'package:rate_my_app/rate_my_app.dart';
import 'package:share_plus/share_plus.dart';

import 'chat_home_page.dart';
import 'chat/chat_message_new.dart';

class DrawerScreen extends StatefulWidget {
  @override
  _DrawerScreenState createState() => _DrawerScreenState();
}

class _DrawerScreenState extends State<DrawerScreen> {
  FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  AuthController authController = Get.find(tag: AuthController().toString());

  GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: <String>[
      'email',
      'https://www.googleapis.com/auth/contacts.readonly',
    ],
  );

  Future _signOutConfirmDialog(BuildContext context) {
    return showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            backgroundColor: Colors.black,
            title: Text(
              'confirm_logout'.tr,
              style: TextStyle(color: Colors.white),
              textAlign: TextAlign.center,
            ),
            content: Container(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'are_you_sure_logout'.tr,
                    style: TextStyle(fontSize: 16, color: Colors.white),
                  ),
                  SizedBox(
                    height: 20,
                  ),
                  Container(
                    child: Row(
                      children: [
                        Container(
                          width: 100,
                          height: 40,
                          child: ElevatedButton(
                            child: Text(
                              "no".tr,
                              style:
                                  TextStyle(fontSize: 20, color: Colors.white),
                            ),
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                            style: ElevatedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(5),
                                  side: BorderSide(color: Colors.white)),
                              backgroundColor: Colors.black,
                              padding: EdgeInsets.all(8.0),
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 30,
                        ),
                        Container(
                          width: 100,
                          height: 40,
                          child: ElevatedButton(
                            child: Text(
                              "yes".tr,
                              style:
                                  TextStyle(fontSize: 20, color: Colors.white),
                            ),
                            onPressed: () {
                              WidgetsBinding.instance
                                  .addPostFrameCallback((timeStamp) {
                                authController.signOut(context);
                              });
                            },
                            style: ElevatedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(5),
                                  side: BorderSide(color: Colors.white)),
                              backgroundColor: Colors.red[900],
                              padding: EdgeInsets.all(8.0),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        });
  }

  String _displayName(UserModel user) {
    final fullName = '${user.firstName} ${user.lastName}'.trim();
    if (fullName.isNotEmpty) return fullName;

    final fromControllers =
        '${authController.firstnameController.text} ${authController.lastnameController.text}'
            .trim();
    if (fromControllers.isNotEmpty) return fromControllers;

    if (user.email.contains('@')) {
      return user.email
          .split('@')
          .first
          .replaceAll('.', ' ')
          .replaceAll('_', ' ')
          .split(' ')
          .where((part) => part.isNotEmpty)
          .map((part) =>
              '${part[0].toUpperCase()}${part.substring(1).toLowerCase()}')
          .join(' ');
    }
    return 'User';
  }

  String _linkupHandle(UserModel user) {
    final handle =
        '${user.firstName}${user.lastName}'.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
    if (handle.length >= 3) return '@$handle';
    if (user.email.contains('@')) return '@${user.email.split('@').first}';
    return '';
  }

  String _initials(UserModel user) {
    final name = _displayName(user);
    final parts = name.split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts[1][0]}'.toUpperCase();
    }
    if (parts.isNotEmpty) return parts.first[0].toUpperCase();
    return 'U';
  }

  String _popularityLabel(UserModel user) {
    if (user.isTopShelf) return 'High';
    if (user.subscription.isNotEmpty) return 'Medium';
    return 'Low';
  }

  Widget _buildProfileHeader() {
    final user = authController.user?.value;
    final isGuest = user == null || (user.uid == null && user.laravelId == null);

    if (isGuest) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(20, 60, 20, 30),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0089CD), Color(0xFF2FA4E6)],
          ),
        ),
        child: Column(
          children: [
            const Icon(Icons.account_circle, size: 80, color: Colors.white70),
            const SizedBox(height: 16),
            const Text(
              'Welcome, Guest',
              style: TextStyle(
                fontFamily: 'OpenSans',
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, RoutePath.auth_page),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF0089CD),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Sign In / Create Account'),
            ),
          ],
        ),
      );
    }

    final avatarUrl = user.avatar.trim();
    final hasAvatar = avatarUrl.isNotEmpty;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0089CD), Color(0xFF2FA4E6)],
        ),
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, RoutePath.profile_page);
            },
            child: Column(
              children: [
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: hasAvatar
                        ? Image.network(
                            avatarUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _avatarFallback(user),
                          )
                        : _avatarFallback(user),
                  ),
                ),
                const SizedBox(height: 12),
                if (_linkupHandle(user).isNotEmpty)
                  Text(
                    _linkupHandle(user),
                    style: TextStyle(
                      fontFamily: 'OpenSans',
                      color: Colors.white.withValues(alpha: 0.95),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                const SizedBox(height: 4),
                Text(
                  _displayName(user),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'OpenSans',
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Popularity: ${_popularityLabel(user)}',
                  style: TextStyle(
                    fontFamily: 'OpenSans',
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _avatarFallback(UserModel user) {
    return Container(
      color: LinkUpColors.brandBlue,
      alignment: Alignment.center,
      child: Text(
        _initials(user),
        style: const TextStyle(
          fontFamily: 'OpenSans',
          color: Colors.white,
          fontSize: 32,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
  }

  RateMyApp rateMyApp = RateMyApp(
    preferencesPrefix: 'rateMyApp_',
    minDays: 7,
    minLaunches: 10,
    remindDays: 7,
    remindLaunches: 10,
    googlePlayIdentifier: 'fr.skyost.example',
    appStoreIdentifier: '1491556149',
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromARGB(255, 245, 245, 245),
      body: GetBuilder(
          init: authController,
          builder: (_) {
            return ListView(
              padding: EdgeInsets.zero,
              children: <Widget>[
                _buildProfileHeader(),

                ListTile(
                  leading: Image.asset(
                    "assets/home.png",
                    height: 20,
                    width: 20,
                  ),
                  title: Text("home".tr),
                  onTap: () {
                    // Navigator.popAndPushNamed(context, RoutePath.home_screen);
                    Get.to(CurrentLocation());
                  },
                  // trailing: Icon(
                  //   Icons.arrow_forward,
                  //   color: Colors.black,
                  //   size: 20,
                  // ),
                ),
                ListTile(
                  leading: Image.asset(
                    "assets/booking.png",
                    height: 20,
                    width: 20,
                  ),
                  title: Text("My Bookings"),
                  onTap: () {
                    Get.to(() => const AllEvents(initialTab: 'Booking'));
                  },
                ),
                InkWell(
                  onTap: () {
                    Get.to(History());
                  },
                  child: ListTile(
                    leading: Image.asset(
                      "assets/ror.png",
                      color: Color.fromARGB(255, 56, 171, 216),
                      height: 20,
                      width: 20,
                    ),
                    title: Text("Wallets"),
                  ),
                ),
                ListTile(
                  leading: Image.asset(
                    "assets/discuss-issue.png",
                    height: 20,
                    width: 20,
                  ),
                  title: Text("Chat Now"),
                  onTap: () {
                    //
                    Get.to(ChatHomePage());
                  },
                  // trailing: Icon(
                  //                 Icons.arrow_forward,
                  //              color: Colors.black,
                  //           size: 20,
                  //      ),
                ),
                ListTile(
                  leading: Image.asset(
                    "assets/advice.png",
                    height: 20,
                    width: 20,
                  ),
                  title: Text("subscription".tr),
                  onTap: () {
                    Navigator.popAndPushNamed(
                        context, RoutePath.subscription_page_one);
                  },
                  // trailing: Icon(
                  //                 Icons.arrow_forward,
                  //              color: Colors.black,
                  //           size: 20,
                  //      ),
                ),
                ListTile(
                  leading: Image.asset(
                    "assets/promotion(1).png",
                    height: 20,
                    width: 20,
                  ),
                  title: Text("push_notification".tr),
                  onTap: () {
                    Navigator.popAndPushNamed(
                        context, RoutePath.notification_page);
                  },
                  // trailing: Icon(
                  //                 Icons.arrow_forward,
                  //              color: Colors.black,
                  //           size: 20,
                  //      ),
                ),
                ListTile(
                  leading: Image.asset(
                    "assets/paper.png",
                    height: 20,
                    width: 20,
                  ),
                  title: Text("legal_support".tr),
                  onTap: () {
                    Navigator.pushNamed(context, RoutePath.legal_and_support);
                  },
                  // trailing: Icon(
                  //                 Icons.arrow_forward,
                  //              color: Colors.black,
                  //           size: 20,
                  //      ),
                ),
                ListTile(
                  leading: Image.asset(
                    "assets/control-center.png",
                    height: 20,
                    width: 20,
                  ),
                  title: Text("settings".tr),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, RoutePath.setting_screen);
                  },
                  // trailing: Icon(
                  //                 Icons.arrow_forward,
                  //              color: Colors.black,
                  //           size: 20,
                  //      ),
                ),
                ListTile(
                  leading: Image.asset(
                    "assets/share.png",
                    height: 20,
                    width: 20,
                  ),
                  title: Text("share".tr),
                  onTap: () {
                    Share.share(
                        "https://play.google.com/store/apps/details?id=com.bluskies.linkUp");
                  },
                  // trailing: Icon(
                  //                 Icons.arrow_forward,
                  //              color: Colors.black,
                  //           size: 20,
                  //      ),
                ),
                ListTile(
                  leading: Image.asset(
                    "assets/advice.png",
                    height: 20,
                    width: 20,
                  ),
                  title: Text("rate_this_app".tr),
                  onTap: () {
                    rateMyApp.showRateDialog(
                      context,
                      title: 'rate_this_app'.tr, // The dialog title.
                      message: 'rate_app_description'.tr, // The dialog message.
                      rateButton: 'rate'.tr, // The dialog "rate" button text.
                      noButton: 'no_thanks'.tr, // The dialog "no" button text.
                      laterButton:
                          'maybe_later', // The dialog "later" button text.
                      listener: (button) {
                        // The button click listener (useful if you want to cancel the click event).
                        switch (button) {
                          case RateMyAppDialogButton.rate:
                            print('Clicked on "Rate".');
                            break;
                          case RateMyAppDialogButton.later:
                            print('Clicked on "Later".');
                            break;
                          case RateMyAppDialogButton.no:
                            print('Clicked on "No".');
                            break;
                        }

                        return true; // Return false if you want to cancel the click event.
                      },
                      ignoreNativeDialog:
                          true, // Set to false if you want to show the Apple's native app rating dialog on iOS or Google's native app rating dialog (depends on the current Platform).
                      dialogStyle: const DialogStyle(), // Custom dialog styles.
                      onDismissed: () => rateMyApp
                          .callEvent(RateMyAppEventType.laterButtonPressed),
                      // Called when the user dismissed the dialog (either by taping outside or by pressing the "back" button).
                      // contentBuilder: (context, defaultContent) => content, // This one allows you to change the default dialog content.
                      // actionsBuilder: (context) => [], // This one allows you to use your own buttons.
                    );
                  },
                  // trailing: Icon(
                  //                 Icons.arrow_forward,
                  //              color: Colors.black,
                  //           size: 20,
                  //      ),
                ),
                ListTile(
                  leading: Image.asset(
                    "assets/shop.png",
                    height: 20,
                    width: 20,
                  ),
                  title: Text("Shop"),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, RoutePath.shop_screen);
                  },
                  // trailing: Icon(
                  //                 Icons.arrow_forward,
                  //              color: Colors.black,
                  //           size: 20,
                  //      ),
                ),
                ListTile(
                  leading: Image.asset(
                    "assets/contact.png",
                    height: 20,
                    width: 20,
                  ),
                  title: Text("Contact Us"),
                  onTap: () {
                    Get.to(ContactUsScreen());
                  },
                ),
                ListTile(
                  leading: Image.asset(
                    "assets/help.png",
                    height: 20,
                    width: 20,
                  ),
                  title: Text("Help"),
                  onTap: () {
                    Get.to(HelpScreen());
                  },
                  // trailing: Icon(
                  //                 Icons.arrow_forward,
                  //              color: Colors.black,
                  //           size: 20,
                  //      ),
                ),
                ListTile(
                  leading: Image.asset(
                    "assets/log-out.png",
                    height: 20,
                    width: 20,
                  ),
                  title: Text("log_out".tr),
                  onTap: () {
                    _signOutConfirmDialog(context);
                  },
                  // trailing: Icon(
                  //                 Icons.arrow_forward,
                  //              color: Colors.black,
                  //           size: 20,
                  //      ),
                ),
              ],
            );
          }),
    );
  }
}
