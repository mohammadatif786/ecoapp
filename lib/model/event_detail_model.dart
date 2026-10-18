import 'package:link_up/mappers/api_user_mapper.dart';
import 'package:link_up/model/linkup_event.dart';

class EventDetailModel {
  final bool status;
  final EventData data;

  EventDetailModel({required this.status, required this.data});

  factory EventDetailModel.fromJson(Map<String, dynamic> json) {
    return EventDetailModel(
      status: json['status'] == true || json['status'] == 1,
      data: EventData.fromJson(
        json['data'] is Map ? Map<String, dynamic>.from(json['data']) : <String, dynamic>{},
      ),
    );
  }

  EventDetailModel copyWith({EventData? data}) {
    return EventDetailModel(
      status: status,
      data: data ?? this.data,
    );
  }
}

class EventData {
  final EventDetail event;
  final List<Ticket> tickets;
  final List<LinkupEvent> otherEvents;
  final List<Sponsor> sponsors;
  final OrganizerStats organizerStats;
  final List<Attendee> attendees;
  final bool showMap;
  final String currency;
  final bool isWellnessEvent;
  final bool isCookoutEvent;

  EventData({
    required this.event,
    required this.tickets,
    required this.otherEvents,
    required this.sponsors,
    required this.organizerStats,
    required this.attendees,
    required this.showMap,
    this.currency = '',
    this.isWellnessEvent = false,
    this.isCookoutEvent = false,
  });

  factory EventData.fromJson(Map<String, dynamic> json) {
    final nestedEvent = json['event'];
    final eventJson = nestedEvent is Map
        ? Map<String, dynamic>.from(nestedEvent)
        : (json['title'] != null || json['slug'] != null)
            ? json
            : <String, dynamic>{};

    return EventData(
      event: EventDetail.fromJson(eventJson),
      tickets: _parseTickets(
        json['tickets'] ?? (nestedEvent is Map ? nestedEvent['tickets'] : null),
      ),
      otherEvents: (json['other_events'] as List? ?? [])
          .map((item) => LinkupEvent.fromJson(Map<String, dynamic>.from(item)))
          .toList(),
      sponsors: (json['sponsor'] as List? ?? json['sponsors'] as List? ?? [])
          .map((item) => Sponsor.fromJson(Map<String, dynamic>.from(item)))
          .toList(),
      organizerStats: OrganizerStats.fromJson(
        json['organizer_stats'] is Map
            ? Map<String, dynamic>.from(json['organizer_stats'])
            : <String, dynamic>{},
      ),
      attendees: (json['attendees'] as List? ?? [])
          .map((item) => Attendee.fromJson(Map<String, dynamic>.from(item)))
          .toList(),
      showMap: json['show_map'] == true || json['show_map'] == 1,
      currency: ApiUserMapper.asString(json['currency']),
      isWellnessEvent: json['is_wellness_event'] == true || json['is_wellness_event'] == 1,
      isCookoutEvent: json['is_cookout_event'] == true || json['is_cookout_event'] == 1,
    );
  }

  EventData copyWith({OrganizerStats? organizerStats}) {
    return EventData(
      event: event,
      tickets: tickets,
      otherEvents: otherEvents,
      sponsors: sponsors,
      organizerStats: organizerStats ?? this.organizerStats,
      attendees: attendees,
      showMap: showMap,
      currency: currency,
      isWellnessEvent: isWellnessEvent,
      isCookoutEvent: isCookoutEvent,
    );
  }
}

class EventDetail {
  final int id;
  final String title;
  final String slug;
  final String description;
  final String disclaimer;
  final String type;
  final String status;
  final String? venue;
  final String city;
  final String state;
  final String country;
  final double? latitude;
  final double? longitude;
  final String website;
  final String phone;
  final String email;
  final String? startTime;
  final String? endTime;
  final String imageUrl;
  final int organizerId;
  final String? organizerName;
  final String? organizerImageUrl;
  final bool isFree;
  final int likesCount;
  final double averageRating;
  final int reviewsCount;
  final String categoryName;
  final bool isFavourite;
  final int favouritesCount;
  final EventSpecificDetails eventDetails;
  final List<Review> reviews;

