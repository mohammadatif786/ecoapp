import 'package:flutter/material.dart';
import 'package:link_up/ui/profile/profile_page.dart';
import 'package:link_up/widgets/linkup_location_sheet.dart';
import 'package:get/get.dart';
import 'package:link_up/get_controller/home_controller.dart';
import 'package:link_up/get_controller/news_controller.dart';
import 'package:link_up/model/news_model.dart';
import 'package:link_up/ui/wallet_page.dart';
import 'vibes_page.dart';
import 'eats_page.dart';
import 'live_page.dart';
import 'chat_home_page.dart';
import 'home_page.dart';
import 'package:link_up/ui/notification_page.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'package:link_up/ui/widgets/news_ad_video_player.dart';

class NewsPage extends StatefulWidget {
  const NewsPage({super.key});

  @override
  State<NewsPage> createState() => _NewsPageState();
}

class _NewsPageState extends State<NewsPage> {
  final HomeController homeController = Get.find(tag: HomeController().toString());
  final NewsController newsController = Get.find<NewsController>();

  @override
  void initState() {
    super.initState();
    newsController.fetchNews();
  }
  
  double _ui(BuildContext context, double value) {
    final width = MediaQuery.of(context).size.width;
    return value * (width / 430).clamp(0.86, 1.08).toDouble();
  }

