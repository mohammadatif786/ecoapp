import 'package:flutter/material.dart';
import 'package:link_up/theme/linkup_colors.dart';
import 'package:link_up/ui/auth/auth_page.dart';
import 'package:link_up/ui/auth/widgets/linkup_auth_widgets.dart';

class OnboardingScreenSeven extends StatefulWidget {
  @override
  State<OnboardingScreenSeven> createState() => _OnboardingScreenSevenState();
}

class _OnboardingScreenSevenState extends State<OnboardingScreenSeven> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(
                  'assets/Group 164008.png',
                  fit: BoxFit.cover,
                  width: MediaQuery.of(context).size.width,
                ),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.white.withValues(alpha: 0.15),
                        Colors.white.withValues(alpha: 0.92),
                      ],
                      stops: const [0.4, 0.75, 1.0],
                    ),
                  ),
                ),
                Positioned(
                  top: 28,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Image.asset(
                      'assets/Vector Smart Object 2.png',
                      width: 140,
                      height: 52,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 12),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: LinkUpColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const Text(
                  'LinkUp Membership',
                  style: TextStyle(
                    fontFamily: 'OpenSans',
                    color: LinkUpColors.brandBlue,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.2,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 14),
                const Text(
                  'Unlimited Calls • Unlimited Video\nUnlimited Restaurant Search • Unlimited Live\nTop Shelf Profile • Unlimited Swipes',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'OpenSans',
                    fontSize: 14,
                    height: 1.5,
                    color: LinkUpColors.textMuted,
                  ),
                ),
                const SizedBox(height: 24),
                LinkUpGradientButton(
                  label: 'Get Started',
                  onPressed: () {
                    Navigator.push(
                      context,
                      PageRouteBuilder(
                        pageBuilder: (_, __, ___) => const AuthPage(),
                        transitionsBuilder: (_, animation, __, child) {
                          return FadeTransition(opacity: animation, child: child);
                        },
                        transitionDuration: const Duration(milliseconds: 300),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