  EventDetail({
    required this.id,
    required this.title,
    required this.slug,
    required this.description,
    required this.disclaimer,
    required this.type,
    required this.status,
    this.venue,
    required this.city,
    required this.state,
    required this.country,
    this.latitude,
    this.longitude,
    required this.website,
    required this.phone,
    required this.email,
    this.startTime,
    this.endTime,
    required this.imageUrl,
    required this.organizerId,
    this.organizerName,
    this.organizerImageUrl,
    required this.isFree,
    required this.likesCount,
    required this.averageRating,
    required this.reviewsCount,
    required this.categoryName,
    required this.isFavourite,
    required this.favouritesCount,
    required this.eventDetails,
    required this.reviews,
  });

  factory EventDetail.fromJson(Map<String, dynamic> json) {
    final detailsRaw = json['event_details'];
    final details = EventSpecificDetails.fromJson(
      detailsRaw is Map ? Map<String, dynamic>.from(detailsRaw) : <String, dynamic>{},
    );
    var imageUrl = ApiUserMapper.resolveEventImage(json);
    if (imageUrl.isEmpty && details.imageGallery.isNotEmpty) {
      imageUrl = details.imageGallery.first;
    }

    return EventDetail(
      id: json['id'] is int
          ? json['id'] as int
          : int.tryParse(json['id']?.toString() ?? '') ?? 0,
      title: ApiUserMapper.asString(json['title']),
      slug: ApiUserMapper.asString(json['slug']),
      description: ApiUserMapper.asString(json['description']),
      disclaimer: ApiUserMapper.asString(json['disclaimer']),
      type: ApiUserMapper.asString(json['type']),
      status: ApiUserMapper.asString(json['status']),
      venue: ApiUserMapper.asNullableString(json['venue']),
      city: ApiUserMapper.asString(json['city']),
      state: ApiUserMapper.asString(json['state']),
      country: ApiUserMapper.asString(json['country']),
      latitude: json['latitude'] is num
          ? (json['latitude'] as num).toDouble()
          : double.tryParse(json['latitude']?.toString() ?? ''),
      longitude: json['longitude'] is num
          ? (json['longitude'] as num).toDouble()
          : double.tryParse(json['longitude']?.toString() ?? ''),
      website: ApiUserMapper.asString(json['website']),
      phone: ApiUserMapper.asString(json['phone']),
      email: ApiUserMapper.asString(json['email']),
      startTime: ApiUserMapper.asNullableString(json['start_time']),
      endTime: ApiUserMapper.asNullableString(json['end_time']),
      imageUrl: imageUrl,
      organizerId: json['organizer_id'] is int
          ? json['organizer_id'] as int
          : int.tryParse(json['organizer_id']?.toString() ?? '') ?? 0,
      organizerName: ApiUserMapper.asNullableString(json['organizer_name']),
      organizerImageUrl: ApiUserMapper.extractMediaUrl(
        json['organizer_image_url'] ?? json['organizer_avatar'],
      ),
      isFree: json['is_free'] == true || json['is_free'] == 1,
      likesCount: json['likes_count'] is int
          ? json['likes_count'] as int
          : int.tryParse(json['likes_count']?.toString() ?? '') ?? 0,
      averageRating: json['average_rating'] is num
          ? (json['average_rating'] as num).toDouble()
          : double.tryParse(json['average_rating']?.toString() ?? '') ?? 0.0,
      reviewsCount: json['reviews_count'] is int
          ? json['reviews_count'] as int
          : int.tryParse(json['reviews_count']?.toString() ?? '') ?? 0,
      categoryName: ApiUserMapper.asString(json['category_name']),
      isFavourite: ApiUserMapper.parseBool(
        json['is_favourite'] ?? json['is_favorite'],
        fallback: false,
      ),
      favouritesCount: json['favourites_count'] is int
          ? json['favourites_count'] as int
          : int.tryParse(json['favourites_count']?.toString() ?? '') ?? 0,
      eventDetails: details,
      reviews: (json['reviews'] as List? ?? [])
          .map((item) => Review.fromJson(Map<String, dynamic>.from(item)))
          .toList(),
    );
  }

