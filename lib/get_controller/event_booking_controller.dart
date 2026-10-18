import 'dart:math';

import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:link_up/model/event_detail_model.dart';
import 'package:link_up/services/linkup_api_service.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:link_up/get_controller/ChatController.dart';

enum BookingStep { selection, summary, success }

/// One paid extra in the cart, resolved back to the ticket that carries it.
class CookoutAddonLine {
  final Ticket ticket;
  final CookoutAddon addon;
  final String group;
  final int quantity;

  const CookoutAddonLine({
    required this.ticket,
    required this.addon,
    required this.group,
    required this.quantity,
  });

  double get lineTotal => addon.price * quantity;
}

class EventBookingController extends GetxController {
  /// Where the map centres before the buyer drops a pin (The Valley, Anguilla).
  static const double fallbackLatitude = 18.2200;
  static const double fallbackLongitude = -63.0600;

  var currentStep = BookingStep.selection.obs;
  
  var isLoading = false.obs;
  var tickets = <Ticket>[].obs;

  // Cart state: Map<TicketID, Quantity>
  var cart = <int, int>{}.obs;
  
  // Selected slot per ticket: Map<TicketID, Slot>
  var selectedSlots = <int, Slot>{}.obs;
  
  // Location mode per ticket: Map<TicketID, String> (in-house vs mobile)
  var locationModes = <int, String>{}.obs;

  // Chosen included plate per ticket: Map<TicketID, plate id>
  var selectedPlates = <int, String>{}.obs;

  // Paid extras, keyed "<ticketId>:<addonId>" so two tickets can hold their
  // own counts of the same drink.
  var addonQuantities = <String, int>{}.obs;

  // Tickets whose drinks-only panel has been opened via "Add Drinks".
  var expandedDrinkPanels = <int>{}.obs;
  
  // Address for mobile service
  var addressController = TextEditingController();
  var address = "".obs;

  // Pin the therapist navigates to when the buyer picks "Mobile (to me)".
  var pinLatitude = fallbackLatitude.obs;
  var pinLongitude = fallbackLongitude.obs;
  var hasDroppedPin = false.obs;
  var isLocating = false.obs;

  // Populated when checkout completes, so the success sheet stops guessing.
  var paymentMethod = 'Card'.obs;
  var issuedTicketCode = ''.obs;
  var salesClosed = false.obs;

  void useDetailTickets(List<Ticket> items, {bool salesClosed = false}) {
    this.salesClosed.value = salesClosed;
    tickets.assignAll(items);
    isLoading.value = false;
  }

  Future<void> loadTickets(String slug,
      {String categoryName = '', String eventType = ''}) async {
    try {
      isLoading.value = true;
      final res = await LinkupApiService.fetchEventTickets(slug);
      tickets.assignAll(res);
    } catch (e) {
      print('Error loading tickets: $e');
      tickets.clear();
    } finally {
      isLoading.value = false;
    }
  }

  @override
  void onClose() {
    addressController.dispose();
    super.onClose();
  }

  void reset() {
    currentStep.value = BookingStep.selection;
    cart.clear();
    selectedSlots.clear();
    locationModes.clear();
    selectedPlates.clear();
    addonQuantities.clear();
    expandedDrinkPanels.clear();
    address.value = "";
    addressController.clear();
    pinLatitude.value = fallbackLatitude;
    pinLongitude.value = fallbackLongitude;
    hasDroppedPin.value = false;
    issuedTicketCode.value = '';
    salesClosed.value = false;
  }

  void setPin(double latitude, double longitude) {
    pinLatitude.value = latitude;
    pinLongitude.value = longitude;
    hasDroppedPin.value = true;
  }

