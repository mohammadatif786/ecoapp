import 'package:flutter/material.dart';
import 'package:pretty_qr_code/pretty_qr_code.dart';
import 'package:link_up/model/event_booking_model.dart';

class EventBookingTicketPage extends StatelessWidget {
  const EventBookingTicketPage({super.key, required this.booking});

  final EventBooking booking;

  @override
  Widget build(BuildContext context) {
    final event = booking.event;
    final qr = booking.qrToken;
    return Scaffold(
      backgroundColor: const Color(0xffeaf4fe),
      appBar: AppBar(
        backgroundColor: const Color(0xff2f9bef),
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Ticket',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 32),
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: Container(
              color: Colors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    height: 150,
                    decoration: BoxDecoration(
                      color: const Color(0xff2f9bef),
                      image: event.imageUrl.isEmpty
                          ? null
                          : DecorationImage(
                              image: NetworkImage(event.imageUrl),
                              fit: BoxFit.cover,
                            ),
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(18),
                      alignment: Alignment.bottomLeft,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.black.withOpacity(0.05),
                            Colors.black.withOpacity(0.62),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                      child: Text(
                        event.title.isEmpty ? 'Event' : event.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 18, 18, 8),
                    child: Column(
                      children: [
                        _row('Event', event.title),
                        _row('Date', booking.eventDateLabel),
                        _row('Location', event.location),
                        _row('Ticket', booking.ticketName),
                        _row('Type', booking.ticketType),
                        _row('Tickets', '${booking.ticketCount}'),
                        _row('Paid', booking.paidLabel),
                        _row('Status', booking.statusLabel),
                        _row('Purchased', booking.date),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 22, 18, 26),
                    child: Column(
                      children: [
                        const Text(
                          'Scan for entry',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                            color: Color(0xff142033),
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Show this QR code at the venue',
                          style: TextStyle(
                            color: Color(0xff7a8aa0),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 18),
                        Container(
                          width: 210,
                          height: 210,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xffe5edf6)),
                          ),
                          child: qr.isEmpty
                              ? const Center(
                                  child: Icon(
                                    Icons.qr_code_2_rounded,
                                    size: 72,
                                    color: Color(0xff94a3b8),
                                  ),
                                )
                              : PrettyQrView.data(data: qr),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          qr,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Color(0xff64748b),
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(String label, String value) {
    if (value.trim().isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 92,
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xff7a8aa0),
                fontWeight: FontWeight.w800,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Color(0xff142033),
                fontWeight: FontWeight.w800,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
