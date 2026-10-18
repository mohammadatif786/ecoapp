import 'package:dots_indicator/dots_indicator.dart';
import 'package:flutter/material.dart';
import 'package:link_up/theme/linkup_colors.dart';
import 'package:link_up/ui/auth/auth_page.dart';

class OnBoardingScreens extends StatefulWidget {
  const OnBoardingScreens({super.key});

  @override
  State<OnBoardingScreens> createState() => _OnBoardingScreensState();
}

class _OnboardingSlide {
  final String image;
  final String flag;
  final String title;
  final String body;
  final bool membership;

  const _OnboardingSlide({
    required this.image,
    required this.flag,
    required this.title,
    required this.body,
    this.membership = false,
  });
}

class _OnBoardingScreensState extends State<OnBoardingScreens> {
  final PageController _controller = PageController();
  int _page = 0;

  static const List<_OnboardingSlide> _slides = [
    _OnboardingSlide(
      image: 'https://images.unsplash.com/photo-1531123897727-8f129e1688ce?w=800&q=70',
      flag: 'assets/br.png',
      title: 'Linkup Vibes!',
      body:
          'The only App that brings Caribbean & Latin Americans together from all over the World.',
    ),
    _OnboardingSlide(
      image: 'https://images.unsplash.com/photo-1488426862026-3ee34a7d66df?w=800&q=70',
      flag: 'assets/bs.png',
      title: 'Linkup Vibes',
      body:
          'With Linkup Vibes, you can select which Caribbean or Latin American country you want to see people from.',
    ),
    _OnboardingSlide(
      image: 'https://images.unsplash.com/photo-1514525253161-7a46d19cd819?w=800&q=70',
      flag: 'assets/jm.png',
      title: 'Linkup Vibes Live',
      body:
          'Share your partying experience with the world by live streaming on Linkup from your favorite fete, party, club, or festival.',
    ),
    _OnboardingSlide(
      image: 'https://images.unsplash.com/photo-1517841905240-472988babdf9?w=800&q=70',
      flag: 'assets/cu.png',
      title: 'Linkup Vibes Restaurant',
      body:
          'Want to take your new date to a nice restaurant? Select the food section on the app and all the restaurants in your area will be visible.',
    ),
    _OnboardingSlide(
      image: 'https://images.unsplash.com/photo-1492447166138-50c3889fccb1?w=800&q=70',
      flag: 'assets/mx.png',
      title: 'Linkup Events',
      body:
          'LinkUp Events provides information on events and activities across the Caribbean and Latin America — live music, festivals, cultural events, sports games and more. Discover what\'s happening in your area.',
    ),
    _OnboardingSlide(
      image: 'https://images.unsplash.com/photo-1509631179647-0177331693ae?w=800&q=70',
      flag: 'assets/mx.png',
      title: 'Linkup Digital Wallet',
      body:
          'With Linkup, you can conveniently use your digital wallet to purchase tickets for both local and international events. By loading funds into your wallet, you\'ll always be prepared to pay for your desired events.',
    ),
    _OnboardingSlide(
      image: 'https://images.unsplash.com/photo-1502823403499-6ccfcf4fb453?w=800&q=70',
      flag: '',
      title: 'LinkUp VIP',
      body:
          'By subscribing to our unique membership club, you become part of our community and enjoy exclusive access to the following benefits.',
      membership: true,
    ),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _finish() {
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const AuthPage(),
        transitionsBuilder: (_, animation, __, child) => FadeTransition(
          opacity: animation,
          child: child,
        ),
        transitionDuration: const Duration(milliseconds: 260),
      ),
    );
  }

  void _next() {
    if (_page >= _slides.length - 1) {
      _finish();
      return;
    }
    _controller.nextPage(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffeaf2fb),
      body: Stack(
        children: [
          PageView.builder(
            controller: _controller,
            itemCount: _slides.length,
            onPageChanged: (index) => setState(() => _page = index),
            itemBuilder: (context, index) {
              return _OnboardingSlideView(
                slide: _slides[index],
                index: index,
                count: _slides.length,
                isLast: index == _slides.length - 1,
                onSkip: _finish,
                onNext: _next,
              );
            },
          ),
        ],
      ),
    );
  }
}

class _OnboardingSlideView extends StatelessWidget {
  final _OnboardingSlide slide;
  final int index;
  final int count;
  final bool isLast;
  final VoidCallback onSkip;
  final VoidCallback onNext;

