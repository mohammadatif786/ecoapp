import 'package:flutter/material.dart';
import 'package:link_up/theme/linkup_colors.dart';
import 'package:link_up/ui/DrawerScreen.dart';
import 'package:url_launcher/url_launcher.dart';

class ShopPage extends StatelessWidget {
  const ShopPage({super.key});

  static const String marketplaceUrl = 'https://linkupvibes.com/products';

  Future<void> _openMarketplace() async {
    final uri = Uri.parse(marketplaceUrl);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not open $marketplaceUrl');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      drawer: Drawer(child: DrawerScreen()),
      appBar: AppBar(
        backgroundColor: LinkUpColors.brandBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'LinkUp Marketplace',
          style: TextStyle(
            fontFamily: 'OpenSans',
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/shop.png',
                height: 72,
                width: 72,
              ),
              const SizedBox(height: 24),
              const Text(
                'Buy and sell on LinkUp',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'OpenSans',
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: LinkUpColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Browse products from sellers in the LinkUp community. '
                'The full marketplace is available on linkupvibes.com.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'OpenSans',
                  fontSize: 15,
                  height: 1.5,
                  color: LinkUpColors.textMuted,
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinkUpColors.ctaGradient,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ElevatedButton(
                    onPressed: _openMarketplace,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Browse marketplace',
                      style: TextStyle(
                        fontFamily: 'OpenSans',
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