  bool get ticketsNoLongerAvailable => eventDetails.isNoLongerAvailable;
}

class EventSpecificDetails {
  final String eventType;
  final String? singleEventDate;
  final String? singleStartTime;
  final String? singleEndTime;
  final String? recurrPattern;
  final String? recurrStartDate;
  final String? recurrEndDate;
  final bool seatingPlan;
  final bool enableViews;
  final List<dynamic> imageGallery;
  final String? artists;
  final String? twitter;
  final String? instagram;
  final String? facebook;
  final String? tiktok;
  final String? linkedin;
  final String? ageRequirement;
  final String? dressCode;

  EventSpecificDetails({
    required this.eventType,
    this.singleEventDate,
    this.singleStartTime,
    this.singleEndTime,
    this.recurrPattern,
    this.recurrStartDate,
    this.recurrEndDate,
    required this.seatingPlan,
    required this.enableViews,
    required this.imageGallery,
    this.artists,
    this.twitter,
    this.instagram,
    this.facebook,
    this.tiktok,
    this.linkedin,
    this.ageRequirement,
    this.dressCode,
  });

  factory EventSpecificDetails.fromJson(Map<String, dynamic> json) {
    return EventSpecificDetails(
      eventType: ApiUserMapper.asString(json['event_type']),
      singleEventDate: ApiUserMapper.asNullableString(json['single_event_date']),
      singleStartTime: ApiUserMapper.asNullableString(json['single_start_time']),
      singleEndTime: ApiUserMapper.asNullableString(json['single_end_time']),
      recurrPattern: ApiUserMapper.asNullableString(json['recurr_pattern']),
      recurrStartDate: ApiUserMapper.asNullableString(json['recurr_start_date']),
      recurrEndDate: ApiUserMapper.asNullableString(json['recurr_end_date']),
      seatingPlan: json['seating_plan'] == true || json['seating_plan'] == 1,
      enableViews: json['enable_views'] == true || json['enable_views'] == 1,
      imageGallery: ApiUserMapper.extractMediaUrls(
        json['image_gallery'] ?? json['images'] ?? json['gallery'],
      ),
      artists: ApiUserMapper.asNullableString(json['artists']),
      twitter: ApiUserMapper.asNullableString(json['twitter']),
      instagram: ApiUserMapper.asNullableString(json['instagram']),
      facebook: ApiUserMapper.asNullableString(json['facebook']),
      tiktok: ApiUserMapper.asNullableString(json['tiktok']),
      linkedin: ApiUserMapper.asNullableString(json['linkedin']),
      ageRequirement: ApiUserMapper.asNullableString(json['age_requirement']),
      dressCode: ApiUserMapper.asNullableString(json['dress_code']),
    );
  }

  bool get isRecurring {
    final type = eventType.trim().toLowerCase();
    return type == 'recurring' || type == 'recurr' || type.contains('recur');
  }

  bool get isSingle {
    final type = eventType.trim().toLowerCase();
    return type == 'single' || type == 'onetime' || type == 'one-time' || type == 'one_time';
  }

  /// True when the event window has ended, so tickets should not be sold.
  bool get isNoLongerAvailable {
    final now = DateTime.now();
    if (isRecurring) {
      final end = _parseEventDateTime(recurrEndDate, endOfDay: true);
      if (end == null) return false;
      return now.isAfter(end);
    }
    if (isSingle) {
      final end = _parseEventDateTime(singleEndTime, endOfDay: false);
      if (end == null) return false;
      return now.isAfter(end);
    }
    return false;
  }
}

