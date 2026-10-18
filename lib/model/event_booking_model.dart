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

class EventBooking {
  final int id;
  final int eventId;
  final String qr;
  final String ticketQrcode;
  final String date;
  final int quantity;
  final int noOfTickets;
  final double paid;
  final String ticketStatus;
  final bool checkin;
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
    required this.ticketStatus,
    required this.checkin,
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
    return EventBooking(
      id: _asInt(json['id']),
      eventId: _asInt(json['event_id']),
      qr: (json['qr'] ?? '').toString().trim(),
      ticketQrcode: (json['ticket_qrcode'] ?? json['qr'] ?? '').toString().trim(),
      date: (json['date'] ?? '').toString().trim(),
      quantity: _asInt(json['quantity']),
      noOfTickets: _asInt(json['no_of_tickets'] ?? json['quantity']),
      paid: _asDouble(json['paid']),
      ticketStatus: (json['ticket_status'] ?? '').toString().trim(),
      checkin: _asBool(json['checkin']),
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
