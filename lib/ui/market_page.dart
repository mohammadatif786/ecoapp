import 'package:flutter/material.dart';
import 'package:link_up/ui/profile/profile_page.dart';
import 'package:link_up/widgets/linkup_location_sheet.dart';
import '../widgets/linkup_current_user.dart';
import 'package:get/get.dart';
import 'package:link_up/get_controller/home_controller.dart';
import 'package:link_up/ui/wallet_page.dart';

import 'chat_home_page.dart';
import 'eats_page.dart';
import 'live_page.dart';
import 'vibes_page.dart';
import 'package:link_up/ui/notification_page.dart';

class MarketPage extends StatefulWidget {
  const MarketPage({super.key});

  @override
  State<MarketPage> createState() => _MarketPageState();
}

class _MarketPageState extends State<MarketPage> {
  final HomeController homeController = Get.find(tag: HomeController().toString());
  int _categoryIndex = 0;
  int _tabIndex = 0;
  int _cartCount = 0;

  final List<String> _tabs = const ['Market', 'Orders', 'Selling', 'Saved'];
  final List<String> _categories = const ['All', 'Food', 'Crafts', 'Fashion', 'Beauty', 'Tech', 'Services'];

  final List<_MarketProduct> _products = const [
    _MarketProduct(
      title: 'Straw Bags',
      seller: 'Island Market',
      price: '\$35',
      tag: 'New drop',
      image: 'https://images.unsplash.com/photo-1590874103328-eac38a683ce7?auto=format&fit=crop&w=900&q=80',
      category: 'Crafts',
      location: 'The Valley',
      description: 'Hand-woven straw bags from local makers. Lightweight, beach-ready and available in three sizes.',
    ),
    _MarketProduct(
      title: 'Carnival Tee',
      seller: 'Soca Prints',
      price: '\$28',
      tag: 'Trending',
      image: 'https://images.unsplash.com/photo-1523381294911-8d3cead13475?auto=format&fit=crop&w=900&q=80',
      category: 'Fashion',
      location: 'Road Town',
      description: 'Limited carnival graphic tee with soft cotton and bold island artwork.',
    ),
    _MarketProduct(
      title: 'Mango Pepper Sauce',
      seller: 'Bahama Bites',
      price: '\$12',
      tag: 'Food',
      image: 'https://images.unsplash.com/photo-1604908176997-125f25cc6f3d?auto=format&fit=crop&w=900&q=80',
      category: 'Food',
      location: 'Nassau',
      description: 'Small-batch pepper sauce with ripe mango, Scotch bonnet and a clean citrus finish.',
    ),
    _MarketProduct(
      title: 'Festival Makeup Slot',
      seller: 'Glow by Renee',
      price: '\$55',
      tag: 'Beauty',
      image: 'https://images.unsplash.com/photo-1522335789203-aabd1fc54bc9?auto=format&fit=crop&w=900&q=80',
      category: 'Beauty',
      location: 'The Valley',
      description: 'Book a glam appointment for Carnival week. Includes lashes, gems and long-wear setting.',
    ),
    _MarketProduct(
      title: 'DJ Speaker Rental',
      seller: 'Echo Club',
      price: '\$90',
      tag: 'Service',
      image: 'https://images.unsplash.com/photo-1526948128573-703ee1aeb6fa?auto=format&fit=crop&w=900&q=80',
      category: 'Services',
      location: 'The Valley',
      description: 'Portable speaker rental for beach days, pop-ups and private events. Delivery available.',
    ),
    _MarketProduct(
      title: 'Wireless Earbuds',
      seller: 'Tech Hut',
      price: '\$49',
      tag: 'Tech',
      image: 'https://images.unsplash.com/photo-1606220945770-b5b6c2c55bf1?auto=format&fit=crop&w=900&q=80',
      category: 'Tech',
      location: 'St. John\'s',
      description: 'Compact Bluetooth earbuds with charging case, noise reduction and splash resistance.',
    ),
  ];

  double _ui(BuildContext context, double value) {
    final width = MediaQuery.of(context).size.width;
    return value * (width / 430).clamp(0.86, 1.08).toDouble();
  }

  double _font(BuildContext context, double value) => _ui(context, value);

  IconData _tabIcon(String tab) {
    switch (tab) {
      case 'Orders':
        return Icons.receipt_long_outlined;
      case 'Selling':
        return Icons.sell_outlined;
      case 'Saved':
        return Icons.favorite_border_rounded;
      default:
        return Icons.storefront_outlined;
    }
  }

  Color _tabColor(String tab) {
    switch (tab) {
      case 'Orders':
        return const Color(0xff1985ff);
      case 'Selling':
        return const Color(0xff12b78f);
      case 'Saved':
        return const Color(0xffff2e86);
      default:
        return const Color(0xffff9f0a);
    }
  }

  IconData _categoryIcon(String category) {
    switch (category) {
      case 'Food':
        return Icons.restaurant_outlined;
      case 'Crafts':
        return Icons.palette_outlined;
      case 'Fashion':
        return Icons.checkroom_outlined;
      case 'Beauty':
        return Icons.spa_outlined;
      case 'Tech':
        return Icons.devices_outlined;
      case 'Services':
        return Icons.miscellaneous_services_outlined;
      default:
        return Icons.grid_view_rounded;
    }
  }

  Color _categoryColor(String category) {
    switch (category) {
      case 'Food':
        return const Color(0xff18b957);
      case 'Crafts':
        return const Color(0xffff9f0a);
      case 'Fashion':
        return const Color(0xffff2e86);
      case 'Beauty':
        return const Color(0xffb23cff);
      case 'Tech':
        return const Color(0xff1985ff);
      case 'Services':
        return const Color(0xff14b8a6);
      default:
        return const Color(0xff5b53ff);
    }
  }