  const _OnboardingSlideView({
    required this.slide,
    required this.index,
    required this.count,
    required this.isLast,
    required this.onSkip,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final topInset = MediaQuery.of(context).padding.top;
    final bottomInset = MediaQuery.of(context).padding.bottom;
    final imageHeight = size.height * 0.68;

    return SizedBox.expand(
      child: Stack(
        children: [
          Positioned.fill(
            child: Container(color: Colors.white),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: imageHeight + 32,
            child: Stack(
              fit: StackFit.expand,
              children: [
                slide.image.startsWith('http')
                    ? Image.network(
                        slide.image,
                        fit: BoxFit.cover,
                        alignment: Alignment.topCenter,
                      )
                    : Image.asset(
                        slide.image,
                        fit: BoxFit.cover,
                        alignment: Alignment.topCenter,
                      ),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withOpacity(0.06),
                        Colors.transparent,
                        Colors.black.withOpacity(0.10),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            top: topInset + 16,
            left: 14,
            child: slide.flag.isEmpty
                ? const SizedBox.shrink()
                : Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.18),
                          blurRadius: 14,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: slide.flag.endsWith('.png')
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: Image.asset(
                              slide.flag,
                              width: 54,
                              height: 34,
                              fit: BoxFit.cover,
                            ),
                          )
                        : Text(
                            slide.flag,
                            style: const TextStyle(fontSize: 30),
                          ),
                  ),
          ),
          Positioned(
            top: topInset + 18,
            right: 16,
            child: const _LinkupLogo(height: 38),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: size.height * 0.38 + bottomInset,
            child: ClipPath(
              clipper: _WaveTopClipper(),
              child: Container(
                color: Colors.white,
                padding: EdgeInsets.fromLTRB(24, 46, 24, 16 + bottomInset),
                child: Column(
                  children: [
                    if (slide.membership) ...[
                      const _VipLogoTitle(),
                      const SizedBox(height: 14),
                    ] else ...[
                      Text(
                        slide.title,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontFamily: 'OpenSans',
                          color: Color(0xff2d9ded),
                          fontSize: 25,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.4,
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    Expanded(
                      child: slide.membership
                          ? const _MembershipBullets()
                          : Text(
                              slide.body,
                              textAlign: TextAlign.center,
                              maxLines: 6,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontFamily: 'OpenSans',
                                color: Color(0xff65748d),
                                fontSize: 16,
                                height: 1.45,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                    DotsIndicator(
                      dotsCount: count,
                      position: index,
                      decorator: DotsDecorator(
                        color: const Color(0xffcad5e2),
                        activeColor: index == count - 1 ? const Color(0xff2d9ded) : LinkUpColors.linkupLime,
                        size: const Size(9, 9),
                        activeSize: const Size(9, 9),
                        spacing: const EdgeInsets.symmetric(horizontal: 4),
                        activeShape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(99),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      height: 56,
                      width: double.infinity,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xff32c1dc), Color(0xff2699f2)],
                          ),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xff2699f2).withOpacity(0.22),
                              blurRadius: 18,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: onNext,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: Text(
                            isLast ? 'GET STARTED' : 'Next',
                            style: const TextStyle(
                              fontFamily: 'OpenSans',
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: imageHeight - 58,
            right: 18,
            child: GestureDetector(
              onTap: onSkip,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.62),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Skip',
                  style: TextStyle(
                    fontFamily: 'OpenSans',
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WaveTopClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.moveTo(0, 34);
    path.quadraticBezierTo(size.width * 0.25, 50, size.width * 0.50, 34);
    path.quadraticBezierTo(size.width * 0.75, 18, size.width, 32);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class _LinkupLogo extends StatelessWidget {
  final double height;
  const _LinkupLogo({required this.height});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/Vector Smart Object 2.png',
      height: height,
      fit: BoxFit.contain,
    );
  }
}

class _VipLogoTitle extends StatelessWidget {
  const _VipLogoTitle();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const _LinkupLogo(height: 32),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: const Color(0xff38c8e7),
            borderRadius: BorderRadius.circular(7),
          ),
          child: const Text(
            'VIP',
            style: TextStyle(
              fontFamily: 'OpenSans',
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }
}

class _MembershipBullets extends StatelessWidget {
  const _MembershipBullets();

  @override
  Widget build(BuildContext context) {
    const items = [
      'Unlimited Calls',
      'Unlimited Video',
      'Unlimited Restaurant & Club Search',
      'Unlimited Live',
      'Top Shelf Profile',
      'Unlimited Swipes',
    ];

    return Column(
      children: [
        const Text(
          'Membership Includes',
          style: TextStyle(
            fontFamily: 'OpenSans',
            color: Color(0xff111827),
            fontSize: 17,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 14,
          runSpacing: 8,
          children: items
              .map(
                (item) => Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.check, size: 14, color: Color(0xff10b981)),
                    const SizedBox(width: 5),
                    Text(
                      item,
                      style: const TextStyle(
                        fontFamily: 'OpenSans',
                        color: Color(0xff65748d),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}