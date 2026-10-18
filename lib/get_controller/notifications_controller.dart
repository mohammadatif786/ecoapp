import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:link_up/model/notification_model.dart';
import 'package:link_up/services/linkup_api_service.dart';

class NotificationFilter {
  final String type;
  final String label;

  const NotificationFilter(this.type, this.label);
}

class NotificationsController extends GetxController {
  static const filters = <NotificationFilter>[
    NotificationFilter('all', 'All'),
    NotificationFilter('unread', 'Unread'),
    NotificationFilter('messages', 'Messages'),
    NotificationFilter('matches', 'Matches'),
    NotificationFilter('payments', 'Payments'),
    NotificationFilter('marketplace-orders', 'Orders'),
    NotificationFilter('eats', 'Eats'),
    NotificationFilter('events', 'Events'),
    NotificationFilter('gifts', 'Gifts'),
    NotificationFilter('requests', 'Requests'),
    NotificationFilter('system', 'System'),
    NotificationFilter('priority', 'Priority'),
  ];

  final items = <LinkUpNotificationItem>[].obs;
  final isLoading = false.obs;
  final error = RxnString();
  final selectedType = 'all'.obs;
  final unreadTotal = 0.obs;

  @override
  void onInit() {
    super.onInit();
    fetchNotifications();
  }

  int get unreadCount => unreadTotal.value;

  String get selectedLabel {
    for (final filter in filters) {
      if (filter.type == selectedType.value) return filter.label;
    }
    return 'All';
  }

  Future<void> selectType(String type) async {
    if (selectedType.value == type && items.isNotEmpty) {
      await fetchNotifications(type: type);
      return;
    }
    selectedType.value = type;
    await fetchNotifications(type: type);
  }

  Future<void> fetchNotifications({String? type}) async {
    final requestType = (type ?? selectedType.value).trim();
    try {
      isLoading.value = true;
      error.value = null;
      items.clear();
      final result = await LinkupApiService.fetchAllNotifications(
        type: requestType.isEmpty ? 'all' : requestType,
      );
      items.assignAll(result.notifications);
      if (result.unreadCount != null) {
        unreadTotal.value = result.unreadCount!;
      } else if (requestType == 'all') {
        unreadTotal.value = items.where((item) => item.unread).length;
      } else if (requestType == 'unread') {
        unreadTotal.value = items.length;
      }
    } catch (e) {
      error.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> markAllRead() async {
    if (unreadTotal.value <= 0 && !items.any((item) => item.unread)) {
      return;
    }
    for (final item in items) {
      item.unread = false;
    }
    items.refresh();
    unreadTotal.value = 0;
    if (selectedType.value == 'unread') {
      items.clear();
    }
    try {
      await LinkupApiService.markAllNotificationsRead();
    } catch (e) {
      debugPrint('[Notifications] mark-all-read failed: $e');
      error.value = e.toString();
      await fetchNotifications();
    }
  }

  void markRead(int id) {
    for (final item in items) {
      if (item.id != id || !item.unread) continue;
      item.unread = false;
      items.refresh();
      if (unreadTotal.value > 0) unreadTotal.value--;
      return;
    }
  }
}
