import 'package:flutter/material.dart';
import 'package:link_up/ui/auth/auth_screen.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const AuthScreen(initialTab: AuthTab.signin);
  }
}
