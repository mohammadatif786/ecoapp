import 'package:link_up/mappers/api_user_mapper.dart';

class EventBookingEvent {
  final int id;
  final String title;
  final String venue;
  final String city;
  final String country;
  final String imageUrl;
  final String description;
  final DateTime? startTime;
  final DateTime? endTime;
  final String currencySymbol;

  const EventBookingEvent({
    required this.id,
    required this.title,
    required this.venue,
    required this.city,
    required this.country,
    required this.imageUrl,
    required this.description,
    required this.startTime,
    required this.endTime,
    required this.currencySymbol,
  });

  String get location {
    final parts = <String>[];
    if (venue.trim().isNotEmpty) parts.add(venue.trim());
    if (city.trim().isNotEmpty) parts.add(city.trim());
    if (country.trim().isNotEmpty) parts.add(country.trim());
    return parts.join(', ');
  }

  factory EventBookingEvent.fromJson(Map<String, dynamic> json) {
    return EventBookingEvent(
      id: _asInt(json['id']),
      title: (json['title'] ?? '').toString().trim(),
      venue: (json['venue'] ?? '').toString().trim(),
      city: (json['city'] ?? '').toString().trim(),
      country: (json['country'] ?? '').toString().trim(),
      imageUrl: ApiUserMapper.resolveEventImage(json),
      description: (json['description'] ?? json['about'] ?? '').toString().trim(),
      startTime: DateTime.tryParse((json['start_time'] ?? '').toString())
          ?.toLocal(),
      endTime: DateTime.tryParse((json['end_time'] ?? '').toString())?.toLocal(),
      currencySymbol: (json['currency_symbol'] ?? '\$').toString().trim().isEmpty
          ? '\$'
          : (json['currency_symbol'] ?? '\$').toString().trim(),
    );
  }
}

class EventBookingTicket {
  final int id;
  final int eventId;
  final String ticketNumber;
  final String ticketName;
  final String ticketType;
  final int quantity;
  final double paid;
  final double subTotal;
  final double total;
  final double fee;
  final double tax;
  final double drinksTotal;
  final double tablesTotal;
  final double wellnessTotal;
  final double cookoutTotal;
  final List<dynamic> drinkAddons;
  final List<dynamic> tableAddons;
  final List<dynamic> wellnessAddons;
  final List<dynamic> cookoutAddons;
  final String ticketStatus;
  final bool checkin;
  final List<dynamic> checkinDetails;
  final bool canCancel;
  final dynamic event;

  const EventBookingTicket({
    required this.id,
    required this.eventId,
    required this.ticketNumber,
    required this.ticketName,
    required this.ticketType,
    required this.quantity,
    required this.paid,
    required this.subTotal,
    required this.total,
    required this.fee,
    required this.tax,
    required this.drinksTotal,
    required this.tablesTotal,
    required this.wellnessTotal,
    required this.cookoutTotal,
    required this.drinkAddons,
    required this.tableAddons,
    required this.wellnessAddons,
    required this.cookoutAddons,
    required this.ticketStatus,
    required this.checkin,
    required this.checkinDetails,
    required this.canCancel,
    required this.event,
  });