  List<Color> _categoryGradient(String category) {
    final base = _categoryColor(category);
    if (category == 'Crafts') return const [Color(0xffff9f0a), Color(0xffff4d6d)];
    if (category == 'Fashion') return const [Color(0xffff2e86), Color(0xff7c3aed)];
    if (category == 'Beauty') return const [Color(0xffb23cff), Color(0xff27d3ff)];
    if (category == 'Food') return const [Color(0xff18b957), Color(0xff8bdc22)];
    if (category == 'Tech') return const [Color(0xff1985ff), Color(0xff5b53ff)];
    if (category == 'Services') return const [Color(0xff14b8a6), Color(0xff007d6c)];
    return [base, const Color(0xff1985ff)];
  }

  List<_MarketProduct> get _visibleProducts {
    if (_categoryIndex == 0) return _products;
    final selected = _categories[_categoryIndex];
    return _products.where((p) => p.category == selected).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffe9f5ff),
      body: SafeArea(
        child: Column(
          children: [
            _topBar(context),
            _locationBar(context),
            Expanded(
              child: ListView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.fromLTRB(_ui(context, 14), _ui(context, 12), _ui(context, 14), _ui(context, 24)),
                children: [
                  _marketHeader(context),
                  SizedBox(height: _ui(context, 12)),
                  _tabRail(context),
                  SizedBox(height: _ui(context, 12)),
                  if (_tabIndex == 0) ...[
                    _searchAndFilters(context),
                    SizedBox(height: _ui(context, 12)),
                    _categoryRail(context),
                    SizedBox(height: _ui(context, 14)),
                    _promoCard(context),
                    SizedBox(height: _ui(context, 16)),
                    _sectionHeader(context, 'Featured near you', 'Cart ($_cartCount)', Icons.shopping_bag_outlined, onTap: () => _showCartSheet(context)),
                    SizedBox(height: _ui(context, 10)),
                    _productGrid(context),
                  ] else if (_tabIndex == 1) ...[
                    _orderList(context),
                  ] else if (_tabIndex == 2) ...[
                    _sellingPanel(context),
                  ] else ...[
                    _savedPanel(context),
                  ],
                ],
              ),
            ),
            _bottomBar(context),
          ],
        ),
      ),
    );
  }

  Widget _topBar(BuildContext context) {
    return Container(
      height: _ui(context, 64),
      padding: EdgeInsets.symmetric(horizontal: _ui(context, 16)),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xff1da1ff), Color(0xff127be8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        children: [
          const Text('ü', style: TextStyle(color: Color(0xffb8ef34), fontWeight: FontWeight.w900, fontSize: 24)),
          SizedBox(width: _ui(context, 5)),
          const Text('Link', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, fontSize: 25)),
          const Text('up', style: TextStyle(color: Color(0xffffde3f), fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, fontSize: 25)),
          const Spacer(),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => Get.to(() => const WalletPage()),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: _ui(context, 12), vertical: _ui(context, 7)),
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(999)),
              child: Row(children: [Icon(Icons.link, color: Colors.white, size: _ui(context, 16)), SizedBox(width: _ui(context, 5)), Text('${homeController.coins}', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: _font(context, 14)))]),
            ),
          ),
          SizedBox(width: _ui(context, 10)),
          LinkUpNotificationBell(
            iconSize: _ui(context, 28),
            badgeSize: _ui(context, 18),
            badgeFontSize: _font(context, 10),
          ),
          SizedBox(width: _ui(context, 10)),
          LinkUpCurrentUserAvatar(
            radius: _ui(context, 18),
            innerRadius: _ui(context, 16),
            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => ProfilePage())),
          ),
        ],
      ),
    );
  }

  Widget _locationBar(BuildContext context) {
    return LinkupLocationBar(
      height: _ui(context, 30),
      horizontalPadding: _ui(context, 15),
      iconSize: _ui(context, 17),
      fontSize: _font(context, 12),
      changeFontSize: _font(context, 12),
      textColor: const Color(0xff1d2637),
      changeColor: const Color(0xff1985ff),
      iconColor: const Color(0xff1985ff),
    );
  }

  Widget _marketHeader(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(_ui(context, 15)),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xffff9f0a), Color(0xffff4d6d), Color(0xff7c3aed)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(_ui(context, 24)),
        boxShadow: [BoxShadow(color: const Color(0xffff7a1a).withOpacity(0.22), blurRadius: 18, offset: const Offset(0, 8))],
      ),
      child: Row(
        children: [
          Container(
            width: _ui(context, 50),
            height: _ui(context, 50),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(_ui(context, 16))),
            child: Icon(Icons.shopping_bag_outlined, color: Colors.white, size: _ui(context, 28)),
          ),
          SizedBox(width: _ui(context, 12)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Market', style: TextStyle(color: Colors.white, fontSize: _font(context, 27), fontWeight: FontWeight.w900, height: 1.0)),
                SizedBox(height: _ui(context, 4)),
                Text('Buy, sell & discover island drops.', style: TextStyle(color: Colors.white.withOpacity(0.92), fontSize: _font(context, 12), fontWeight: FontWeight.w700)),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => _showSellSheet(context),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: _ui(context, 14), vertical: _ui(context, 10)),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(999)),
              child: Row(children: [Icon(Icons.add, color: const Color(0xff7c3aed), size: _ui(context, 18)), Text('Sell', style: TextStyle(color: const Color(0xff7c3aed), fontSize: _font(context, 14), fontWeight: FontWeight.w900))]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tabRail(BuildContext context) {
    return SizedBox(
      height: _ui(context, 42),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: _tabs.length,
        separatorBuilder: (_, __) => SizedBox(width: _ui(context, 8)),
        itemBuilder: (context, index) {
          final selected = index == _tabIndex;
          final tab = _tabs[index];
          final color = _tabColor(tab);
          return GestureDetector(
            onTap: () => setState(() => _tabIndex = index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              padding: EdgeInsets.symmetric(horizontal: _ui(context, 14)),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: selected ? Colors.white : Colors.white.withOpacity(0.54),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: selected ? Colors.white : Colors.white.withOpacity(0.88), width: 1.2),
                boxShadow: selected ? [BoxShadow(color: color.withOpacity(0.18), blurRadius: 12, offset: const Offset(0, 5))] : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(_tabIcon(tab), color: selected ? color : const Color(0xff617089), size: _ui(context, 17)),
                  SizedBox(width: _ui(context, 6)),
                  Text(tab, style: TextStyle(color: selected ? const Color(0xff10182b) : const Color(0xff56647a), fontSize: _font(context, 13), fontWeight: FontWeight.w900)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _searchAndFilters(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: _ui(context, 46),
            padding: EdgeInsets.symmetric(horizontal: _ui(context, 14)),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(999), border: Border.all(color: const Color(0xffdbe7f4))),
            child: Row(children: [Icon(Icons.search, color: const Color(0xff8fa0b8), size: _ui(context, 21)), SizedBox(width: _ui(context, 8)), Expanded(child: Text('Search products, sellers, services...', style: TextStyle(color: const Color(0xff8fa0b8), fontSize: _font(context, 13), fontWeight: FontWeight.w700)))]),
          ),
        ),
        SizedBox(width: _ui(context, 8)),
        GestureDetector(
          onTap: () => _showFilterSheet(context),
          child: Container(
            width: _ui(context, 46),
            height: _ui(context, 46),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(_ui(context, 15)), border: Border.all(color: const Color(0xffdbe7f4))),
            child: Icon(Icons.tune, color: const Color(0xff1985ff), size: _ui(context, 22)),
          ),
        ),
      ],
    );
  }

  Widget _categoryRail(BuildContext context) {
    return SizedBox(
      height: _ui(context, 46),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: _categories.length,
        separatorBuilder: (_, __) => SizedBox(width: _ui(context, 8)),
        itemBuilder: (context, index) {
          final selected = index == _categoryIndex;
          final category = _categories[index];
          final color = _categoryColor(category);
          return GestureDetector(
            onTap: () => setState(() => _categoryIndex = index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              padding: EdgeInsets.only(left: _ui(context, 7), right: _ui(context, 13)),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: selected ? Colors.white : color.withOpacity(0.13),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: selected ? Colors.white : color.withOpacity(0.24), width: 1.2),
                boxShadow: selected ? [BoxShadow(color: color.withOpacity(0.18), blurRadius: 12, offset: const Offset(0, 5))] : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: _ui(context, 30),
                    height: _ui(context, 30),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: _categoryGradient(category)),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(_categoryIcon(category), color: Colors.white, size: _ui(context, 16)),
                  ),
                  SizedBox(width: _ui(context, 7)),
                  Text(category, style: TextStyle(color: selected ? const Color(0xff10182b) : const Color(0xff46556f), fontSize: _font(context, 12), fontWeight: FontWeight.w900)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _promoCard(BuildContext context) {
    return GestureDetector(
      onTap: () => _showSellSheet(context),
      child: Container(
        padding: EdgeInsets.all(_ui(context, 14)),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xff111c3b), Color(0xff0b9f88)]),
          borderRadius: BorderRadius.circular(_ui(context, 22)),
        ),
        child: Row(
          children: [
            Container(width: _ui(context, 48), height: _ui(context, 48), decoration: BoxDecoration(color: Colors.white.withOpacity(0.18), borderRadius: BorderRadius.circular(_ui(context, 14))), child: const Icon(Icons.local_mall_outlined, color: Colors.white)),
            SizedBox(width: _ui(context, 12)),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Sell on LinkUp Market', style: TextStyle(color: Colors.white, fontSize: _font(context, 18), fontWeight: FontWeight.w900)), Text('Post products, services or quick drops in seconds.', style: TextStyle(color: Colors.white.withOpacity(0.86), fontSize: _font(context, 12), fontWeight: FontWeight.w600))])),
            Icon(Icons.arrow_forward, color: Colors.white, size: _ui(context, 25)),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(BuildContext context, String title, String action, IconData icon, {VoidCallback? onTap}) {
    return Row(
      children: [
        Expanded(child: Text(title, style: TextStyle(color: const Color(0xff10182b), fontSize: _font(context, 21), fontWeight: FontWeight.w900))),
        GestureDetector(
          onTap: onTap,
          child: Row(children: [Text(action, style: TextStyle(color: const Color(0xff1985ff), fontSize: _font(context, 12), fontWeight: FontWeight.w900)), SizedBox(width: _ui(context, 4)), Icon(icon, color: const Color(0xff1985ff), size: _ui(context, 17))]),
        ),
      ],
    );
  }

  Widget _productGrid(BuildContext context) {
    final products = _visibleProducts;
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: products.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: _ui(context, 10), mainAxisSpacing: _ui(context, 10), childAspectRatio: 0.72),
      itemBuilder: (context, index) => _productCard(context, products[index]),
    );
  }

  Widget _productCard(BuildContext context, _MarketProduct product) {
    return GestureDetector(
      onTap: () => _showProductSheet(context, product),
      child: Container(
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(_ui(context, 18)), boxShadow: [BoxShadow(color: const Color(0xff1b3b70).withOpacity(0.06), blurRadius: 14, offset: const Offset(0, 6))]),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(product.image, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(color: const Color(0xffdbe7f4), child: const Icon(Icons.image_outlined))),
                  Positioned(
                    left: _ui(context, 8),
                    top: _ui(context, 8),
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: _ui(context, 8), vertical: _ui(context, 4)),
                      decoration: BoxDecoration(gradient: LinearGradient(colors: _categoryGradient(product.category)), borderRadius: BorderRadius.circular(999)),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(_categoryIcon(product.category), color: Colors.white, size: _ui(context, 11)), SizedBox(width: _ui(context, 3)), Text(product.tag, style: TextStyle(color: Colors.white, fontSize: _font(context, 9), fontWeight: FontWeight.w900))]),
                    ),
                  ),
                  Positioned(
                    right: _ui(context, 8),
                    top: _ui(context, 8),
                    child: Container(width: _ui(context, 28), height: _ui(context, 28), decoration: BoxDecoration(color: Colors.black.withOpacity(0.25), shape: BoxShape.circle), child: Icon(Icons.favorite_border, color: Colors.white, size: _ui(context, 17))),
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.all(_ui(context, 10)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(product.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: const Color(0xff10182b), fontSize: _font(context, 14), fontWeight: FontWeight.w900)),
                  SizedBox(height: _ui(context, 3)),
                  Text(product.seller, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: const Color(0xff8694ad), fontSize: _font(context, 10), fontWeight: FontWeight.w700)),
                  SizedBox(height: _ui(context, 6)),
                  Row(children: [Container(padding: EdgeInsets.symmetric(horizontal: _ui(context, 9), vertical: _ui(context, 4)), decoration: BoxDecoration(color: _categoryColor(product.category).withOpacity(0.10), borderRadius: BorderRadius.circular(999)), child: Text(product.price, style: TextStyle(color: _categoryColor(product.category), fontSize: _font(context, 13), fontWeight: FontWeight.w900))), const Spacer(), Icon(Icons.location_on_outlined, size: _ui(context, 13), color: const Color(0xff9bacbf)), Flexible(child: Text(product.location, overflow: TextOverflow.ellipsis, style: TextStyle(color: const Color(0xff9bacbf), fontSize: _font(context, 9), fontWeight: FontWeight.w700)))]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showProductSheet(BuildContext context, _MarketProduct product) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _marketSheet(
        context,
        maxHeight: 0.88,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sheetHeader(context, title: product.title, subtitle: product.seller, icon: _categoryIcon(product.category), color: _categoryColor(product.category)),
            Expanded(
              child: ListView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.all(_ui(context, 14)),
                children: [
                  ClipRRect(borderRadius: BorderRadius.circular(_ui(context, 18)), child: AspectRatio(aspectRatio: 16 / 10, child: Image.network(product.image, fit: BoxFit.cover))),
                  SizedBox(height: _ui(context, 12)),
                  Row(children: [Expanded(child: Text(product.title, style: TextStyle(fontSize: _font(context, 23), fontWeight: FontWeight.w900, color: const Color(0xff10182b)))), Container(padding: EdgeInsets.symmetric(horizontal: _ui(context, 12), vertical: _ui(context, 6)), decoration: BoxDecoration(color: _categoryColor(product.category).withOpacity(0.10), borderRadius: BorderRadius.circular(999)), child: Text(product.price, style: TextStyle(color: _categoryColor(product.category), fontSize: _font(context, 20), fontWeight: FontWeight.w900)))]),
                  SizedBox(height: _ui(context, 6)),
                  Row(children: [Icon(Icons.location_on_outlined, color: const Color(0xff8ca0b7), size: _ui(context, 17)), Text(product.location, style: TextStyle(color: const Color(0xff687790), fontSize: _font(context, 12), fontWeight: FontWeight.w700)), const Spacer(), _miniBadge(context, product.category)]),
                  SizedBox(height: _ui(context, 12)),
                  _infoBox(context, 'Description', product.description),
                  SizedBox(height: _ui(context, 10)),
                  _sellerBox(context, product),
                  SizedBox(height: _ui(context, 12)),
                  Row(children: [Expanded(child: _outlineButton(context, 'Make Offer', Icons.local_offer_outlined, () => _showOfferSheet(context, product))), SizedBox(width: _ui(context, 8)), Expanded(child: _outlineButton(context, 'Message Seller', Icons.chat_bubble_outline, () => _showMessageSheet(context, product)))]),
                  SizedBox(height: _ui(context, 10)),
                  Row(children: [Expanded(child: _gradientButton(context, 'Add to Cart', Icons.add_shopping_cart, () { setState(() => _cartCount++); Navigator.pop(context); _toast(context, 'Added to cart'); })), SizedBox(width: _ui(context, 8)), Expanded(child: _gradientButton(context, 'Buy Now', Icons.flash_on_outlined, () => _showCheckoutSheet(context, product)))]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sellerBox(BuildContext context, _MarketProduct product) {
    return Container(
      padding: EdgeInsets.all(_ui(context, 12)),
      decoration: BoxDecoration(color: const Color(0xfff8fbff), borderRadius: BorderRadius.circular(_ui(context, 16)), border: Border.all(color: const Color(0xffe0e9f4))),
      child: Row(
        children: [
          const CircleAvatar(backgroundImage: NetworkImage('https://images.unsplash.com/photo-1500648767791-00dcc994a43e?auto=format&fit=crop&w=200&q=80')),
          SizedBox(width: _ui(context, 10)),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(product.seller, style: TextStyle(fontSize: _font(context, 14), fontWeight: FontWeight.w900)), Text('Verified seller · responds within 1 hour', style: TextStyle(color: const Color(0xff8ca0b7), fontSize: _font(context, 11), fontWeight: FontWeight.w700))])),
          Container(padding: EdgeInsets.symmetric(horizontal: _ui(context, 10), vertical: _ui(context, 6)), decoration: BoxDecoration(color: const Color(0xffe8fff6), borderRadius: BorderRadius.circular(999)), child: Text('Follow', style: TextStyle(color: const Color(0xff07966d), fontSize: _font(context, 11), fontWeight: FontWeight.w900))),
        ],
      ),
    );
  }

  Widget _miniBadge(BuildContext context, String text) {
    final color = _categoryColor(text);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: _ui(context, 10), vertical: _ui(context, 6)),
      decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(999), border: Border.all(color: color.withOpacity(0.18))),
      child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(_categoryIcon(text), color: color, size: _ui(context, 13)), SizedBox(width: _ui(context, 4)), Text(text, style: TextStyle(color: color, fontSize: _font(context, 11), fontWeight: FontWeight.w900))]),
    );
  }

  Widget _infoBox(BuildContext context, String title, String body) {
    return Container(
      padding: EdgeInsets.all(_ui(context, 12)),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(_ui(context, 16)), border: Border.all(color: const Color(0xffe0e9f4))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: TextStyle(fontSize: _font(context, 15), fontWeight: FontWeight.w900)), SizedBox(height: _ui(context, 5)), Text(body, style: TextStyle(color: const Color(0xff5b6a82), fontSize: _font(context, 13), fontWeight: FontWeight.w600, height: 1.35))]),
    );
  }

  Widget _orderList(BuildContext context) {
    return Column(
      children: [
        _wideRow(context, icon: Icons.local_shipping_outlined, title: 'Straw Bags', subtitle: 'Out for delivery · Today', amount: '\$35.00', action: 'Track', onTap: () => _showTrackingSheet(context)),
        _wideRow(context, icon: Icons.check_circle_outline, title: 'Mango Pepper Sauce', subtitle: 'Delivered Apr 28', amount: '\$12.00', action: 'Receipt', onTap: () => _showReceiptSheet(context)),
        _wideRow(context, icon: Icons.pending_actions_outlined, title: 'Carnival Tee', subtitle: 'Seller preparing order', amount: '\$28.00', action: 'Details', onTap: () => _showReceiptSheet(context)),
      ],
    );
  }

  Widget _sellingPanel(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _statsCard(context),
        SizedBox(height: _ui(context, 12)),
        _wideRow(context, icon: Icons.inventory_2_outlined, title: 'Festival Makeup Slot', subtitle: 'Active listing · 8 views', amount: '\$55', action: 'Edit', onTap: () => _showSellSheet(context)),
        _wideRow(context, icon: Icons.inventory_2_outlined, title: 'DJ Speaker Rental', subtitle: 'Active listing · 12 views', amount: '\$90', action: 'Boost', onTap: () => _showBoostSheet(context)),
        SizedBox(height: _ui(context, 8)),
        _gradientButton(context, 'Add a listing', Icons.add, () => _showSellSheet(context)),
      ],
    );
  }

  Widget _savedPanel(BuildContext context) {
    return Column(
      children: [
        _wideRow(context, icon: Icons.favorite_border, title: 'Straw Bags', subtitle: 'Saved from Island Market', amount: '\$35', action: 'View', onTap: () => _showProductSheet(context, _products.first)),
        _wideRow(context, icon: Icons.favorite_border, title: 'Wireless Earbuds', subtitle: 'Saved from Tech Hut', amount: '\$49', action: 'View', onTap: () => _showProductSheet(context, _products.last)),
      ],
    );
  }

  Widget _statsCard(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(_ui(context, 14)),
      decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xff0b3b5f), Color(0xff0bbf9a)]), borderRadius: BorderRadius.circular(_ui(context, 20))),
      child: Row(
        children: [
          _stat(context, 'Sales', '\$245'),
          _divider(),
          _stat(context, 'Views', '184'),
          _divider(),
          _stat(context, 'Orders', '6'),
        ],
      ),
    );
  }

  Widget _stat(BuildContext context, String label, String value) {
    return Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: TextStyle(color: Colors.white.withOpacity(0.75), fontSize: _font(context, 11), fontWeight: FontWeight.w700)), Text(value, style: TextStyle(color: Colors.white, fontSize: _font(context, 23), fontWeight: FontWeight.w900))]));
  }

  Widget _divider() => Container(width: 1, height: 35, color: Colors.white.withOpacity(0.24));

  Widget _wideRow(BuildContext context, {required IconData icon, required String title, required String subtitle, required String amount, required String action, required VoidCallback onTap}) {
    return Container(
      margin: EdgeInsets.only(bottom: _ui(context, 10)),
      padding: EdgeInsets.all(_ui(context, 12)),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(_ui(context, 18)), border: Border.all(color: const Color(0xffe0e9f4))),
      child: Row(
        children: [
          Container(width: _ui(context, 42), height: _ui(context, 42), decoration: BoxDecoration(color: const Color(0xffeef6ff), borderRadius: BorderRadius.circular(_ui(context, 14))), child: Icon(icon, color: const Color(0xff1985ff), size: _ui(context, 22))),
          SizedBox(width: _ui(context, 10)),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: TextStyle(fontSize: _font(context, 14), fontWeight: FontWeight.w900)), Text(subtitle, style: TextStyle(color: const Color(0xff8796ad), fontSize: _font(context, 11), fontWeight: FontWeight.w700))])),
          Text(amount, style: TextStyle(fontSize: _font(context, 14), fontWeight: FontWeight.w900)),
          SizedBox(width: _ui(context, 8)),
          GestureDetector(onTap: onTap, child: Container(padding: EdgeInsets.symmetric(horizontal: _ui(context, 10), vertical: _ui(context, 7)), decoration: BoxDecoration(color: const Color(0xff1985ff), borderRadius: BorderRadius.circular(999)), child: Text(action, style: TextStyle(color: Colors.white, fontSize: _font(context, 11), fontWeight: FontWeight.w900)))),
        ],
      ),
    );
  }

  void _showSellSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _marketSheet(
        context,
        maxHeight: 0.9,
        child: Column(
          children: [
            _sheetHeader(context, title: 'Create Listing', subtitle: 'Post a product, service or quick drop.', icon: Icons.add_business_outlined, color: const Color(0xffff9f0a)),
            Expanded(
              child: ListView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.all(_ui(context, 14)),
                children: [
                  _label(context, 'Listing title'),
                  _input(context, 'e.g. Handmade straw bag'),
                  SizedBox(height: _ui(context, 10)),
                  _label(context, 'Category'),
                  _choiceWrap(context, _categories.skip(1).toList()),
                  SizedBox(height: _ui(context, 10)),
                  Row(children: [Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [_label(context, 'Price (USD)'), _input(context, '0.00')])), SizedBox(width: _ui(context, 10)), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [_label(context, 'Quantity'), _input(context, '1')]))]),
                  SizedBox(height: _ui(context, 10)),
                  _label(context, 'Description'),
                  _input(context, 'Describe condition, pickup, delivery...', lines: 4),
                  SizedBox(height: _ui(context, 12)),
                  _uploadBox(context, 'Add photos'),
                  SizedBox(height: _ui(context, 12)),
                  _notice(context, Icons.local_shipping_outlined, 'Pickup and delivery can be negotiated in chat. LinkUp Wallet is recommended for safer payment.'),
                  SizedBox(height: _ui(context, 12)),
                  _gradientButton(context, 'Post Listing', Icons.publish_outlined, () { Navigator.pop(context); _toast(context, 'Listing posted'); }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showFilterSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _marketSheet(
        context,
        maxHeight: 0.56,
        child: Column(
          children: [
            _sheetHeader(context, title: 'Filters', subtitle: 'Refine market results.', icon: Icons.tune, color: const Color(0xff1985ff)),
            Padding(
              padding: EdgeInsets.all(_ui(context, 14)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _label(context, 'Sort by'),
                _choiceWrap(context, const ['Newest', 'Nearest', 'Lowest price', 'Popular']),
                SizedBox(height: _ui(context, 12)),
                _label(context, 'Price range'),
                Row(children: [Expanded(child: _input(context, 'Min')), SizedBox(width: _ui(context, 10)), Expanded(child: _input(context, 'Max'))]),
                SizedBox(height: _ui(context, 12)),
                _gradientButton(context, 'Apply Filters', Icons.check, () => Navigator.pop(context)),
              ]),
            ),
          ],
        ),
      ),
    );
  }

  void _showOfferSheet(BuildContext context, _MarketProduct product) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _marketSheet(
        context,
        maxHeight: 0.48,
        child: Column(
          children: [
            _sheetHeader(context, title: 'Make Offer', subtitle: product.title, icon: Icons.local_offer_outlined, color: const Color(0xff16c7a8)),
            Padding(
              padding: EdgeInsets.all(_ui(context, 14)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _label(context, 'Your offer'),
                _input(context, 'Amount (USD)'),
                SizedBox(height: _ui(context, 10)),
                _notice(context, Icons.info_outline, 'The seller can accept, decline or counter your offer.'),
                SizedBox(height: _ui(context, 12)),
                _gradientButton(context, 'Send Offer', Icons.send_outlined, () { Navigator.pop(context); _toast(context, 'Offer sent'); }),
              ]),
            ),
          ],
        ),
      ),
    );
  }

  void _showMessageSheet(BuildContext context, _MarketProduct product) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _marketSheet(
        context,
        maxHeight: 0.45,
        child: Column(
          children: [
            _sheetHeader(context, title: 'Message Seller', subtitle: product.seller, icon: Icons.chat_bubble_outline, color: const Color(0xff7c3aed)),
            Padding(
              padding: EdgeInsets.all(_ui(context, 14)),
              child: Column(children: [
                _input(context, 'Hi, is ${product.title} still available?', lines: 4),
                SizedBox(height: _ui(context, 12)),
                _gradientButton(context, 'Send Message', Icons.send_outlined, () { Navigator.pop(context); Get.to(() => ChatHomePage()); }),
              ]),
            ),
          ],
        ),
      ),
    );
  }

  void _showCheckoutSheet(BuildContext context, _MarketProduct product) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _marketSheet(
        context,
        maxHeight: 0.56,
        child: Column(
          children: [
            _sheetHeader(context, title: 'Checkout', subtitle: product.title, icon: Icons.shopping_bag_outlined, color: const Color(0xffff9f0a)),
            Padding(
              padding: EdgeInsets.all(_ui(context, 14)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _summaryLine(context, product.title, product.price),
                _summaryLine(context, 'Delivery / pickup', 'Arrange in chat'),
                _summaryLine(context, 'Payment method', 'LinkUp Wallet'),
                SizedBox(height: _ui(context, 12)),
                _notice(context, Icons.shield_outlined, 'Paying with LinkUp Wallet creates a safer record of the order.'),
                SizedBox(height: _ui(context, 12)),
                _gradientButton(context, 'Pay with Wallet', Icons.account_balance_wallet_outlined, () { Navigator.pop(context); _toast(context, 'Payment started'); }),
              ]),
            ),
          ],
        ),
      ),
    );
  }

  void _showCartSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _marketSheet(
        context,
        maxHeight: 0.5,
        child: Column(
          children: [
            _sheetHeader(context, title: 'Cart', subtitle: _cartCount == 0 ? 'No items yet' : '$_cartCount item${_cartCount == 1 ? '' : 's'} ready', icon: Icons.shopping_bag_outlined, color: const Color(0xffff9f0a)),
            Padding(
              padding: EdgeInsets.all(_ui(context, 14)),
              child: _cartCount == 0 ? _emptyState(context, Icons.shopping_bag_outlined, 'Your cart is empty', 'Tap a product and add it to cart.') : Column(children: [_wideRow(context, icon: Icons.shopping_bag_outlined, title: 'Market item', subtitle: 'Saved in cart', amount: '\$35.00', action: 'Pay', onTap: () => _showCheckoutSheet(context, _products.first)), _gradientButton(context, 'Checkout', Icons.payment, () => _showCheckoutSheet(context, _products.first))]),
            ),
          ],
        ),
      ),
    );
  }

  void _showTrackingSheet(BuildContext context) => _simpleSheet(context, 'Order Tracking', 'Your order is out for delivery and should arrive today.', Icons.local_shipping_outlined, const Color(0xff1985ff));
  void _showReceiptSheet(BuildContext context) => _simpleSheet(context, 'Receipt', 'Payment completed with LinkUp Wallet. Seller payout is scheduled after confirmation.', Icons.receipt_long_outlined, const Color(0xff16c7a8));
  void _showBoostSheet(BuildContext context) => _simpleSheet(context, 'Boost Listing', 'Promote your listing in the Market and Home feed for more views.', Icons.trending_up, const Color(0xffff2e86));

  void _simpleSheet(BuildContext context, String title, String message, IconData icon, Color color) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _marketSheet(
        context,
        maxHeight: 0.4,
        child: Column(children: [_sheetHeader(context, title: title, subtitle: 'Market', icon: icon, color: color), Padding(padding: EdgeInsets.all(_ui(context, 14)), child: Column(children: [_notice(context, icon, message), SizedBox(height: _ui(context, 12)), _gradientButton(context, 'Done', Icons.check, () => Navigator.pop(context))]))]),
      ),
    );
  }

  Widget _marketSheet(BuildContext context, {required Widget child, double maxHeight = 0.86}) {
    return Material(
      color: Colors.transparent,
      child: Container(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * maxHeight),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(_ui(context, 26)))),
        clipBehavior: Clip.antiAlias,
        child: child,
      ),
    );
  }

  Widget _sheetHeader(BuildContext context, {required String title, required String subtitle, required IconData icon, required Color color}) {
    return Container(
      padding: EdgeInsets.fromLTRB(_ui(context, 16), _ui(context, 16), _ui(context, 8), _ui(context, 15)),
      decoration: BoxDecoration(gradient: LinearGradient(colors: [color, color.withOpacity(0.72)], begin: Alignment.centerLeft, end: Alignment.centerRight)),
      child: Row(children: [Container(width: _ui(context, 38), height: _ui(context, 38), decoration: BoxDecoration(color: Colors.white.withOpacity(0.22), borderRadius: BorderRadius.circular(_ui(context, 12))), child: Icon(icon, color: Colors.white, size: _ui(context, 22))), SizedBox(width: _ui(context, 10)), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: TextStyle(color: Colors.white, fontSize: _font(context, 21), fontWeight: FontWeight.w900)), Text(subtitle, style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: _font(context, 12), fontWeight: FontWeight.w600))])), GestureDetector(onTap: () => Navigator.of(context).pop(), child: Container(width: _ui(context, 34), height: _ui(context, 34), decoration: BoxDecoration(color: Colors.white.withOpacity(0.18), shape: BoxShape.circle), child: Icon(Icons.close_rounded, color: Colors.white, size: _ui(context, 22))))]),
    );
  }

  Widget _label(BuildContext context, String text) => Padding(padding: EdgeInsets.only(bottom: _ui(context, 6)), child: Text(text.toUpperCase(), style: TextStyle(color: const Color(0xff6a7890), fontSize: _font(context, 11), fontWeight: FontWeight.w900)));

  Widget _input(BuildContext context, String hint, {int lines = 1}) {
    return TextField(
      maxLines: lines,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xff9aa8ba), fontWeight: FontWeight.w700),
        filled: true,
        fillColor: const Color(0xfff8fbff),
        contentPadding: EdgeInsets.symmetric(horizontal: _ui(context, 14), vertical: _ui(context, 14)),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(_ui(context, 14)), borderSide: const BorderSide(color: Color(0xffe0e9f4))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(_ui(context, 14)), borderSide: const BorderSide(color: Color(0xffe0e9f4))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(_ui(context, 14)), borderSide: const BorderSide(color: Color(0xff1985ff), width: 1.5)),
      ),
    );
  }

  Widget _choiceWrap(BuildContext context, List<String> items) {
    return Wrap(
      spacing: _ui(context, 8),
      runSpacing: _ui(context, 8),
      children: items.map((e) => Container(padding: EdgeInsets.symmetric(horizontal: _ui(context, 13), vertical: _ui(context, 9)), decoration: BoxDecoration(color: const Color(0xfff8fbff), borderRadius: BorderRadius.circular(999), border: Border.all(color: const Color(0xffdfe9f5))), child: Text(e, style: TextStyle(color: const Color(0xff42516a), fontSize: _font(context, 12), fontWeight: FontWeight.w900)))).toList(),
    );
  }

  Widget _uploadBox(BuildContext context, String text) {
    return Container(
      height: _ui(context, 78),
      decoration: BoxDecoration(color: const Color(0xfff8fbff), borderRadius: BorderRadius.circular(_ui(context, 16)), border: Border.all(color: const Color(0xffb9c9ff), style: BorderStyle.solid)),
      child: Center(child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.image_outlined, color: const Color(0xff5b53ff), size: _ui(context, 20)), SizedBox(width: _ui(context, 6)), Text(text, style: TextStyle(color: const Color(0xff5b53ff), fontSize: _font(context, 14), fontWeight: FontWeight.w900))])),
    );
  }

  Widget _notice(BuildContext context, IconData icon, String text) {
    return Container(
      padding: EdgeInsets.all(_ui(context, 12)),
      decoration: BoxDecoration(color: const Color(0xffeffdf7), borderRadius: BorderRadius.circular(_ui(context, 15)), border: Border.all(color: const Color(0xffbcf3de))),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(icon, color: const Color(0xff07966d), size: _ui(context, 20)), SizedBox(width: _ui(context, 8)), Expanded(child: Text(text, style: TextStyle(color: const Color(0xff067052), fontSize: _font(context, 12), fontWeight: FontWeight.w800, height: 1.35)))]),
    );
  }

  Widget _summaryLine(BuildContext context, String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: _ui(context, 10)),
      child: Row(children: [Expanded(child: Text(label, style: TextStyle(color: const Color(0xff617089), fontSize: _font(context, 13), fontWeight: FontWeight.w700))), Text(value, style: TextStyle(color: const Color(0xff10182b), fontSize: _font(context, 14), fontWeight: FontWeight.w900))]),
    );
  }

  Widget _outlineButton(BuildContext context, String text, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(height: _ui(context, 46), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(_ui(context, 14)), border: Border.all(color: const Color(0xffdbe7f4), width: 1.4)), child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(icon, color: const Color(0xffff2e86), size: _ui(context, 18)), SizedBox(width: _ui(context, 6)), Text(text, style: TextStyle(color: const Color(0xff10182b), fontSize: _font(context, 13), fontWeight: FontWeight.w900))])),
    );
  }

  Widget _gradientButton(BuildContext context, String text, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(height: _ui(context, 48), decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xffff9f0a), Color(0xffff2e86), Color(0xff7c3aed)]), borderRadius: BorderRadius.circular(_ui(context, 14))), child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(icon, color: Colors.white, size: _ui(context, 18)), SizedBox(width: _ui(context, 7)), Text(text, style: TextStyle(color: Colors.white, fontSize: _font(context, 15), fontWeight: FontWeight.w900))])),
    );
  }

  Widget _emptyState(BuildContext context, IconData icon, String title, String subtitle) {
    return Container(
      padding: EdgeInsets.all(_ui(context, 24)),
      child: Column(children: [Icon(icon, size: _ui(context, 42), color: const Color(0xff9caac0)), SizedBox(height: _ui(context, 8)), Text(title, style: TextStyle(fontSize: _font(context, 17), fontWeight: FontWeight.w900)), SizedBox(height: _ui(context, 4)), Text(subtitle, textAlign: TextAlign.center, style: TextStyle(color: const Color(0xff8391a8), fontSize: _font(context, 12), fontWeight: FontWeight.w700))]),
    );
  }

  Widget _bottomBar(BuildContext context) {
    final items = [
      [Icons.home_outlined, 'Home', true],
      [Icons.image_outlined, 'Vibes', false],
      [Icons.restaurant_outlined, 'Eats', false],
      [Icons.sensors, 'Live', false],
      [Icons.favorite_border, 'LinkUp', false],
    ];
    return Container(
      height: _ui(context, 64),
      padding: EdgeInsets.symmetric(horizontal: _ui(context, 8)),
      decoration: const BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Color(0x12000000), blurRadius: 18, offset: Offset(0, -5))]),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: items.map((item) {
          final selected = item[2] as bool;
          final label = item[1] as String;
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              if (label == 'Home') {
                Get.back();
              } else if (label == 'Vibes') {
                Get.to(() => const VibesPage());
              } else if (label == 'Eats') {
                Get.to(() => const EatsPage());
              } else if (label == 'Live') {
                Get.to(() => const LivePage());
              } else {
                Get.to(() => ChatHomePage());
              }
            },
            child: SizedBox(
              width: _ui(context, 70),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(width: _ui(context, 31), height: _ui(context, 31), decoration: BoxDecoration(color: selected ? const Color(0xff1985ff) : Colors.transparent, shape: BoxShape.circle), child: Icon(item[0] as IconData, color: selected ? Colors.white : const Color(0xff617089), size: _ui(context, 22))),
                  SizedBox(height: _ui(context, 2)),
                  Text(label, style: TextStyle(color: selected ? const Color(0xff1985ff) : const Color(0xff617089), fontSize: _font(context, 10), fontWeight: FontWeight.w900)),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  void _toast(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), behavior: SnackBarBehavior.floating, duration: const Duration(seconds: 2)));
  }
}

class _MarketProduct {
  final String title;
  final String seller;
  final String price;
  final String tag;
  final String image;
  final String category;
  final String location;
  final String description;

  const _MarketProduct({required this.title, required this.seller, required this.price, required this.tag, required this.image, required this.category, required this.location, required this.description});
}
