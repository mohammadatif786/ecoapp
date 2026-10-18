import 'package:get/get.dart';
import 'package:link_up/model/news_model.dart';
import 'package:link_up/services/linkup_api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum NewsSortMode { newest, trending }

class NewsController extends GetxController {
  var newsResponse = Rxn<NewsResponse>();
  var isLoading = false.obs;
  var sortMode = NewsSortMode.trending.obs;

  var detailStory = Rxn<NewsItem>();
  var isDetailLoading = false.obs;

  // Track saved news IDs
  var savedNewsIds = <int>{}.obs;
  static const _savedKey = 'linkup_saved_news';

  @override
  void onInit() {
    super.onInit();
    _loadSavedNews();
    fetchNews();
  }

  Future<void> _loadSavedNews() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_savedKey) ?? [];
    savedNewsIds.assignAll(list.map((e) => int.tryParse(e)).whereType<int>());
  }

  Future<void> _persistSavedNews() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_savedKey, savedNewsIds.map((e) => e.toString()).toList());
  }

  bool isSaved(int id) => savedNewsIds.contains(id);

  Future<void> toggleSave(NewsItem item) async {
    if (isSaved(item.id)) {
      savedNewsIds.remove(item.id);
    } else {
      savedNewsIds.add(item.id);
      try {
        await LinkupApiService.hitNewsTrending(item.id);
      } catch (e) {
        print('Error hitting trending API: $e');
      }
    }
    await _persistSavedNews();
  }

  Future<void> fetchNews() async {
    try {
      isLoading.value = true;
      final response = await LinkupApiService.fetchNews();
      newsResponse.value = response;
    } catch (e) {
      print('Error fetching news: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadNewsDetail(NewsItem preview) async {
    detailStory.value = preview;
    isDetailLoading.value = true;
    try {
      final fresh = await LinkupApiService.fetchNewsDetail(preview.id);
      detailStory.value = fresh;
    } catch (e) {
      print('Error fetching news detail: $e');
    } finally {
      isDetailLoading.value = false;
    }
  }

  List<NewsItem> get allNews => newsResponse.value?.data.news ?? [];
  List<NewsAd> get ads => newsResponse.value?.data.ads ?? [];

  List<NewsItem> get sortedNews {
    final list = List<NewsItem>.from(allNews);
    if (sortMode.value == NewsSortMode.trending) {
      list.sort((a, b) {
        final byTrending = a.trending.compareTo(b.trending);
        if (byTrending != 0) return byTrending;
        return b.publishedDate.compareTo(a.publishedDate);
      });
    } else {
      list.sort((a, b) => b.publishedDate.compareTo(a.publishedDate));
    }
    return list;
  }

  NewsItem? get featuredNews {
    final news = List<NewsItem>.from(allNews);
    if (news.isEmpty) return null;
    news.sort((a, b) {
      final byTrending = a.trending.compareTo(b.trending);
      if (byTrending != 0) return byTrending;
      return b.publishedDate.compareTo(a.publishedDate);
    });
    return news.first;
  }
}
