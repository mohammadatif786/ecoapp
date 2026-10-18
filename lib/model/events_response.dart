import 'package:link_up/model/linkup_event.dart';

class EventsResponse {
  final Map<String, List<LinkupEvent>> sections;

  const EventsResponse({required this.sections});

  factory EventsResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? {};
    final Map<String, List<LinkupEvent>> parsedSections = {};

    data.forEach((key, value) {
      if (value is List) {
        parsedSections[key] = value
            .map((item) => LinkupEvent.fromJson(Map<String, dynamic>.from(item)))
            .toList();
      }
    });

    return EventsResponse(sections: parsedSections);
  }

  static const empty = EventsResponse(sections: {});

  List<LinkupEvent> get allEvents => sections['events'] ?? [];
  List<LinkupEvent> get lowCost => sections['event_low_cost'] ?? [];
  List<LinkupEvent> get free => sections['free_events'] ?? [];

  List<LinkupEvent> get flattened {
    final seen = <int>{};
    final out = <LinkupEvent>[];
    const order = [
      'new_providence',
      'events',
      'event_low_cost',
      'jamaica_event',
      'free_events',
    ];
    for (final key in [...order, ...sections.keys.where((k) => !order.contains(k))]) {
      for (final event in sections[key] ?? const <LinkupEvent>[]) {
        if (seen.add(event.id)) out.add(event);
      }
    }
    return out;
  }

  EventsResponse withFavourite(int eventId, bool isFavourite) {
    final next = <String, List<LinkupEvent>>{};
    sections.forEach((key, list) {
      next[key] = list
          .map((event) => event.id == eventId
              ? event.copyWith(isFavourite: isFavourite)
              : event)
          .toList();
    });
    return EventsResponse(sections: next);
  }
}
