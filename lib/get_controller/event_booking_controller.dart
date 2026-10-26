import 'dart:math';

import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:link_up/model/event_detail_model.dart';
import 'package:link_up/services/linkup_api_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
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

  var ticketsResponse = Rxn<EventTicketsResponse>();

  EventFeeSettings? get feeSettings => ticketsResponse.value?.eventFeeSettings;

  void useDetailTickets(List<Ticket> items, {bool salesClosed = false}) {
    this.salesClosed.value = salesClosed;
    tickets.assignAll(items);
    isLoading.value = false;
  }

  Future<void> loadTickets(String slug,
      {String categoryName = '', String eventType = ''}) async {
    try {
      isLoading.value = true;
      final res = await LinkupApiService.fetchEventTicketsResponse(slug);
      ticketsResponse.value = res;
      tickets.assignAll(res.tickets);
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
    final ticket = tickets.firstWhereOrNull((t) => t.id == ticketId);
    if (ticket == null) return;
    int current = cart[ticketId] ?? 0;
    int next = current + delta;
    if (next < 0) next = 0;

    int maxQty = ticket.qtyAvailable > 0
        ? ticket.qtyAvailable
        : (ticket.quantity > 0 ? ticket.quantity : 99);
    if (next > maxQty) next = maxQty;

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

  // Wellness service quantities: Map<String, int> keyed "<ticketId>:<serviceName>"
  var wellnessServiceQuantities = <String, int>{}.obs;

  int getWellnessServiceQuantity(int ticketId, String serviceName) =>
      wellnessServiceQuantities['$ticketId:$serviceName'] ?? 0;

  void updateWellnessServiceQuantity(int ticketId, WellnessService service, int delta) {
    final key = '$ticketId:${service.name}';
    var next = (wellnessServiceQuantities[key] ?? 0) + delta;
    if (next < 0) next = 0;
    if (next == 0) {
      wellnessServiceQuantities.remove(key);
    } else {
      wellnessServiceQuantities[key] = next;
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
      if (cookout != null) {
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

        collect(cookout.drinks, 'CookoutDrink');
        collect(cookout.proteins, 'CookoutProtein');
      }

      final da = ticket.drinkAddons;
      if (da != null && da.items.isNotEmpty) {
        da.items.forEach((catKey, itemsList) {
          final isBottle = catKey.toLowerCase() == 'bottles' || catKey.toLowerCase() == 'bottle';
          final groupName = isBottle ? 'Bottle' : 'Drink';
          for (final item in itemsList) {
            final addonId = '${ticket.id}_${catKey}_${item.name}';
            final quantity = getAddonQuantity(ticket.id, addonId);
            if (quantity > 0) {
              lines.add(CookoutAddonLine(
                ticket: ticket,
                addon: CookoutAddon(
                  id: addonId,
                  name: item.name,
                  price: item.cost,
                  available: item.qty > 0 ? item.qty : 10,
                ),
                group: groupName,
                quantity: quantity,
              ));
            }
          }
        });
      }
      final wellness = ticket.wellness;
      if (wellness != null) {
        for (final s in wellness.services) {
          if (s.mode.toLowerCase() == 'addon' || (double.tryParse(s.price) ?? 0) > 0) {
            final quantity = getWellnessServiceQuantity(ticket.id, s.name);
            if (quantity > 0) {
              lines.add(CookoutAddonLine(
                ticket: ticket,
                addon: CookoutAddon(
                  id: 'wellness_${s.name}',
                  name: s.name,
                  price: double.tryParse(s.price) ?? 0,
                  available: 10,
                ),
                group: 'Wellness',
                quantity: quantity,
              ));
            }
          }
        }
      }
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
    return total.isNaN ? 0.0 : total;
  }

  bool get cartHasPackage {
    return cart.keys.any((id) {
      final t = tickets.firstWhereOrNull((element) => element.id == id);
      return t != null && t.hasViewablePackage;
    });
  }

  double get standardSubtotal {
    double total = 0;
    cart.forEach((id, qty) {
      final t = tickets.firstWhereOrNull((element) => element.id == id);
      if (t != null && !t.hasViewablePackage) {
        total += (double.tryParse(t.price) ?? 0) * qty;
      }
    });
    return total.isNaN ? 0.0 : total;
  }

  double get serviceFee {
    if (standardSubtotal <= 0) return 0.0;
    final fs = feeSettings;
    if (fs != null) {
      final val = (standardSubtotal * fs.serviceFeePct / 100.0) + fs.serviceFeeFixed;
      return val.isNaN ? 0.0 : val;
    }
    final defaultFee = ticketsResponse.value?.fee ?? 0.0;
    return defaultFee > 0 ? defaultFee : (standardSubtotal * 0.035 + 1.0);
  }

  double get processingFee {
    if (standardSubtotal <= 0) return 0.0;
    final fs = feeSettings;
    if (fs != null) {
      final val = (standardSubtotal * fs.processingFeePct / 100.0) + fs.processingFeeFixed;
      return val.isNaN ? 0.0 : val;
    }
    return (standardSubtotal * 0.029 + 0.30);
  }

  double get vipFee {
    final fs = feeSettings;
    if (fs == null) return 0.0;

    double vipSubtotal = 0.0;
    cart.forEach((id, qty) {
      final t = tickets.firstWhereOrNull((element) => element.id == id);
      if (t != null && t.hasViewablePackage) {
        vipSubtotal += (double.tryParse(t.price) ?? 0) * qty;
      }
    });

    final pct = fs.vipFeePct > 0 ? fs.vipFeePct : (fs.bottleFeePct > 0 ? fs.bottleFeePct : 12.0);
    return (vipSubtotal * pct / 100.0);
  }

  double get drinkSubtotal {
    double sub = 0.0;
    for (final line in addonLines) {
      if (line.group == 'Drink') {
        sub += line.lineTotal;
      }
    }
    return sub;
  }

  double get bottleSubtotal {
    double sub = 0.0;
    for (final line in addonLines) {
      if (line.group == 'Bottle') {
        sub += line.lineTotal;
      }
    }
    return sub;
  }

  double get drinkFee {
    final fs = feeSettings;
    if (fs == null || drinkSubtotal <= 0) return 0.0;
    final pct = fs.drinkFeePct > 0 ? fs.drinkFeePct : 6.0;
    return (drinkSubtotal * pct / 100.0);
  }

  double get bottleFee {
    final fs = feeSettings;
    if (fs == null || bottleSubtotal <= 0) return 0.0;
    final pct = fs.bottleFeePct > 0 ? fs.bottleFeePct : 7.0;
    return (bottleSubtotal * pct / 100.0);
  }

  double get totalFees {
    return serviceFee + processingFee + vipFee + drinkFee + bottleFee;
  }

  double get fees => totalFees;

  Map<String, dynamic> get taxConfig => ticketsResponse.value?.taxConfig ?? {};

  bool get taxFees {
    final tf = taxConfig['tax_fees'];
    if (tf is bool) return tf;
    if (tf is String) return tf.toLowerCase() == 'true' || tf == '1';
    if (tf is num) return tf != 0;
    return false;
  }

  double get taxRate => 10.0;

  double get tax {
    final taxBase = subtotal + totalFees;
    final val = taxBase * (taxRate / 100.0);
    return val.isNaN ? 0.0 : val;
  }

  double get addonsTotal {
    double total = 0;
    for (final line in addonLines) {
      total += line.lineTotal;
    }
    return total.isNaN ? 0.0 : total;
  }

  double get total {
    final val = subtotal + addonsTotal + totalFees + tax;
    return val.isNaN ? 0.0 : val;
  }

  int get ticketCount =>
      cart.values.fold<int>(0, (sum, quantity) => sum + quantity);

  String? validateCartForCheckout() {
    for (final ticketId in cart.keys) {
      final ticket = tickets.firstWhereOrNull((t) => t.id == ticketId);
      final qty = cart[ticketId] ?? 0;
      if (ticket == null || qty <= 0) continue;

      // Cookout Validation
      if (ticket.cookout != null) {
        final plate = plateNameFor(ticket);
        if (ticket.cookout!.plates.isNotEmpty && (plate == null || plate.isEmpty)) {
          return 'Please select an included cookout plate for ${ticket.name}';
        }
      }

      // Wellness Validation
      if (ticket.wellness != null) {
        final slot = selectedSlots[ticket.id];
        if (ticket.wellness!.booking != null && slot == null) {
          return 'Please select a wellness appointment time slot for ${ticket.name}';
        }
      }
    }
    return null;
  }

  /// True when any ticket in the cart is booked as a call-out, which is what
  /// unlocks therapist tracking on the success sheet.
  bool get hasMobileService => cart.keys
      .any((ticketId) => locationModes[ticketId] == 'Mobile');

  Future<void> payWithWallet(dynamic eventId) async {
    try {
      isLoading.value = true;
      final items = <Map<String, dynamic>>[];
      cart.forEach((ticketId, qty) {
        final ticket = tickets.firstWhereOrNull((t) => t.id == ticketId);
        final ticketAddonIds = addonLines
            .where((l) => l.ticket.id == ticketId)
            .map((l) => int.tryParse(l.addon.id))
            .whereType<int>()
            .toList();

        final ticketAddons = addonLines
            .where((l) => l.ticket.id == ticketId)
            .map((l) => {
                  'ticketId': ticketId,
                  'ticket_id': ticketId,
                  if (int.tryParse(l.addon.id) != null) ...{
                    'addon_id': int.tryParse(l.addon.id)!,
                    'id': int.tryParse(l.addon.id)!,
                  },
                  'name': l.addon.name,
                  'qty': l.quantity,
                  'quantity': l.quantity,
                  'price': l.lineTotal,
                })
            .toList();

        items.add({
          'ticketId': ticketId,
          'ticket_id': ticketId,
          'id': ticketId,
          'qty': qty,
          'quantity': qty,
          if (ticketAddonIds.isNotEmpty) 'addons': ticketAddonIds,
          'detailed_addons': ticketAddons,
          'has_package': ticket?.hasViewablePackage ?? false,
          'drink_package_id': ticket?.drinkPackage?.id,
        });
      });

      final res = await LinkupApiService.buyTicketsWallet(
        eventId,
        items: items,
        subtotal: subtotal,
        standardSubtotal: standardSubtotal,
        serviceFee: serviceFee,
        processingFee: processingFee,
        vipFee: vipFee,
        drinkFee: drinkFee,
        bottleFee: bottleFee,
        tax: tax,
        total: total,
      );

      if (res['status'] == true) {
        paymentMethod.value = 'Wallet';
        issuedTicketCode.value = res['data']?['order_id']?.toString() ?? _generateTicketCode();
        currentStep.value = BookingStep.success;
      } else {
        Get.snackbar('Checkout Failed', res['message']?.toString() ?? 'Insufficient wallet balance or error.',
            backgroundColor: Colors.red, colorText: Colors.white);
      }
    } catch (e) {
      print('Error in payWithWallet: $e');
      Get.snackbar('Error', 'An unexpected error occurred during wallet checkout: $e');
    } finally {
      isLoading.value = false;
    }
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

  Future<void> buyWithStripe(dynamic eventId) async {
    try {
      isLoading.value = true;
      final items = <Map<String, dynamic>>[];
      cart.forEach((ticketId, qty) {
        final ticket = tickets.firstWhereOrNull((t) => t.id == ticketId);
        final ticketAddonIds = addonLines
            .where((l) => l.ticket.id == ticketId)
            .map((l) => int.tryParse(l.addon.id))
            .whereType<int>()
            .toList();

        final ticketAddons = addonLines
            .where((l) => l.ticket.id == ticketId)
            .map((l) => {
                  'ticketId': ticketId,
                  'ticket_id': ticketId,
                  if (int.tryParse(l.addon.id) != null) ...{
                    'addon_id': int.tryParse(l.addon.id)!,
                    'id': int.tryParse(l.addon.id)!,
                  },
                  'name': l.addon.name,
                  'qty': l.quantity,
                  'quantity': l.quantity,
                  'price': l.lineTotal,
                })
            .toList();

        items.add({
          'ticketId': ticketId,
          'ticket_id': ticketId,
          'id': ticketId,
          'qty': qty,
          'quantity': qty,
          if (ticketAddonIds.isNotEmpty) 'addons': ticketAddonIds,
          'detailed_addons': ticketAddons,
          'has_package': ticket?.hasViewablePackage ?? false,
          'drink_package_id': ticket?.drinkPackage?.id,
        });
      });

      final res = await LinkupApiService.buyTicketsStripeInit(
        eventId,
        items: items,
        subtotal: subtotal,
        standardSubtotal: standardSubtotal,
        serviceFee: serviceFee,
        processingFee: processingFee,
        vipFee: vipFee,
        drinkFee: drinkFee,
        bottleFee: bottleFee,
        tax: tax,
        total: total,
      );

      if (res['status'] == true && res['data'] != null) {
        final keys = res['data'];
        final checkoutUrl = keys['checkout_url']?.toString();

        if (checkoutUrl != null && checkoutUrl.isNotEmpty) {
          final uri = Uri.parse(checkoutUrl);
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
            return;
          }
        }

        final clientSecret = keys['client_secret']?.toString();
        final customerId = keys['customer_id']?.toString();
        final ephemeralKey = keys['ephemeralKey']?.toString();
        final cartToken = keys['cart_token']?.toString();
        final paymentIntentId = keys['payment_intent_id']?.toString();

        if (clientSecret != null && cartToken != null && paymentIntentId != null) {
          final pubKey = keys['publishableKey']?.toString();
          if (pubKey != null && pubKey.isNotEmpty) {
            Stripe.publishableKey = pubKey;
            await Stripe.instance.applySettings();
          }

          await Stripe.instance.initPaymentSheet(
            paymentSheetParameters: SetupPaymentSheetParameters(
              paymentIntentClientSecret: clientSecret,
              customerId: customerId,
              customerEphemeralKeySecret: ephemeralKey,
              merchantDisplayName: 'Link Up Tickets',
            ),
          );

          await Stripe.instance.presentPaymentSheet();

          final confirmRes = await LinkupApiService.buyTicketsStripeConfirm(
            cartToken: cartToken,
            paymentIntentId: paymentIntentId,
          );

          if (confirmRes['status'] == true) {
            paymentMethod.value = 'Card';
            issuedTicketCode.value = confirmRes['data']?['order_id']?.toString() ?? paymentIntentId;
            currentStep.value = BookingStep.success;
          } else {
            Get.snackbar('Payment Error', confirmRes['message']?.toString()?.toString() ?? 'Failed to confirm ticket purchase.',
                backgroundColor: Colors.red, colorText: Colors.white);
          }
        } else {
          Get.snackbar('Error', 'Invalid payment keys received from server.');
        }
      } else {
        Get.snackbar('Error', res['message']?.toString() ?? 'Failed to initialize payment sheet.');
      }
    } on StripeException catch (e) {
      Get.snackbar('Payment Cancelled', 'Payment cancelled: ${e.error.localizedMessage}',
          backgroundColor: Colors.orange, colorText: Colors.white);
    } catch (e) {
      print('Error in buyWithStripe: $e');
      Get.snackbar('Error', 'An unexpected error occurred during card checkout: $e');
    } finally {
      isLoading.value = false;
    }
  }
}