  factory EventBookingTicket.fromJson(Map<String, dynamic> json) {
    final chk = _asBool(json['checkin']);
    final stat = (json['ticket_status'] ?? 'confirmed').toString();
    final canceled = stat.toLowerCase().contains('cancel');
    final canC = json['can_cancel'] ?? (!chk && !canceled);

    return EventBookingTicket(
      id: _asInt(json['id']),
      eventId: _asInt(json['event_id']),
      ticketNumber: (json['ticket_qrcode'] ?? json['qr'] ?? '').toString(),
      ticketName: (json['ticket_name'] ?? 'Ticket').toString(),
      ticketType: (json['ticket_type'] ?? 'General').toString(),
      quantity: _asInt(json['quantity'] ?? 1),
      paid: _asDouble(json['paid']),
      subTotal: _asDouble(json['sub_total']),
      total: _asDouble(json['total']),
      fee: _asDouble(json['fee']),
      tax: _asDouble(json['tax']),
      drinksTotal: _asDouble(json['drinks_total']),
      tablesTotal: _asDouble(json['tables_total']),
      wellnessTotal: _asDouble(json['wellness_total']),
      cookoutTotal: _asDouble(json['cookout_total']),
      drinkAddons: json['drink_addons'] is List ? json['drink_addons'] as List : const [],
      tableAddons: json['table_addons'] is List ? json['table_addons'] as List : const [],
      wellnessAddons: json['wellness_addons'] is List ? json['wellness_addons'] as List : const [],
      cookoutAddons: json['cookout_addons'] is List ? json['cookout_addons'] as List : const [],
      ticketStatus: stat,
      checkin: chk,
      checkinDetails: json['checkin_details'] is List ? json['checkin_details'] as List : const [],
      canCancel: canC is bool ? canC : _asBool(canC),
      event: json['event'] ?? {},
    );
  }
}

class EventBooking {
  final int id;
  final int eventId;
  final String qr;
  final String ticketQrcode;
  final String date;
  final int quantity;
  final int noOfTickets;
  final double paid;
  final double subTotal;
  final double total;
  final double fee;
  final double tax;
  final double drinksTotal;
  final double tablesTotal;
  final double wellnessTotal;
  final double cookoutTotal;
  final List<dynamic> drinkAddons;
  final List<dynamic> tableAddons;
  final List<dynamic> wellnessAddons;
  final List<dynamic> cookoutAddons;
  final String ticketStatus;
  final bool checkin;
  final List<dynamic> checkinDetails;
  final bool canCancel;
  final String ticketName;
  final String ticketType;
  final EventBookingEvent event;

  const EventBooking({
    required this.id,
    required this.eventId,
    required this.qr,
    required this.ticketQrcode,
    required this.date,
    required this.quantity,
    required this.noOfTickets,
    required this.paid,
    this.subTotal = 0,
    this.total = 0,
    this.fee = 0,
    this.tax = 0,
    this.drinksTotal = 0,
    this.tablesTotal = 0,
    this.wellnessTotal = 0,
    this.cookoutTotal = 0,
    this.drinkAddons = const [],
    this.tableAddons = const [],
    this.wellnessAddons = const [],
    this.cookoutAddons = const [],
    required this.ticketStatus,
    required this.checkin,
    this.checkinDetails = const [],
    this.canCancel = true,
    required this.ticketName,
    required this.ticketType,
    required this.event,
  });

  String get qrToken {
    if (ticketQrcode.trim().isNotEmpty) return ticketQrcode.trim();
    return qr.trim();
  }

  int get ticketCount => noOfTickets > 0 ? noOfTickets : (quantity > 0 ? quantity : 1);

  bool get isCanceled {
    final status = ticketStatus.toLowerCase();
    return status.contains('cancel');
  }

  String get statusLabel {
    if (isCanceled) return 'Canceled';
    if (checkin) return 'Checked in';
    final status = ticketStatus.trim();
    if (status.isEmpty) return 'Confirmed';
    return '${status[0].toUpperCase()}${status.substring(1).toLowerCase()}';
  }

  String get paidLabel {
    return '${event.currencySymbol}${paid.toStringAsFixed(2)}';
  }