  double _font(BuildContext context, double value) => _ui(context, value);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff0f7ff),
      body: SafeArea(
        child: Obx(() {
          if (newsController.isLoading.value &&
              newsController.allNews.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          final news = newsController.sortedNews;
          final featured = newsController.featuredNews;
          final ads = newsController.ads;
          
          return Column(
            children: [
              _topBar(context),
              _locationBar(context),
              Expanded(
                child: ListView(
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.symmetric(horizontal: _ui(context, 16)),
                  children: [
                    SizedBox(height: _ui(context, 8)),
                    _heroBanner(context),
                    SizedBox(height: _ui(context, 16)),
                    _searchBar(context),
                    SizedBox(height: _ui(context, 20)),
                    _categories(context),
                    SizedBox(height: _ui(context, 20)),
                    if (featured != null) ...[
                      _featuredStory(context, featured),
                      SizedBox(height: _ui(context, 20)),
                    ],
                    if (ads.isNotEmpty) ...[
                      _featuredAd(context, ads.first),
                      SizedBox(height: _ui(context, 20)),
                    ],
                    _topStoriesHeader(context),
                    SizedBox(height: _ui(context, 12)),
                    if (news.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 32),
                        child: Center(
                          child: Text(
                            'No news available',
                            style: TextStyle(
                              color: Colors.grey,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      )
                    else
                      _topStoriesGrid(context, news),
                    SizedBox(height: _ui(context, 30)),
                  ],
                ),
              ),
              _bottomBar(context),
            ],
          );
        }),
      ),
    );
  }

  Widget _topBar(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(_ui(context, 16), _ui(context, 8), _ui(context, 16), _ui(context, 8)),
      child: Row(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xff2d98e5),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text('ui', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
              ),
              const SizedBox(width: 4),
              const Text('Link Up', style: TextStyle(color: Color(0xff2d98e5), fontWeight: FontWeight.w900, fontSize: 20)),
            ],
          ),
          const Spacer(),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => Get.to(() => const WalletPage()),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xff2d98e5).withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  const Icon(Icons.link, color: Color(0xff2d98e5), size: 16),
                  const SizedBox(width: 4),
                  Text('${homeController.coins}', style: const TextStyle(color: Color(0xff2d98e5), fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          const LinkUpNotificationBell(
            iconColor: Color(0xff2d98e5),
            iconSize: 28,
            badgeSize: 16,
            badgeFontSize: 9,
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => ProfilePage())),
            child: const CircleAvatar(
              radius: 16,
              backgroundImage: AssetImage('assets/profile2.jpg'), // Placeholder
            ),
          ),
        ],
      ),
    );
  }

  Widget _locationBar(BuildContext context) {
    return const LinkupLocationBar(
      height: 34,
      horizontalPadding: 16,
      iconSize: 18,
      fontSize: 14,
      changeFontSize: 14,
      textColor: Color(0xff1e293b),
      changeColor: Color(0xff2d98e5),
      iconColor: Color(0xff2d98e5),
      fontWeight: FontWeight.w600,
    );
  }

  Widget _heroBanner(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(_ui(context, 16)),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xff0f172a), Color(0xff1e293b), Color(0xff334155)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: const Color(0xfffbbf24),
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: const Text('360', style: TextStyle(color: Color(0xff0f172a), fontWeight: FontWeight.w900, fontSize: 18)),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Caribbean 360', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 20)),
                Text('FRIDAY, JULY 5 - LIVE EDITION', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 10)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white10,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.tune_rounded, color: Colors.white, size: 20),
          ),
        ],
      ),
    );
  }

  Widget _searchBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: const TextField(
        decoration: InputDecoration(
          icon: Icon(Icons.search, color: Colors.grey),
          hintText: 'Search headlines, keywords...',
          hintStyle: TextStyle(color: Colors.grey, fontWeight: FontWeight.w500),
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget _categories(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _categoryItem(context, 'Caribbean + \nLatin America + \nGlobal', Icons.public, const Color(0xff2d98e5)),
          _categoryItem(context, '47\nSelected', Icons.bookmark_border, Colors.redAccent),
          _categoryItem(context, 'All\ncategories', Icons.auto_awesome, Colors.amber),
          _categoryItem(context, 'Country-\nfirst', Icons.waves, Colors.orange),
        ],
      ),
    );
  }

  Widget _categoryItem(BuildContext context, String title, IconData icon, Color color) {
    return Container(
      width: _ui(context, 90),
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 12),
          Text(title, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xff334155), height: 1.2)),
        ],
      ),
    );
  }

  Widget _featuredStory(BuildContext context, NewsItem story) {
    return Container(
      height: _ui(context, 240),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.network(
            story.imageUrl,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Container(
                color: Colors.black12,
                child: Center(
                  child: CircularProgressIndicator(
                    value: loadingProgress.expectedTotalBytes != null
                        ? loadingProgress.cumulativeBytesLoaded /
                            loadingProgress.expectedTotalBytes!
                        : null,
                    strokeWidth: 2,
                  ),
                ),
              );
            },
            errorBuilder: (_, __, ___) => Container(
              color: Colors.grey[300],
              child: const Icon(Icons.broken_image, color: Colors.grey),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Colors.black.withOpacity(0.8)],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Row(
                  children: [
                    _tag(story.category.toUpperCase(), Colors.pinkAccent),
                    const SizedBox(width: 8),
                    Row(
                      children: [
                        Text(story.countryCode == 'GLB' ? '🌎' : '📍',
                            style: const TextStyle(fontSize: 14)),
                        const SizedBox(width: 4),
                        Text(story.country,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const Spacer(),
                    Obx(() {
                      final isSaved = newsController.isSaved(story.id);
                      return GestureDetector(
                        onTap: () => newsController.toggleSave(story),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.3),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isSaved ? Icons.bookmark : Icons.bookmark_border,
                            color: isSaved ? Colors.yellow : Colors.white,
                            size: 20,
                          ),
                        ),
                      );
                    }),
                    if (story.isBreaking) ...[
                      const SizedBox(width: 8),
                      _tag('BREAKING', Colors.red),
                    ],
                    if (story.trending > 0) ...[
                      const SizedBox(width: 8),
                      _tag('TOP STORY', Colors.orange),
                    ],
                  ],
                ),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: () => _showNewsDetail(context, story),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        story.title,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        story.summary,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 12,
                            fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.access_time, color: Colors.white, size: 14),
                    const SizedBox(width: 4),
                    Text(
                        '${story.publishedAt.split('T')[0]} · ${story.trending} Feeds',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold)),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => _showNewsDetail(context, story),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          children: [
                            Text('Read Full Story',
                                style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w900)),
                            Icon(Icons.arrow_forward,
                                color: Colors.black, size: 12),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _tag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(20)),
      child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w900)),
    );
  }

  Widget _featuredAd(BuildContext context, NewsAd ad) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome, color: Color(int.parse(ad.brandColor.replaceAll('#', '0xff'))), size: 16),
              const SizedBox(width: 4),
              Text(ad.name, style: const TextStyle(color: Color(0xff334155), fontWeight: FontWeight.w900, fontSize: 14)),
              const Spacer(),
              const Text('Sponsored', style: TextStyle(color: Colors.redAccent, fontSize: 10, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 12),
          if (ad.adType == 'video' && ad.videoUrl != null) ...[
            NewsAdVideoPlayer(videoUrl: ad.videoUrl!, brandColor: ad.brandColor),
            const SizedBox(height: 12),
          ],
          Text(ad.headline, style: const TextStyle(color: Color(0xff1e293b), fontWeight: FontWeight.w900, fontSize: 16)),
          const SizedBox(height: 4),
          Text(ad.description, style: const TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.w500)),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () async {
              final uri = Uri.parse(ad.website);
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(int.parse(ad.brandColor.replaceAll('#', '0xff'))),
              minimumSize: const Size(double.infinity, 45),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            child: Text(ad.ctaText, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );
  }

  Widget _topStoriesHeader(BuildContext context) {
    final isNewest = newsController.sortMode.value == NewsSortMode.newest;
    return Row(
      children: [
        const Text('Top Stories for You', style: TextStyle(color: Color(0xff1e293b), fontWeight: FontWeight.w900, fontSize: 18)),
        const Spacer(),
        Container(
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
          child: Row(
            children: [
              GestureDetector(
                onTap: () => newsController.sortMode.value = NewsSortMode.newest,
                child: _tabButton('Newest', isNewest),
              ),
              GestureDetector(
                onTap: () => newsController.sortMode.value = NewsSortMode.trending,
                child: _tabButton('Trending', !isNewest),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _tabButton(String text, bool active) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: active ? const Color(0xff2d98e5) : Colors.transparent,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(text, style: TextStyle(color: active ? Colors.white : Colors.grey, fontWeight: FontWeight.bold, fontSize: 12)),
    );
  }

  Widget _topStoriesGrid(BuildContext context, List<NewsItem> news) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.76,
      ),
      itemCount: news.length,
      itemBuilder: (context, index) {
        final story = news[index];
        return _storyCard(context, story);
      },
    );
  }

  Widget _storyCard(BuildContext context, NewsItem story) {
    return GestureDetector(
      onTap: () => _showNewsDetail(context, story),
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    story.imageUrl,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        color: Colors.black12,
                        child: Center(
                          child: CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                    loadingProgress.expectedTotalBytes!
                                : null,
                            strokeWidth: 2,
                          ),
                        ),
                      );
                    },
                    errorBuilder: (_, __, ___) => Container(
                      color: Colors.grey[300],
                      child: const Icon(Icons.broken_image, color: Colors.grey),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: Stack(
                      children: [
                        Align(
                          alignment: Alignment.topLeft,
                          child: _tag(
                              story.category.toUpperCase(), Colors.pinkAccent),
                        ),
                        Align(
                          alignment: Alignment.topRight,
                          child: Obx(() {
                            final isSaved = newsController.isSaved(story.id);
                            return GestureDetector(
                              onTap: () => newsController.toggleSave(story),
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.3),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  isSaved ? Icons.bookmark : Icons.bookmark_border,
                                  color: isSaved ? Colors.yellow : Colors.white,
                                  size: 16,
                                ),
                              ),
                            );
                          }),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(story.title,
                      style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 12,
                          color: Color(0xff1e293b)),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Text(
                      '${story.countryCode == 'GLB' ? '🌎' : '📍'} ${story.country} · 1 min read',
                      style: const TextStyle(
                          fontSize: 8,
                          color: Colors.grey,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Spacer(),
                      const Icon(Icons.local_fire_department,
                          color: Colors.orange, size: 10),
                      Text(story.trending.toString(),
                          style: const TextStyle(
                              color: Colors.orange,
                              fontSize: 10,
                              fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _bottomBar(BuildContext context) {
    final items = [
      [Icons.home_outlined, 'Home', false],
      [Icons.image_outlined, 'Vibes', false],
      [Icons.restaurant_outlined, 'Eats', false],
      [Icons.sensors, 'Live', false],
      [Icons.favorite_border, 'LinkUp', false],
    ];

    return Container(
      height: _ui(context, 64) + MediaQuery.of(context).padding.bottom,
      padding: EdgeInsets.only(
        left: _ui(context, 12),
        right: _ui(context, 12),
        bottom: MediaQuery.of(context).padding.bottom,
      ),
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: items.map((item) {
          final selected = item[2] as bool;
          return Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(_ui(context, 18)),
              onTap: () {
                if (item[1] == 'Home') Get.off(() => HomePage());
                if (item[1] == 'Vibes') Get.to(() => const VibesPage());
                if (item[1] == 'Eats') Get.to(() => const EatsPage());
                if (item[1] == 'Live') Get.to(() => const LivePage());
                if (item[1] == 'LinkUp') Get.to(ChatHomePage());
              },
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: selected ? _ui(context, 30) : _ui(context, 26),
                    height: selected ? _ui(context, 30) : _ui(context, 26),
                    decoration: BoxDecoration(
                      color: selected
                          ? const Color(0xff2d98e5)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(_ui(context, 11)),
                    ),
                    child: Icon(
                      item[0] as IconData,
                      color: selected ? Colors.white : const Color(0xff69768a),
                      size: 24,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    item[1] as String,
                    maxLines: 1,
                    style: TextStyle(
                      color: selected
                          ? const Color(0xff2589df)
                          : const Color(0xff627085),
                      fontSize: 10,
                      fontWeight: selected ? FontWeight.w900 : FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  void _showNewsDetail(BuildContext context, NewsItem story) {
    newsController.loadNewsDetail(story);
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Close News',
      barrierColor: Colors.black.withOpacity(0.55),
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (dialogContext, animation, secondaryAnimation) {
        final size = MediaQuery.of(dialogContext).size;
        final ads = newsController.ads;

        return SafeArea(
          child: Center(
            child: Material(
              color: Colors.transparent,
              child: Container(
                width: size.width - 24,
                constraints: const BoxConstraints(maxWidth: 500),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                ),
                clipBehavior: Clip.antiAlias,
                child: Obx(() {
                  final current = newsController.detailStory.value ?? story;
                  final loading = newsController.isDetailLoading.value;
                  final publishedLabel = current.publishedAt.contains('T')
                      ? current.publishedAt.split('T').first
                      : current.publishedAt;
                  return Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          border: Border(
                              bottom: BorderSide(color: Color(0xfff1f5f9))),
                        ),
                        child: Row(
                          children: [
                            Text(current.countryCode == 'GLB' ? '🌎' : '📍',
                                style: const TextStyle(fontSize: 16)),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                '${current.country} · ${current.category}',
                                style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xff475569)),
                              ),
                            ),
                            GestureDetector(
                              onTap: () => Navigator.pop(dialogContext),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: const Color(0xfff1f5f9),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Row(
                                  children: [
                                    Icon(Icons.close, size: 14),
                                    SizedBox(width: 4),
                                    Text('Close',
                                        style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w900)),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (loading)
                        const LinearProgressIndicator(minHeight: 2),
                      Expanded(
                        child: SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (current.imageUrl.isNotEmpty)
                                Image.network(
                                  current.imageUrl,
                                  width: double.infinity,
                                  height: 220,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(
                                    height: 220,
                                    color: Colors.grey[300],
                                    child: const Icon(Icons.broken_image,
                                        color: Colors.grey),
                                  ),
                                )
                              else
                                Container(
                                  height: 220,
                                  color: Colors.grey[300],
                                  child: const Icon(Icons.broken_image,
                                      color: Colors.grey),
                                ),
                              Padding(
                                padding: const EdgeInsets.all(20),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      current.title,
                                      style: const TextStyle(
                                          fontSize: 22,
                                          fontWeight: FontWeight.w900,
                                          color: Color(0xff0f172a)),
                                    ),
                                    const SizedBox(height: 10),
                                    Row(
                                      children: [
                                        const Icon(Icons.access_time,
                                            size: 14, color: Color(0xff94a3b8)),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: Text(
                                            '$publishedLabel · ${current.sourceName}',
                                            style: const TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w700,
                                                color: Color(0xff94a3b8)),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      current.summary,
                                      style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xff475569),
                                          height: 1.5),
                                    ),
                                    const SizedBox(height: 20),
                                    if (ads.isNotEmpty) ...[
                                      _featuredAd(context, ads.first),
                                      const SizedBox(height: 20),
                                    ],
                                    Text(
                                      current.body,
                                      style: const TextStyle(
                                          fontSize: 15,
                                          color: Color(0xff475569),
                                          height: 1.6),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          border:
                              Border(top: BorderSide(color: Color(0xfff1f5f9))),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: _detailActionButton(
                                label: newsController.isSaved(current.id)
                                    ? 'Saved'
                                    : 'Save',
                                icon: newsController.isSaved(current.id)
                                    ? Icons.bookmark
                                    : Icons.bookmark_border,
                                iconColor: newsController.isSaved(current.id)
                                    ? Colors.redAccent
                                    : Colors.black,
                                onTap: () =>
                                    newsController.toggleSave(current),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _detailActionButton(
                                label: 'Share',
                                icon: Icons.ios_share,
                                onTap: () => Share.share(
                                    'Check out this news: ${current.title}\nhttps://linkupvibes.com/news/${current.id}'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                }),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _detailActionButton(
      {required String label,
      required IconData icon,
      required VoidCallback onTap,
      Color? iconColor}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xffe2e8f0)),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20, color: iconColor),
            const SizedBox(width: 8),
            Text(label,
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: Color(0xff0f172a))),
          ],
        ),
      ),
    );
  }
}
