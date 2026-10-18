import 'package:link_up/model/event_detail_model.dart';

/// Static stand-in tickets that mirror the web checkout.
///
/// The tickets endpoint is not populated for every event yet, and an empty
/// response used to leave the booking sheet blank. These keep the full UI
/// reachable on both platforms; they are only used when the API returns
/// nothing, so real data always wins.
class DemoEventTickets {
  const DemoEventTickets._();

  /// Picks the set that suits [categoryName] / [eventType].
  static List<Ticket> forEvent({String categoryName = '', String eventType = ''}) {
    final haystack = '$categoryName $eventType'.toLowerCase();
    if (haystack.contains('cookout') || haystack.contains('food')) {
      return cookoutTickets();
    }
    if (haystack.contains('wellness') ||
        haystack.contains('spa') ||
        haystack.contains('massage')) {
      return wellnessTickets();
    }
    return partyTickets();
  }

  /// "Harry's Cookout Fund" — plate picker, sides, drink and protein add-ons.
  static List<Ticket> cookoutTickets() => [
        _ticket(
          id: 9001,
          name: 'Harry Food',
          type: 'Cookouts/Food',
          description: 'test food',
          price: '20.00',
          qtyAvailable: 10,
          cookout: const Cookout(
            plates: [
              CookoutOption(id: 'fried-fish', name: 'Fried Fish'),
              CookoutOption(id: 'jerk-chicken', name: 'Jerk Chicken'),
              CookoutOption(id: 'bbq-ribs', name: 'BBQ Ribs'),
            ],
            includedSides: [
              'Rice',
              'Macaroni (Mac Pie)',
              'Potato Salad',
              'Coleslaw',
            ],
            drinks: [
              CookoutAddon(id: 'water', name: 'Water', price: 2, available: 20),
              CookoutAddon(
                  id: 'soft-drinks', name: 'Soft Drinks', price: 3, available: 20),
            ],
            proteins: [
              CookoutAddon(
                  id: 'curry-chicken',
                  name: 'Curry Chicken',
                  price: 8,
                  available: 0),
              CookoutAddon(
                  id: 'extra-fried-fish',
                  name: 'Extra Fried Fish',
                  price: 10,
                  available: 5),
            ],
          ),
        ),
      ];

  /// "Old School Getaway" — plain ticket, a VIP with drinks, a bundle.
  static List<Ticket> partyTickets() => [
        _ticket(
          id: 9101,
          name: 'Ticket',
          type: 'Party/Fete',
          description: 'thick',
          price: '25.00',
          qtyAvailable: 7,
        ),
        _ticket(
          id: 9102,
          name: 'VIP',
          type: 'Party/Fete',
          description: 'VIP',
          price: '40.00',
          qtyAvailable: 7,
          cookout: const Cookout(
            drinks: [
              CookoutAddon(id: 'water', name: 'Water', price: 2, available: 20),
              CookoutAddon(
                  id: 'rum-punch', name: 'Rum Punch', price: 6, available: 12),
            ],
          ),
        ),
        _ticket(
          id: 9103,
          name: 'Bond Special',
          type: 'Party/Fete',
          description: 'Bond Special',
          price: '250.00',
          qtyAvailable: 5,
          packageItems: const [
            'Round-trip ferry to Bimini',
            'Two nights shared accommodation',
            'Welcome dinner and open bar',
            'Priority entry to all fetes',
          ],
        ),
      ];

  /// "Polished Gem Wellness Spa" — bookable slots and a service location.
  static List<Ticket> wellnessTickets() => [
        _ticket(
          id: 9201,
          name: 'Massage Service',
          type: 'Wellness and Spa',
          description: 'Massage Service',
          price: '100.00',
          qtyAvailable: 7,
          wellness: Wellness(
            includeService: 'Sports Massage',
            booking: Booking(
              duration: '60',
              buffer: '15',
              maxPerSlot: '1',
              mode: 'inhouse',
              mobileFee: '0.00',
              policy:
                  'Non-refundable. Reschedule allowed up to 24 hours before appointment.',
              slotDate: '2026-04-02',
              slotStart: '09:00',
              slotEnd: '18:00',
              slots: const [
                Slot(key: 's1', label: '09:00-10:00', start: '09:00', end: '10:00', disabled: '0'),
                Slot(key: 's2', label: '10:15-11:15', start: '10:15', end: '11:15', disabled: '0'),
                Slot(key: 's3', label: '11:30-12:30', start: '11:30', end: '12:30', disabled: '0'),
                Slot(key: 's4', label: '12:45-13:45', start: '12:45', end: '13:45', disabled: '1'),
                Slot(key: 's5', label: '14:00-15:00', start: '14:00', end: '15:00', disabled: '1'),
                Slot(key: 's6', label: '15:15-16:15', start: '15:15', end: '16:15', disabled: '0'),
                Slot(key: 's7', label: '16:30-17:30', start: '16:30', end: '17:30', disabled: '0'),
              ],
            ),
            services: const [
              WellnessService(
                  name: 'Sports Massage',
                  mode: 'inhouse',
                  price: '0.00',
                  duration: '60'),
            ],
          ),
        ),
      ];

  static Ticket _ticket({
    required int id,
    required String name,
    required String type,
    required String description,
    required String price,
    required int qtyAvailable,
    Cookout? cookout,
    Wellness? wellness,
    List<String> packageItems = const [],
  }) {
    return Ticket(
      id: id,
      name: name,
      type: type,
      description: description,
      price: price,
      promoPrice: '0.00',
      isFree: false,
      hasTable: false,
      tablePrice: '0.00',
      tableCapacity: 0,
      quantity: qtyAvailable,
      qtyAvailable: qtyAvailable,
      status: 'active',
      cookout: cookout,
      wellness: wellness,
      wellnessSlotBlocks: const [],
      packageItems: packageItems,
    );
  }
}
