import 'package:flutter/material.dart';
import 'package:link_up/ui/auth/auth_screen.dart';

class SignUpUsingEmail extends StatelessWidget {
  const SignUpUsingEmail({super.key});

  @override
  Widget build(BuildContext context) {
    return const AuthScreen(initialTab: AuthTab.signup);
  }
}
