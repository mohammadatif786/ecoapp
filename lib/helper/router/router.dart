import 'package:flutter/material.dart';
import 'package:link_up/element/full_screen_image.dart';
import 'package:link_up/helper/router/route_path.dart';
import 'package:link_up/ui/auth/auth_page.dart';
import 'package:link_up/ui/auth/forgot_password_page.dart';
import 'package:link_up/ui/auth/login_page.dart';
import 'package:link_up/ui/auth/phone_verification_page.dart';
import 'package:link_up/ui/auth/sign_up_email.dart';
import 'package:link_up/ui/auth/signup_second_page.dart';
import 'package:link_up/ui/auth/signup_third_page.dart';
import 'package:link_up/ui/auth/signup_wizard/signup_wizard_screen.dart';
import 'package:link_up/ui/home_page.dart';
import 'package:link_up/ui/legal_support.dart';
import 'package:link_up/ui/map/place_list_page.dart';
import 'package:link_up/ui/matching_page.dart';
import 'package:link_up/ui/notification_page.dart';
import 'package:link_up/ui/chat/chat_message_page.dart';
import 'package:link_up/ui/profile/user_detail_page.dart';
import 'package:link_up/ui/profile/profile_page.dart';
import 'package:link_up/ui/splash_screen.dart';
import 'package:link_up/ui/setting/setting_page.dart';
import 'package:link_up/ui/shop/shop_page.dart';
import 'package:link_up/ui/subscription/subscription_page.dart';
import 'package:link_up/widgets/pdf_screen.dart';

Route<dynamic> generateRoutes(RouteSettings settings) {
  switch (settings.name) {
    case RoutePath.splash_screen:
      return MaterialPageRoute(
        builder: (context) => SplashScreen(),
      );
    case RoutePath.home_screen:
      final args = settings.arguments as Map<String, dynamic>?;
      return MaterialPageRoute(
        builder: (context) => HomePage(
          isGuest: args?['isGuest'] ?? false,
        ),
      );
    case RoutePath.login_screen:
      return MaterialPageRoute(
        builder: (context) => LoginPage(),
      );
    case RoutePath.auth_page:
      return MaterialPageRoute(
        builder: (context) => const AuthPage(),
      );
    case RoutePath.sign_up_second:
      return MaterialPageRoute(
        builder: (context) => SignUpSecondPage(),
      );
    case RoutePath.profile_page:
      return MaterialPageRoute(
        builder: (context) => ProfilePage(),
      );
    case RoutePath.subscription_page_one:
      return MaterialPageRoute(
        builder: (context) => SubscriptionPage1(),
      );
    case RoutePath.notification_page:
      return MaterialPageRoute(
        builder: (context) => NotificationPage(),
      );
    case RoutePath.setting_screen:
      return MaterialPageRoute(
        builder: (context) => const SettingPage(),
      );
    case RoutePath.shop_screen:
      return MaterialPageRoute(
        builder: (context) => const ShopPage(),
      );
    case RoutePath.phone_verification_page:
      return MaterialPageRoute(
        builder: (context) => PhoneVerificationPage(),
      );
    case RoutePath.forget_password:
      return MaterialPageRoute(
        builder: (context) => ForgotPasswordPage(),
      );
    case RoutePath.sign_up_third:
      return MaterialPageRoute(
        builder: (context) => SignUpThirdPage(),
      );
    case RoutePath.signup_wizard:
      return MaterialPageRoute(
        builder: (context) => const SignupWizardScreen(),
      );
    case RoutePath.sign_up_email:
      return MaterialPageRoute(
        builder: (context) => SignUpUsingEmail(),
      );
    case RoutePath.user_detail_page:
      var arg = settings.arguments as Map<String, dynamic>;
      return MaterialPageRoute(
        builder: (context) => UserDetailPage(endUser: arg['end_user']),
      );
    case RoutePath.chat_message_page:
      var arg = settings.arguments as Map<String, dynamic>;
      return MaterialPageRoute(
        builder: (context) => ChatMessagePage(
          endUserID: arg['end_user_id'],
          endUserName: arg['end_user_name'],
          chatID: arg['chat_id'],
        ),
      );
    case RoutePath.full_screen_image:
      var arg = settings.arguments as Map<String, dynamic>;
      return MaterialPageRoute(
        builder: (context) => FullScreenImage(
          imageURL: arg['image_url'],
          tag: arg['tag'],
        ),
      );
    case RoutePath.legal_and_support:
      return MaterialPageRoute(
        builder: (context) => LegalAndSupport(),
      );
    case RoutePath.pdf_view:
      var arg = settings.arguments as Map<String, dynamic>;
      return MaterialPageRoute(
        builder: (context) => PDFScreen(arg: arg),
      );
    case RoutePath.place_list_screen:
      var arg = settings.arguments as Map<String, dynamic>;
      return MaterialPageRoute(
        builder: (context) => PlaceListPage(
          placeTitle: arg['title'],
        ),
      );
    case RoutePath.matching_page:
      var arg = settings.arguments as Map<String, dynamic>;
      return MaterialPageRoute(
        builder: (context) => MatchingPage(
          friendID: arg['friend_id'],
          avatar: arg['avatar'],
        ),
      );
    default:
      return MaterialPageRoute(
        builder: (context) => LoadingScreen(),
      );
  }
}

class LoadingScreen extends StatelessWidget {
  const LoadingScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
