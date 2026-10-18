import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:link_up/get_controller/auth_controller.dart';
import 'package:link_up/ui/home_page.dart';

class WhyAre extends StatefulWidget {
  const WhyAre({Key? key}) : super(key: key);

  @override
  State<WhyAre> createState() => _WhyAreState();
}

class _WhyAreState extends State<WhyAre> {
  final AuthController authController = Get.find(tag: AuthController().toString());
  Location location = Location.livingRoom;

  final List<_IntentChoice> _choices = const [
    _IntentChoice(
      value: Location.livingRoom,
      title: 'Here to Party',
      subtitle: 'Find fêtes, clubs, festivals and nightlife around you.',
      image: 'assets/Tell People.png',
      icon: Icons.celebration_rounded,
      colors: [Color(0xFFFF8A00), Color(0xFFFF3D77)],
    ),
    _IntentChoice(
      value: Location.bedroom,
      title: 'Here to Link Up',
      subtitle: 'Meet someone nice, vibe first and see where it goes.',
      image: 'assets/Tell People (1).png',
      icon: Icons.favorite_rounded,
      colors: [Color(0xFFEC4899), Color(0xFF8B5CF6)],
    ),
    _IntentChoice(
      value: Location.kitchen,
      title: 'Here for Casual Chat',
      subtitle: 'Talk, send Vibes, comment and keep it simple.',
      image: 'assets/Tell People (2).png',
      icon: Icons.chat_bubble_rounded,
      colors: [Color(0xFF2FA4E6), Color(0xFF06B6D4)],
    ),
    _IntentChoice(
      value: Location.others,
      title: 'Here to make friends',
      subtitle: 'Connect with people from across the region.',
      image: 'assets/Tell People (3).png',
      icon: Icons.group_rounded,
      colors: [Color(0xFF22C55E), Color(0xFF14B8A6)],
    ),
    _IntentChoice(
      value: Location.mohsin,
      title: 'Looking for something serious',
      subtitle: 'Tell people you are open to a real relationship.',
      image: 'assets/Tell People (4).png',
      icon: Icons.verified_rounded,
      colors: [Color(0xFF2563EB), Color(0xFF7C3AED)],
    ),
  ];

  void _select(_IntentChoice choice) {
    setState(() => location = choice.value);
    authController.actLocation.value = choice.title;
  }

  void _continue() {
    final selected = _choices.firstWhere((choice) => choice.value == location);
    authController.actLocation.value = selected.title;
    authController.updateProfile(context: context);
    Timer(const Duration(milliseconds: 650), () {
      if (!mounted) return;
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => HomePage()));
    });
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).padding.bottom;
    return Scaffold(
      backgroundColor: const Color(0xFFEAF6FF),
      body: SafeArea(
        child: Column(
          children: [
            const _GuidanceHeader(),
            Expanded(
              child: ListView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
                children: [
                  const Text(
                    'Tell people why you are here',
                    style: TextStyle(
                      fontFamily: 'OpenSans',
                      color: Color(0xFF0F172A),
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -.4,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'This appears on your profile and helps LinkUp suggest better people, events and moments. You can change it later.',
                    style: TextStyle(
                      fontFamily: 'OpenSans',
                      color: Color(0xFF64748B),
                      fontSize: 14,
                      height: 1.42,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 18),
                  ..._choices.map((choice) {
                    final selected = choice.value == location;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _IntentCard(
                        choice: choice,
                        selected: selected,
                        onTap: () => _select(choice),
                      ),
                    );
                  }),
                ],
              ),
            ),
            Container(
              padding: EdgeInsets.fromLTRB(18, 12, 18, 14 + bottom * .35),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: const Color(0xFFE1EAF5)),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: .08), blurRadius: 26, offset: const Offset(0, -8)),
                ],
              ),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF7C3AED), Color(0xFF2FA4E6), Color(0xFFEC4899)]),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(color: const Color(0xFF2FA4E6).withValues(alpha: .25), blurRadius: 20, offset: const Offset(0, 10))],
                ),
                child: ElevatedButton(
                  onPressed: _continue,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 17),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                  child: const Text('Add to Profile ›', style: TextStyle(fontFamily: 'OpenSans', fontSize: 16, fontWeight: FontWeight.w900)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GuidanceHeader extends StatelessWidget {
  const _GuidanceHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(18, 8, 18, 0),
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0EA5E9), Color(0xFF1985FF), Color(0xFF7C3AED)],
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [BoxShadow(color: const Color(0xFF1985FF).withValues(alpha: .25), blurRadius: 26, offset: const Offset(0, 12))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: .18), borderRadius: BorderRadius.circular(11)),
                alignment: Alignment.center,
                child: const Text('ü', style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFFD5DE23), fontSize: 24)),
              ),
              const SizedBox(width: 8),
              RichText(
                text: const TextSpan(
                  style: TextStyle(fontFamily: 'OpenSans', fontSize: 26, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic),
                  children: [
                    TextSpan(text: 'Link', style: TextStyle(color: Colors.white)),
                    TextSpan(text: 'up', style: TextStyle(color: Color(0xFFFFDE31))),
                  ],
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: .16), borderRadius: BorderRadius.circular(18)),
                child: const Text('Profile guidance', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 11)),
              ),
            ],
          ),
          const SizedBox(height: 18),
          const Text(
            'Why are you here?',
            style: TextStyle(
              fontFamily: 'OpenSans',
              color: Colors.white,
              fontSize: 30,
              fontWeight: FontWeight.w900,
              letterSpacing: -.4,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Choose one intent so LinkUp can personalize your feed, matches and recommendations.',
            style: TextStyle(
              fontFamily: 'OpenSans',
              color: Colors.white70,
              fontSize: 13,
              height: 1.35,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _IntentCard extends StatelessWidget {
  const _IntentCard({required this.choice, required this.selected, required this.onTap});

  final _IntentChoice choice;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: selected ? const Color(0xFF2FA4E6) : const Color(0xFFE1EAF5), width: selected ? 2 : 1),
          boxShadow: [
            BoxShadow(
              color: (selected ? const Color(0xFF2FA4E6) : Colors.black).withValues(alpha: selected ? .16 : .04),
              blurRadius: selected ? 22 : 14,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: choice.colors),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Image.asset(
                    choice.image,
                    width: 52,
                    height: 52,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => Icon(choice.icon, color: Colors.white, size: 30),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(choice.title, style: const TextStyle(fontFamily: 'OpenSans', color: Color(0xFF0F172A), fontSize: 16, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 4),
                  Text(choice.subtitle, style: const TextStyle(fontFamily: 'OpenSans', color: Color(0xFF64748B), fontSize: 12, height: 1.35, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
            const SizedBox(width: 10),
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: selected ? const Color(0xFF2FA4E6) : const Color(0xFFF1F5F9),
                shape: BoxShape.circle,
                border: Border.all(color: selected ? const Color(0xFF2FA4E6) : const Color(0xFFD8E3F0)),
              ),
              child: selected ? const Icon(Icons.check_rounded, color: Colors.white, size: 18) : null,
            ),
          ],
        ),
      ),
    );
  }
}

class _IntentChoice {
  const _IntentChoice({
    required this.value,
    required this.title,
    required this.subtitle,
    required this.image,
    required this.icon,
    required this.colors,
  });

  final Location value;
  final String title;
  final String subtitle;
  final String image;
  final IconData icon;
  final List<Color> colors;
}

enum Location { livingRoom, bedroom, kitchen, others, mohsin }
