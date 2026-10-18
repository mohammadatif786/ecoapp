import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:link_up/model/nightlife_model.dart';
import 'package:link_up/services/linkup_api_service.dart';

class NightlifeController extends GetxController {
  final clubs = <NightlifePlace>[].obs;
  final restaurants = <NightlifePlace>[].obs;
  final isLoading = false.obs;
  final error = RxnString();
  final selectedTab = 0.obs;
  final searchQuery = ''.obs;
  final detail = Rxn<NightlifePlaceDetail>();
  final isDetailLoading = false.obs;
  final detailError = RxnString();
  NightlifeLocation? location;

  @override
  void onInit() {
    super.onInit();
    fetchNightlife();
  }

  List<NightlifePlace> get visiblePlaces {
    final source = selectedTab.value == 0 ? clubs : restaurants;
    final query = searchQuery.value.trim().toLowerCase();
    if (query.isEmpty) return source.toList();
    return source
        .where((place) =>
            place.name.toLowerCase().contains(query) ||
            place.address.toLowerCase().contains(query))
        .toList();
  }

  Future<void> fetchNightlife() async {
    try {
      isLoading.value = true;
      error.value = null;
      final result = await LinkupApiService.fetchNightlife();
      clubs.assignAll(result.clubs);
      restaurants.assignAll(result.restaurants);
      location = result.location;
    } catch (e) {
      error.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchDetail({
    required String kind,
    required String placeId,
  }) async {
    try {
      isDetailLoading.value = true;
      detailError.value = null;
      detail.value = await LinkupApiService.fetchNightlifeDetail(
        kind: kind,
        placeId: placeId,
      );
    } catch (e) {
      debugPrint('[Nightlife] detail error=$e');
      detailError.value = e.toString();
    } finally {
      isDetailLoading.value = false;
    }
  }
}
