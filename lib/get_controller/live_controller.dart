import 'package:get/get.dart';
import 'package:link_up/model/live_stream_model.dart';
import 'package:link_up/services/linkup_api_service.dart';

class LiveController extends GetxController {
  var streams = <LiveStream>[].obs;
  var categories = <String>['All'].obs;
  var selectedCategory = 'All'.obs;

  var isLoading = false.obs;
  var isCategoriesLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetchCategories();
    fetchStreams();
  }

  Future<void> fetchCategories() async {
    try {
      isCategoriesLoading.value = true;
      final res = await LinkupApiService.fetchLiveCategories();
      categories.assignAll(['All', ...res]);
    } catch (e) {
      print('Error fetching live categories: $e');
    } finally {
      isCategoriesLoading.value = false;
    }
  }

  Future<void> fetchStreams({String? category}) async {
    try {
      isLoading.value = true;
      final response = await LinkupApiService.fetchLiveStreams(category: category ?? selectedCategory.value);
      streams.assignAll(response.streams);

      // If categories are empty (other than 'All'), update them from the streams response if available
      if (categories.length <= 1 && response.categories.isNotEmpty) {
        categories.assignAll(['All', ...response.categories]);
      }
    } catch (e) {
      print('Error fetching live streams: $e');
    } finally {
      isLoading.value = false;
    }
  }

  void changeCategory(String category) {
    if (selectedCategory.value == category) return;
    selectedCategory.value = category;
    fetchStreams(category: category);
  }
}