  /// Centres the pin on the device and back-fills the address field from it.
  Future<void> useMyLocation() async {
    if (isLocating.value) return;
    try {
      isLocating.value = true;

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        Get.snackbar('Location needed',
            'Allow location access so your therapist can navigate to you.');
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: LocationSettings(accuracy: LocationAccuracy.best),
      );
      setPin(position.latitude, position.longitude);

      // A missing street name should not discard a perfectly good pin.
      try {
        final places = await placemarkFromCoordinates(
            position.latitude, position.longitude);
        if (places.isNotEmpty) {
          final line = _formatPlacemark(places.first);
          if (line.isNotEmpty) {
            address.value = line;
            addressController.text = line;
          }
        }
      } catch (_) {}
    } catch (e) {
      Get.snackbar('Location unavailable', 'Could not read your position.');
    } finally {
      isLocating.value = false;
    }
  }

  String _formatPlacemark(Placemark place) {
    final parts = <String?>[
      place.street,
      place.locality,
      place.administrativeArea,
      place.country,
    ];
    return parts
        .where((p) => p != null && p.trim().isNotEmpty)
        .map((p) => p!.trim())
        .toSet()
        .join(', ');
  }

  void updateQuantity(int ticketId, int delta) {
    final ticket = tickets.firstWhere((t) => t.id == ticketId);
    if (delta > 0 && (salesClosed.value || !ticket.isPurchasable)) return;
    int current = cart[ticketId] ?? 0;
    int next = current + delta;
    if (next < 0) next = 0;
    if (next > ticket.qtyAvailable) next = ticket.qtyAvailable;
    
    if (next == 0) {
      cart.remove(ticketId);
    } else {
      cart[ticketId] = next;
    }
  }

  int getQuantity(int ticketId) => cart[ticketId] ?? 0;

  void selectSlot(int ticketId, Slot slot) {
    selectedSlots[ticketId] = slot;
  }

  String addonKey(int ticketId, String addonId) => '$ticketId:$addonId';

  int getAddonQuantity(int ticketId, String addonId) =>
      addonQuantities[addonKey(ticketId, addonId)] ?? 0;

  void updateAddonQuantity(int ticketId, CookoutAddon addon, int delta) {
    final key = addonKey(ticketId, addon.id);
    var next = (addonQuantities[key] ?? 0) + delta;
    if (next < 0) next = 0;
    if (next > addon.available) next = addon.available;
    if (next == 0) {
      addonQuantities.remove(key);
    } else {
      addonQuantities[key] = next;
    }
  }

  void selectPlate(int ticketId, String plateId) {
    selectedPlates[ticketId] = plateId;
  }

  /// Defaults to the first plate so a cookout line is never left unqualified.
  String? plateNameFor(Ticket ticket) {
    final plates = ticket.cookout?.plates ?? const <CookoutOption>[];
    if (plates.isEmpty) return null;
    final chosen = selectedPlates[ticket.id];
    for (final plate in plates) {
      if (plate.id == chosen) return plate.name;
    }
    return plates.first.name;
  }

  void toggleDrinkPanel(int ticketId) {
    if (expandedDrinkPanels.contains(ticketId)) {
      expandedDrinkPanels.remove(ticketId);
    } else {
      expandedDrinkPanels.add(ticketId);
    }
  }

  /// Every paid extra currently in the cart, flattened for the order summary.
  List<CookoutAddonLine> get addonLines {
    final lines = <CookoutAddonLine>[];
    for (final ticket in tickets) {
      if (!cart.containsKey(ticket.id)) continue;
      final cookout = ticket.cookout;
      if (cookout == null) continue;

      void collect(List<CookoutAddon> addons, String group) {
        for (final addon in addons) {
          final quantity = getAddonQuantity(ticket.id, addon.id);
          if (quantity > 0) {
            lines.add(CookoutAddonLine(
                ticket: ticket,
                addon: addon,
                group: group,
                quantity: quantity));
          }
        }
      }

      collect(cookout.drinks, 'Drink');
      collect(cookout.proteins, 'Protein');
    }
    return lines;
  }

  void setLocationMode(int ticketId, String mode) {
    locationModes[ticketId] = mode;
  }

  double get subtotal {
    double total = 0;
    cart.forEach((id, qty) {
      final t = tickets.firstWhereOrNull((element) => element.id == id);
      if (t != null) {
        total += (double.tryParse(t.price) ?? 0) * qty;
      }
    });
    for (final line in addonLines) {
      total += line.lineTotal;
    }
    return total.isNaN ? 0.0 : total;
  }

  double get fees {
    final val = subtotal * 0.084; // Matching screenshot 8.4% approx
    return val.isNaN ? 0.0 : val;
  }

  double get tax {
    final val = subtotal * 0.1084; // Matching screenshot approx
    return val.isNaN ? 0.0 : val;
  }

  double get total {
    final val = subtotal + fees + tax;
    return val.isNaN ? 0.0 : val;
  }

  int get ticketCount =>
      cart.values.fold<int>(0, (sum, quantity) => sum + quantity);

  /// True when any ticket in the cart is booked as a call-out, which is what
  /// unlocks therapist tracking on the success sheet.
  bool get hasMobileService => cart.keys
      .any((ticketId) => locationModes[ticketId] == 'Mobile');

  void payWithWallet() {
    paymentMethod.value = 'Wallet';
    issuedTicketCode.value = _generateTicketCode();
    currentStep.value = BookingStep.success;
  }

  void payWithScotiabank() {
    paymentMethod.value = 'Bank';
    issuedTicketCode.value = _generateTicketCode();
    currentStep.value = BookingStep.success;
  }

  Future<void> sendTicketToUser(Map<String, dynamic> user, EventDetail event) async {
    try {
      final chatController = Get.find<ChatController>(tag: ChatController().toString());
      final receiverId = user['laravel_id'] ?? user['chat_id'] ?? user['uid'] ?? user['id']?.toString();

      if (receiverId == null) {
        Get.snackbar('Error', 'User ID not found for sharing.');
        return;
      }

      final message = '🎟️ Ticket for ${event.title}\n'
          'Code: ${issuedTicketCode.value}\n'
          'Location: ${event.venue ?? event.city}\n'
          'Date: ${event.startTime ?? "Upcoming"}';

      await chatController.sendMessage(receiverId, message);

      Get.snackbar(
        'Ticket Sent',
        'Ticket shared with ${user['first_name'] ?? "user"}.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xff238df2),
        colorText: Colors.white,
      );
    } catch (e) {
      print('Error sending ticket: $e');
      Get.snackbar('Error', 'Failed to send ticket via chat.');
    }
  }

  String _generateTicketCode() {
    const alphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    final code = List.generate(
        5, (_) => alphabet[random.nextInt(alphabet.length)]).join();
    return 'TKT-$code';
  }

  Future<void> buyWithStripe(int eventId) async {
    try {
      isLoading.value = true;
      final items = <Map<String, dynamic>>[];
      cart.forEach((ticketId, qty) {
        items.add({
          'id': ticketId,
          'quantity': qty,
        });
      });

      final checkoutUrl = await LinkupApiService.buyTicketsStripe(eventId, tickets: items);
      if (checkoutUrl != null) {
        final uri = Uri.parse(checkoutUrl);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        } else {
          Get.snackbar('Error', 'Could not launch payment page.');
        }
      } else {
        Get.snackbar('Error', 'Failed to create checkout session.');
      }
    } catch (e) {
      print('Error in buyWithStripe: $e');
      Get.snackbar('Error', 'An unexpected error occurred during checkout.');
    } finally {
      isLoading.value = false;
    }
  }
}
