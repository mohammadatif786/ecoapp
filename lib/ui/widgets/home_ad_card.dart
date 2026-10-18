import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:link_up/element/full_screen_image.dart';
import 'package:link_up/model/home_advertisement.dart';
import 'package:url_launcher/url_launcher.dart';

class HomeAdCard extends StatelessWidget {
  final HomeAdvertisement ad;

  const HomeAdCard({super.key, required this.ad});

  Color get _brandColor {
    final hex = ad.brandColor.replaceAll('#', '');
    if (hex.length == 6) {
      final value = int.tryParse(hex, radix: 16);
      if (value != null) return Color(0xFF000000 | value);
    }
    return const Color.fromARGB(255, 56, 171, 216);
  }

  Future<void> _openAd() async {
    final target = ad.website.isNotEmpty
        ? ad.website
        : (ad.isVideo && ad.videoUrl.isNotEmpty ? ad.videoUrl : '');
    if (target.isEmpty) return;
    final uri = Uri.tryParse(
      target.startsWith('http') ? target : 'https://$target',
    );
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final imageUrl = ad.displayImageUrl;

    return Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (imageUrl.isNotEmpty)
            GestureDetector(
              onTap: () => Get.to(() => FullScreenImage(
                    imageURL: imageUrl,
                    tag: 'ad_${ad.id}',
                  )),
              child: Image.network(
                imageUrl,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    color: _brandColor.withOpacity(0.1),
                    child: Center(
                      child: CircularProgressIndicator(
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                                loadingProgress.expectedTotalBytes!
                            : null,
                        color: _brandColor,
                        strokeWidth: 2,
                      ),
                    ),
                  );
                },
                errorBuilder: (_, __, ___) => Container(
                  color: _brandColor.withOpacity(0.15),
                  child: Icon(Icons.campaign_outlined,
                      size: 64, color: _brandColor),
                ),
              ),
            )
          else
            Container(
              color: _brandColor.withValues(alpha: 0.12),
              child: Icon(Icons.campaign_outlined, size: 64, color: _brandColor),
            ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.15),
                  Colors.black.withValues(alpha: 0.75),
                ],
              ),
            ),
          ),
          if (ad.isVideo || ad.isAudio)
            Center(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.45),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  ad.isVideo ? Icons.play_arrow_rounded : Icons.volume_up_rounded,
                  color: Colors.white,
                  size: 42,
                ),
              ),
            ),
          Positioned(
            top: 12,
            right: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: _brandColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                ad.adType == 'image' ? 'AD' : '${ad.adType.toUpperCase()} AD',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 11,
                  letterSpacing: 0.6,
                ),
              ),
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (ad.headline.isNotEmpty)
                  Text(
                    ad.headline,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      height: 1.2,
                    ),
                  ),
                if (ad.description.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    ad.description,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 13,
                      height: 1.35,
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: _openAd,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: _brandColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      ad.ctaText,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Swipe right to open • Tap ${ad.ctaText}',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.65),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