class Ticket {
  final int id;
  final String name;
  final String type;
  final String description;
  final String price;
  final String promoPrice;
  final bool isFree;
  final bool hasTable;
  final String tablePrice;
  final int tableCapacity;
  final int quantity;
  final int qtyAvailable;
  final String? salesStart;
  final String? salesEnd;
  final String status;
  final Cookout? cookout;
  final Wellness? wellness;
  final List<WellnessSlotBlock> wellnessSlotBlocks;

  /// Lines shown by the "View Package" button on bundle tickets.
  final List<String> packageItems;

  Ticket({
    required this.id,
    required this.name,
    required this.type,
    required this.description,
    required this.price,
    required this.promoPrice,
    required this.isFree,
    required this.hasTable,
    required this.tablePrice,
    required this.tableCapacity,
    required this.quantity,
    required this.qtyAvailable,
    this.salesStart,
    this.salesEnd,
    required this.status,
    this.cookout,
    this.wellness,
    required this.wellnessSlotBlocks,
    this.packageItems = const [],
  });

  bool get salesHaveEnded {
    final end = DateTime.tryParse(salesEnd ?? '');
    if (end == null) return false;
    return DateTime.now().isAfter(end.toLocal());
  }

  bool get isPurchasable {
    if (qtyAvailable <= 0) return false;
    if (salesHaveEnded) return false;
    final statusText = status.trim().toLowerCase();
    if (statusText == 'inactive' ||
        statusText == 'ended' ||
        statusText.contains('cancel')) {
      return false;
    }
    return true;
  }

  factory Ticket.fromJson(Map<String, dynamic> json) {
    String rawName = json['name']?.toString() ?? '';
    if (rawName.isEmpty || rawName.toLowerCase() == 'null' || rawName.toLowerCase() == 'undefined') {
      rawName = 'General Admission'; // Fallback for tickets in screenshots
    }

    return Ticket(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '') ?? 0,
      name: rawName,
      type: json['type']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      price: json['price']?.toString() ?? '0.00',
      promoPrice: json['promo_price']?.toString() ?? '0.00',
      isFree: json['is_free'] == true || json['is_free'] == 1 || json['is_free']?.toString() == 'true',
      hasTable: json['has_table'] == true || json['has_table'] == 1 || json['has_table']?.toString() == 'true',
      tablePrice: json['table_price']?.toString() ?? '0.00',
      tableCapacity: json['table_capacity'] is int ? json['table_capacity'] : int.tryParse(json['table_capacity']?.toString() ?? '') ?? 0,
      quantity: json['quantity'] is int ? json['quantity'] : int.tryParse(json['quantity']?.toString() ?? '') ?? 0,
      qtyAvailable: json['qty_available'] is int ? json['qty_available'] : int.tryParse(json['qty_available']?.toString() ?? '') ?? 0,
      salesStart: json['sales_start']?.toString(),
      salesEnd: json['sales_end']?.toString(),
      status: json['status']?.toString() ?? '',
      cookout: json['cookout'] is Map
          ? Cookout.fromJson(Map<String, dynamic>.from(json['cookout'] as Map))
          : null,
      wellness: json['wellness'] is Map
          ? Wellness.fromJson(Map<String, dynamic>.from(json['wellness'] as Map))
          : null,
      wellnessSlotBlocks: (json['wellness_slot_blocks'] as List? ?? [])
          .whereType<Map>()
          .map((item) => WellnessSlotBlock.fromJson(Map<String, dynamic>.from(item)))
          .toList(),
      packageItems: (json['package_items'] as List? ?? json['package'] as List? ?? [])
          .map((item) => item.toString())
          .toList(),
    );
  }
}

/// Plate / add-on data behind the "Cookout Plate Order" panel.
///
/// The upstream payload is not fixed yet, so every key is read leniently and a
/// missing section simply hides that part of the panel.
class Cookout {
  final String title;
  final String note;
  final List<CookoutOption> plates;
  final List<String> includedSides;
  final List<CookoutAddon> drinks;
  final List<CookoutAddon> proteins;

