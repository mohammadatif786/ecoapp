import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:link_up/model/event_booking_model.dart';
import 'package:link_up/model/event_detail_model.dart';
import 'package:link_up/model/events_response.dart';
import 'package:link_up/model/linkup_event.dart';
import 'package:link_up/services/linkup_api_service.dart';

class EventsController extends GetxController {
  var eventsResponse = EventsResponse.empty.obs;
  var isLoading = false.obs;
  
  var eventDetail = Rxn<EventDetailModel>();
  var isDetailLoading = false.obs;
  var togglingFavoriteIds = <int>{}.obs;
  var favouriteFlags = <int, bool>{}.obs;
  var favoriteEvents = <LinkupEvent>[].obs;
  var isFavoritesLoading = false.obs;
  var bookings = <EventBooking>[].obs;
  var canceledBookings = <EventBooking>[].obs;
  var isBookingsLoading = false.obs;
  var isTogglingOrganizerFollow = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetchEvents();
  }

  void _syncFavouriteFlags(EventsResponse response) {
    final flags = <int, bool>{};
    for (final list in response.sections.values) {
      for (final event in list) {
        flags[event.id] = (flags[event.id] ?? false) || event.isFavourite;
      }
    }
    favouriteFlags.assignAll(flags);
    if (kDebugMode) {
      final favourites = flags.entries.where((e) => e.value).map((e) => e.key).toList();
      debugPrint('[Events] favourite ids=$favourites');
    }
  }

  Future<void> fetchEvents() async {
    try {
      isLoading.value = true;
      final response = await LinkupApiService.fetchEvents();
      eventsResponse.value = response;
      _syncFavouriteFlags(response);
      if (kDebugMode) {
        final counts = response.sections.map((key, list) => MapEntry(key, list.length));
        debugPrint('[Events] loaded sections=$counts');
        for (final event in response.flattened.take(5)) {
          debugPrint(
            '[Events] id=${event.id} title=${event.title} slug=${event.slug} fav=${event.isFavourite} image=${event.imageUrl}',
          );
        }
      }
    } catch (e) {
      debugPrint('[Events] fetch list error: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchFavorites() async {
    try {
      isFavoritesLoading.value = true;
      final events = await LinkupApiService.fetchEventFavorites();
      favoriteEvents.assignAll(events);
      for (final event in events) {
        favouriteFlags[event.id] = true;
      }
      favouriteFlags.refresh();
      debugPrint('[Events] favorites tab count=${events.length}');
    } catch (e) {
      debugPrint('[Events] fetch favorites error: $e');
    } finally {
      isFavoritesLoading.value = false;
    }
  }

  Future<void> fetchBookings({bool canceled = false}) async {
    try {
      isBookingsLoading.value = true;
      if (canceled) {
        final items = await LinkupApiService.fetchEventBookings(
          status: 'cancelled',
        );
        canceledBookings.assignAll(items);
        debugPrint('[Events] cancelled bookings count=${items.length}');
      } else {
        final items = await LinkupApiService.fetchEventBookings();
        bookings.assignAll(items.where((item) => !item.isCanceled).toList());
        debugPrint('[Events] bookings tab count=${bookings.length}');
      }
    } catch (e) {
      debugPrint('[Events] fetch bookings error: $e');
    } finally {
      isBookingsLoading.value = false;
    }
  }

  Future<void> fetchEventDetail(String slug) async {
    try {
      isDetailLoading.value = true;
      eventDetail.value = null;
      debugPrint('[Events] open detail slug=$slug');
      final response = await LinkupApiService.fetchEventDetail(slug);
      eventDetail.value = response;
      if (kDebugMode) {
        final event = response.data.event;
        debugPrint(
          '[Events] detail ok id=${event.id} title=${event.title} tickets=${response.data.tickets.length} image=${event.imageUrl}',
        );
        for (final ticket in response.data.tickets.take(8)) {
          debugPrint(
            '[Events] ticket id=${ticket.id} name=${ticket.name} price=${ticket.price} qty=${ticket.qtyAvailable}',
          );
        }
      }
    } catch (e, st) {
      debugPrint('[Events] fetch detail error slug=$slug: $e');
      debugPrint('$st');
    } finally {
      isDetailLoading.value = false;
    }
  }

  bool favouriteOf(int eventId, {bool fallback = false}) {
    return favouriteFlags[eventId] ?? fallback;
  }

  Future<void> toggleFavorite(LinkupEvent event) async {
    if (event.id <= 0 || togglingFavoriteIds.contains(event.id)) return;
    final previous = favouriteOf(event.id, fallback: event.isFavourite);
    final optimistic = !previous;
    togglingFavoriteIds.add(event.id);
    togglingFavoriteIds.refresh();
    favouriteFlags[event.id] = optimistic;
    favouriteFlags.refresh();
    eventsResponse.value = eventsResponse.value.withFavourite(event.id, optimistic);
    _applyFavoriteToTab(event, optimistic);
    try {
      final next = await LinkupApiService.toggleEventFavorite(
        event.id,
        currentlyFavourite: previous,
      );
      favouriteFlags[event.id] = next;
      favouriteFlags.refresh();
      eventsResponse.value = eventsResponse.value.withFavourite(event.id, next);
      _applyFavoriteToTab(event, next);
      debugPrint('[Events] favorite id=${event.id} -> $next');
    } catch (e) {
      favouriteFlags[event.id] = previous;
      favouriteFlags.refresh();
      eventsResponse.value = eventsResponse.value.withFavourite(event.id, previous);
      _applyFavoriteToTab(event, previous);
      debugPrint('[Events] toggle favorite error id=${event.id}: $e');
    } finally {
      togglingFavoriteIds.remove(event.id);
      togglingFavoriteIds.refresh();
    }
  }

  Future<void> toggleOrganizerFollow() async {
    final current = eventDetail.value;
    if (current == null || isTogglingOrganizerFollow.value) return;

    final stats = current.data.organizerStats;
    var organizerId = stats.organizerId;
    if (organizerId <= 0) organizerId = current.data.event.organizerId;
    if (organizerId <= 0) return;

    final previousFollowing = stats.isFollowing;
    final previousCount = stats.followersCount;
    final optimisticFollowing = !previousFollowing;
    final optimisticCount = optimisticFollowing
        ? previousCount + 1
        : (previousCount > 0 ? previousCount - 1 : 0);

    isTogglingOrganizerFollow.value = true;
    _applyOrganizerFollow(optimisticFollowing, optimisticCount);
    try {
      // Same toggle-follow endpoint both follows and unfollows.
      final result = await LinkupApiService.toggleOrganizerFollow(
        organizerId,
        currentlyFollowing: previousFollowing,
      );
      _applyOrganizerFollow(
        result.isFollowing,
        result.followersCount ?? optimisticCount,
      );
      debugPrint(
        '[Events] organizer follow id=$organizerId -> ${result.isFollowing}',
      );
    } catch (e) {
      _applyOrganizerFollow(previousFollowing, previousCount);
      debugPrint('[Events] organizer follow error id=$organizerId: $e');
      Get.snackbar('Error', e.toString());
    } finally {
      isTogglingOrganizerFollow.value = false;
    }
  }

  void _applyOrganizerFollow(bool isFollowing, int followersCount) {
    final current = eventDetail.value;
    if (current == null) return;
    eventDetail.value = current.copyWith(
      data: current.data.copyWith(
        organizerStats: current.data.organizerStats.copyWith(
          isFollowing: isFollowing,
          followersCount: followersCount,
        ),
      ),
    );
  }

  void _applyFavoriteToTab(LinkupEvent event, bool isFavourite) {
    if (isFavourite) {
      if (!favoriteEvents.any((item) => item.id == event.id)) {
        favoriteEvents.insert(0, event.copyWith(isFavourite: true));
      }
    } else {
      favoriteEvents.removeWhere((item) => item.id == event.id);
    }
  }

  Future<void> submitReview(int eventId, int rating, String text, String reviewerName) async {
    try {
      await LinkupApiService.postEventReview(eventId,
          rating: rating, text: text, reviewerName: reviewerName);
      if (eventDetail.value != null) {
        fetchEventDetail(eventDetail.value!.data.event.slug);
      }
    } catch (e) {
      print('Error submitting review: $e');
      rethrow;
    }
  }

  Future<void> updateReview(
      int eventId, int reviewId, int rating, String text, String reviewerName) async {
    try {
      await LinkupApiService.updateEventReview(eventId, reviewId,
          rating: rating, text: text, reviewerName: reviewerName);
      if (eventDetail.value != null) {
        fetchEventDetail(eventDetail.value!.data.event.slug);
      }
    } catch (e) {
      print('Error updating review: $e');
      rethrow;
    }
  }

  Future<void> deleteReview(int eventId, int reviewId) async {
    try {
      await LinkupApiService.deleteEventReview(eventId, reviewId);
      if (eventDetail.value != null) {
        fetchEventDetail(eventDetail.value!.data.event.slug);
      }
    } catch (e) {
      print('Error deleting review: $e');
      rethrow;
    }
  }
}
