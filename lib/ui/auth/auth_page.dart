import 'package:flutter/material.dart';
import 'package:link_up/helper/router/route_path.dart';
import 'package:link_up/ui/auth/auth_screen.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<double> _scale;

  static const double _designWidth = 888;
  static const double _designHeight = 1788;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 360),
    );
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _scale = Tween<double>(begin: 0.985, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _openAuth(AuthTab tab) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => AuthScreen(initialTab: tab),
        transitionsBuilder: (_, animation, __, child) => FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.025),
              end: Offset.zero,
            ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
            child: child,
          ),
        ),
        transitionDuration: const Duration(milliseconds: 240),
      ),
    );
  }

  void _enterGuest() {
    Navigator.pushNamed(
      context,
      RoutePath.home_screen,
      arguments: {'isGuest': true},
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffe9f1fb),
      body: FadeTransition(
        opacity: _fade,
        child: ScaleTransition(
          scale: _scale,
          child: SizedBox.expand(
            child: FittedBox(
              fit: BoxFit.cover,
              alignment: Alignment.center,
              child: SizedBox(
                width: _designWidth,
                height: _designHeight,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.asset(
                      'assets/auth_landing_exact.png',
                      fit: BoxFit.fill,
                      gaplessPlayback: true,
                    ),

                    // Exact web landing UI is painted from the web reference asset above.
                    // The transparent zones below keep the existing app logic intact.
                    _TapZone(
                      left: 58,
                      top: 1364,
                      width: 772,
                      height: 118,
                      semanticLabel: 'Continue with Phone',
                      onTap: () => _openAuth(AuthTab.signin),
                    ),
                    _TapZone(
                      left: 58,
                      top: 1501,
                      width: 772,
                      height: 124,
                      semanticLabel: 'Continue with Email',
                      onTap: () => _openAuth(AuthTab.signup),
                    ),
                    _TapZone(
                      left: 250,
                      top: 1640,
                      width: 170,
                      height: 82,
                      semanticLabel: 'Sign in',
                      onTap: () => _openAuth(AuthTab.signin),
                    ),
                    _TapZone(
                      left: 432,
                      top: 1640,
                      width: 260,
                      height: 82,
                      semanticLabel: 'Explore as guest',
                      onTap: _enterGuest,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TapZone extends StatelessWidget {
  final double left;
  final double top;
  final double width;
  final double height;
  final String semanticLabel;
  final VoidCallback onTap;

  const _TapZone({
    required this.left,
    required this.top,
    required this.width,
    required this.height,
    required this.semanticLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: left,
      top: top,
      width: width,
      height: height,
      child: Semantics(
        label: semanticLabel,
        button: true,
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: onTap,
          child: const SizedBox.expand(),
        ),
      ),
    );
  }
}