  const Cookout({
    this.title = 'Cookout Plate Order',
    this.note = 'Base includes one plate. Add-ons update totals automatically.',
    this.plates = const [],
    this.includedSides = const [],
    this.drinks = const [],
    this.proteins = const [],
  });

  /// A ticket that only carries drinks shows an "Add Drinks" button rather
  /// than the full plate panel.
  bool get isDrinksOnly =>
      plates.isEmpty && includedSides.isEmpty && proteins.isEmpty && drinks.isNotEmpty;

  bool get hasAnything =>
      plates.isNotEmpty ||
      includedSides.isNotEmpty ||
      drinks.isNotEmpty ||
      proteins.isNotEmpty;

  factory Cookout.fromJson(Map<String, dynamic> json) {
    List<CookoutAddon> addons(List<String> keys) {
      for (final key in keys) {
        final raw = json[key];
        if (raw is List && raw.isNotEmpty) {
          return raw
              .whereType<Map>()
              .map((item) => CookoutAddon.fromJson(item.cast<String, dynamic>()))
              .toList();
        }
      }
      return const [];
    }

    List<String> sides() {
      final raw = json['included_sides'] ?? json['includedSides'] ?? json['sides'];
      if (raw is List) return raw.map((item) => item.toString()).toList();
      if (raw is String && raw.trim().isNotEmpty) {
        return raw.split(',').map((part) => part.trim()).toList();
      }
      return const [];
    }

    final rawPlates = json['plates'] ?? json['included_plates'] ?? json['proteins_included'];

    return Cookout(
      title: json['title']?.toString() ?? 'Cookout Plate Order',
      note: json['note']?.toString() ??
          'Base includes one plate. Add-ons update totals automatically.',
      plates: rawPlates is List
          ? rawPlates
              .whereType<Map>()
              .map((item) => CookoutOption.fromJson(item.cast<String, dynamic>()))
              .toList()
          : const [],
      includedSides: sides(),
      drinks: addons(['drinks', 'addon_drinks', 'add_on_drinks']),
      proteins: addons(['proteins', 'addon_proteins', 'add_on_proteins']),
    );
  }
}

/// One selectable protein for the plate that comes with the ticket.
class CookoutOption {
  final String id;
  final String name;
  final String note;

  const CookoutOption(
      {required this.id, required this.name, this.note = 'Included plate'});

  factory CookoutOption.fromJson(Map<String, dynamic> json) {
    final name = json['name']?.toString() ?? '';
    return CookoutOption(
      id: json['id']?.toString() ?? name,
      name: name,
      note: json['note']?.toString() ?? 'Included plate',
    );
  }
}

/// A paid extra (drink or protein) with its own stock counter.
class CookoutAddon {
  final String id;
  final String name;
  final double price;
  final int available;

  const CookoutAddon({
    required this.id,
    required this.name,
    required this.price,
    required this.available,
  });

  bool get isSoldOut => available <= 0;

  factory CookoutAddon.fromJson(Map<String, dynamic> json) {
    final name = json['name']?.toString() ?? '';
    return CookoutAddon(
      id: json['id']?.toString() ?? name,
      name: name,
      price: double.tryParse(json['price']?.toString() ?? '') ?? 0,
      available: int.tryParse(
              (json['available'] ?? json['qty_available'])?.toString() ?? '') ??
          0,
    );
  }
}

class Wellness {
  final String includeService;
  final Booking? booking;
  final List<WellnessService> services;

  const Wellness({required this.includeService, this.booking, required this.services});

  factory Wellness.fromJson(Map<String, dynamic> json) {
    return Wellness(
      includeService: json['includeService']?.toString() ?? '',
      booking: json['booking'] is Map
          ? Booking.fromJson(Map<String, dynamic>.from(json['booking'] as Map))
          : null,
      services: (json['services'] as List? ?? [])
          .whereType<Map>()
          .map((item) => WellnessService.fromJson(Map<String, dynamic>.from(item)))
          .toList(),
    );
  }
}