  String get eventDateLabel {
    final start = event.startTime;
    if (start != null) {
      const months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];
      return '${months[start.month - 1]} ${start.day}, ${start.year}';
    }
    return date;
  }

  factory EventBooking.fromJson(Map<String, dynamic> json) {
    final eventRaw = json['event'];
    final chk = _asBool(json['checkin']);
    final stat = (json['ticket_status'] ?? '').toString().trim();
    final canceled = stat.toLowerCase().contains('cancel');
    final canC = json['can_cancel'] ?? (!chk && !canceled);

    return EventBooking(
      id: _asInt(json['id']),
      eventId: _asInt(json['event_id']),
      qr: (json['qr'] ?? '').toString().trim(),
      ticketQrcode: (json['ticket_qrcode'] ?? json['qr'] ?? '').toString().trim(),
      date: (json['date'] ?? '').toString().trim(),
      quantity: _asInt(json['quantity']),
      noOfTickets: _asInt(json['no_of_tickets'] ?? json['quantity']),
      paid: _asDouble(json['paid']),
      subTotal: _asDouble(json['sub_total']),
      total: _asDouble(json['total']),
      fee: _asDouble(json['fee']),
      tax: _asDouble(json['tax']),
      drinksTotal: _asDouble(json['drinks_total']),
      tablesTotal: _asDouble(json['tables_total']),
      wellnessTotal: _asDouble(json['wellness_total']),
      cookoutTotal: _asDouble(json['cookout_total']),
      drinkAddons: json['drink_addons'] is List ? json['drink_addons'] as List : const [],
      tableAddons: json['table_addons'] is List ? json['table_addons'] as List : const [],
      wellnessAddons: json['wellness_addons'] is List ? json['wellness_addons'] as List : const [],
      cookoutAddons: json['cookout_addons'] is List ? json['cookout_addons'] as List : const [],
      ticketStatus: stat,
      checkin: chk,
      checkinDetails: json['checkin_details'] is List ? json['checkin_details'] as List : const [],
      canCancel: canC is bool ? canC : _asBool(canC),
      ticketName: (json['ticket_name'] ?? '').toString().trim(),
      ticketType: (json['ticket_type'] ?? '').toString().trim(),
      event: eventRaw is Map
          ? EventBookingEvent.fromJson(Map<String, dynamic>.from(eventRaw))
          : const EventBookingEvent(
              id: 0,
              title: '',
              venue: '',
              city: '',
              country: '',
              imageUrl: '',
              description: '',
              startTime: null,
              endTime: null,
              currencySymbol: '\$',
            ),
    );
  }
}

class EventBookingGroup {
  final int eventId;
  final EventBookingEvent event;
  final List<EventBooking> purchases;

  const EventBookingGroup({
    required this.eventId,
    required this.event,
    required this.purchases,
  });

  int get purchaseCount => purchases.length;

  int get ticketCount {
    var total = 0;
    for (final item in purchases) {
      total += item.ticketCount;
    }
    return total;
  }

  double get totalPaid {
    var total = 0.0;
    for (final item in purchases) {
      total += item.paid;
    }
    return total;
  }

  EventBooking get latest => purchases.first;

  String get paidLabel =>
      '${event.currencySymbol}${totalPaid.toStringAsFixed(2)}';

  String get ticketsBadge {
    final count = ticketCount;
    return '$count Ticket${count == 1 ? '' : 's'}';
  }

  String get subtitle {
    if (event.description.isNotEmpty) return event.description;
    if (latest.ticketName.isNotEmpty) return latest.ticketName;
    if (event.location.isNotEmpty) return event.location;
    return latest.ticketType;
  }
}

List<EventBookingGroup> groupEventBookings(List<EventBooking> items) {
  final order = <int>[];
  final grouped = <int, List<EventBooking>>{};
  for (final item in items) {
    final key = item.eventId > 0 ? item.eventId : item.event.id;
    if (!grouped.containsKey(key)) {
      order.add(key);
      grouped[key] = <EventBooking>[];
    }
    grouped[key]!.add(item);
  }
  return order.map((id) {
    final purchases = grouped[id]!;
    purchases.sort((a, b) => b.id.compareTo(a.id));
    return EventBookingGroup(
      eventId: id,
      event: purchases.first.event,
      purchases: purchases,
    );
  }).toList();
}

int _asInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

double _asDouble(dynamic value) {
  if (value is double) return value;
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0;
}

bool _asBool(dynamic value) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  final text = value?.toString().toLowerCase().trim();
  return text == 'true' || text == '1' || text == 'yes';
}
