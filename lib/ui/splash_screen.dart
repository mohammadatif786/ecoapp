import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:link_up/get_controller/auth_controller.dart';
import 'package:link_up/helper/router/route_path.dart';
import 'package:link_up/introscreens/welcome.dart';
import 'package:link_up/services/linkup_api_service.dart';

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  AuthController authController = Get.find(tag: AuthController().toString());

  Future<void> checkAuth(BuildContext context) async {
    final apiToken = await LinkupApiService.getToken();
    if (apiToken != null && apiToken.isNotEmpty) {
      try {
        await authController.getUserFromApi(context);
      } catch (e) {
        debugPrint('Splash profile load failed: $e');
        await authController.restoreUserFromStoredSession();
      }
      if (!context.mounted) return;
      if (authController.hasValidApiUser()) {
        Navigator.of(context).pushNamedAndRemoveUntil(
          RoutePath.home_screen,
          (route) => false,
        );
        return;
      }
      await LinkupApiService.clearToken();
    }

    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (builder) => Welcome()),
      (route) => false,
    );
  }

  @override
  void initState() {
    super.initState();
    print("📲 SplashScreen initState called.");
    WidgetsBinding.instance.addPostFrameCallback((_) {
      checkAuth(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