class Booking {
  final String duration;
  final String buffer;
  final String maxPerSlot;
  final String mode;
  final String mobileFee;
  final String policy;
  final String? slotDate;
  final String? slotStart;
  final String? slotEnd;
  final List<Slot> slots;
  final String? selectedSlotText;

  const Booking({
    required this.duration,
    required this.buffer,
    required this.maxPerSlot,
    required this.mode,
    required this.mobileFee,
    required this.policy,
    this.slotDate,
    this.slotStart,
    this.slotEnd,
    required this.slots,
    this.selectedSlotText,
  });

  factory Booking.fromJson(Map<String, dynamic> json) {
    return Booking(
      duration: json['duration']?.toString() ?? '',
      buffer: json['buffer']?.toString() ?? '',
      maxPerSlot: json['maxPerSlot']?.toString() ?? '',
      mode: json['mode']?.toString() ?? '',
      mobileFee: json['mobileFee']?.toString() ?? '',
      policy: json['policy']?.toString() ?? '',
      slotDate: json['slotDate']?.toString(),
      slotStart: json['slotStart']?.toString(),
      slotEnd: json['slotEnd']?.toString(),
      slots: (json['slots'] as List? ?? [])
          .whereType<Map>()
          .map((item) => Slot.fromJson(Map<String, dynamic>.from(item)))
          .toList(),
      selectedSlotText: json['selectedSlotText']?.toString(),
    );
  }
}

class Slot {
  final String key;
  final String label;
  final String start;
  final String end;
  final String disabled;

  const Slot({required this.key, required this.label, required this.start, required this.end, required this.disabled});

  factory Slot.fromJson(Map<String, dynamic> json) {
    return Slot(
      key: json['key']?.toString() ?? '',
      label: json['label']?.toString() ?? '',
      start: json['start']?.toString() ?? '',
      end: json['end']?.toString() ?? '',
      disabled: json['disabled']?.toString() ?? '0',
    );
  }
}

class WellnessService {
  final String name;
  final String mode;
  final String price;
  final String duration;

  const WellnessService({required this.name, required this.mode, required this.price, required this.duration});

  factory WellnessService.fromJson(Map<String, dynamic> json) {
    return WellnessService(
      name: ApiUserMapper.asString(json['name']),
      mode: ApiUserMapper.asString(json['mode']),
      price: json['price']?.toString() ?? '0',
      duration: json['duration']?.toString() ?? '',
    );
  }
}

class WellnessSlotBlock {
  final int id;
  final String slotDate;
  final String startTime;
  final String endTime;
  final int count;

  WellnessSlotBlock({required this.id, required this.slotDate, required this.startTime, required this.endTime, required this.count});

  factory WellnessSlotBlock.fromJson(Map<String, dynamic> json) {
    return WellnessSlotBlock(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '') ?? 0,
      slotDate: json['slot_date']?.toString() ?? '',
      startTime: json['start_time']?.toString() ?? '',
      endTime: json['end_time']?.toString() ?? '',
      count: json['count'] is int ? json['count'] : int.tryParse(json['count']?.toString() ?? '') ?? 0,
    );
  }
}

class Sponsor {
  final int id;
  final String name;
  final String description;
  final String imageUrl;

  Sponsor({required this.id, required this.name, required this.description, required this.imageUrl});

  factory Sponsor.fromJson(Map<String, dynamic> json) {
    return Sponsor(
      id: json['id'] is int ? json['id'] as int : int.tryParse(json['id']?.toString() ?? '') ?? 0,
      name: ApiUserMapper.asString(json['name']),
      description: ApiUserMapper.asString(json['description']),
      imageUrl: ApiUserMapper.resolveEventImage(json),
    );
  }
}

class OrganizerStats {
  final int organizerId;
  final String organizerName;
  final String organizerAvatar;
  final int followersCount;
  final int eventsCount;
  final String hostingSince;
  final bool isFollowing;

  OrganizerStats({
    required this.organizerId,
    required this.organizerName,
    required this.organizerAvatar,
    required this.followersCount,
    required this.eventsCount,
    required this.hostingSince,
    required this.isFollowing,
  });

  factory OrganizerStats.fromJson(Map<String, dynamic> json) {
    return OrganizerStats(
      organizerId: json['organizer_id'] is int
          ? json['organizer_id'] as int
          : int.tryParse(json['organizer_id']?.toString() ?? '') ?? 0,
      organizerName: ApiUserMapper.asString(json['organizer_name']),
      organizerAvatar: ApiUserMapper.extractMediaUrl(
        json['organizer_avatar'] ?? json['organizer_image_url'] ?? json['avatar'],
      ),
      followersCount: json['followers_count'] is int
          ? json['followers_count'] as int
          : int.tryParse(json['followers_count']?.toString() ?? '') ?? 0,
      eventsCount: json['events_count'] is int
          ? json['events_count'] as int
          : int.tryParse(json['events_count']?.toString() ?? '') ?? 0,
      hostingSince: ApiUserMapper.asString(json['hosting_since']),
      isFollowing: json['is_following'] == true || json['is_following'] == 1,
    );
  }

  OrganizerStats copyWith({
    bool? isFollowing,
    int? followersCount,
  }) {
    return OrganizerStats(
      organizerId: organizerId,
      organizerName: organizerName,
      organizerAvatar: organizerAvatar,
      followersCount: followersCount ?? this.followersCount,
      eventsCount: eventsCount,
      hostingSince: hostingSince,
      isFollowing: isFollowing ?? this.isFollowing,
    );
  }
}

class OrganizerFollowResult {
  final bool isFollowing;
  final int? followersCount;

  OrganizerFollowResult({
    required this.isFollowing,
    this.followersCount,
  });
}

class Attendee {
  final int id;
  final String name;
  final String avatar;

  Attendee({required this.id, required this.name, required this.avatar});

  factory Attendee.fromJson(Map<String, dynamic> json) {
    return Attendee(
      id: json['id'] is int ? json['id'] as int : int.tryParse(json['id']?.toString() ?? '') ?? 0,
      name: ApiUserMapper.asString(json['name']),
      avatar: ApiUserMapper.extractMediaUrl(json['avatar'] ?? json['image'] ?? json['image_url']),
    );
  }
}

class Review {
  final int id;
  final String reviewerName;
  final int rating;
  final String reviewText;
  final String createdAt;

  Review({required this.id, required this.reviewerName, required this.rating, required this.reviewText, required this.createdAt});

  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      id: json['id'] is int ? json['id'] as int : int.tryParse(json['id']?.toString() ?? '') ?? 0,
      reviewerName: ApiUserMapper.asString(json['reviewer_name'] ?? json['name']),
      rating: json['rating'] is int
          ? json['rating'] as int
          : int.tryParse(json['rating']?.toString() ?? '') ?? 0,
      reviewText: ApiUserMapper.asString(json['review_text'] ?? json['text'] ?? json['comment']),
      createdAt: ApiUserMapper.asString(json['created_at']),
    );
  }
}

List<Ticket> _parseTickets(dynamic raw) {
  if (raw is! List) return const [];
  final tickets = <Ticket>[];
  for (final item in raw) {
    if (item is! Map) continue;
    try {
      tickets.add(Ticket.fromJson(Map<String, dynamic>.from(item)));
    } catch (_) {}
  }
  return tickets;
}

DateTime? _parseEventDateTime(String? raw, {required bool endOfDay}) {
  if (raw == null) return null;
  final text = raw.trim();
  if (text.isEmpty || text.toLowerCase() == 'null') return null;
  final parsed = DateTime.tryParse(text);
  if (parsed == null) return null;
  final local = parsed.toLocal();
  if (endOfDay) {
    return DateTime(local.year, local.month, local.day, 23, 59, 59);
  }
  return local;
}
