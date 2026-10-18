import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pretty_qr_code/pretty_qr_code.dart';

class ApiETicket extends StatelessWidget {
  final Map<String, dynamic> ticket;

  const ApiETicket({Key? key, required this.ticket}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final event = ticket['event'] ?? {};
    final ticketInfo = ticket['ticket'] ?? {};
    
    final eventTitle = event['title'] ?? 'Event';
    final eventDateStr = event['single_event_date'] ?? ticket['created_at'] ?? '';
    DateTime? eventDate;
    if (eventDateStr.isNotEmpty) {
      eventDate = DateTime.tryParse(eventDateStr);
    }
    final formattedDate = eventDate != null
        ? DateFormat('dd/MM/yyyy • hh:mm a').format(eventDate)
        : eventDateStr;

    final venue = event['venue'] ?? '';
    final city = event['city'] ?? '';
    final country = event['country'] ?? '';
    final location = [venue, city, country].where((s) => s != null && s.isNotEmpty).join(', ');

    final ticketId = ticket['ticket_qrcode'] ?? '';
    final ticketDisplayId = 'LU-TKT-${ticket['ticket_id'] ?? ticket['id']}';
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Ticket Details'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      backgroundColor: Colors.grey[100],
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 5)),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.blue[600],
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Event Information', style: TextStyle(color: Colors.white70, fontSize: 12)),
                        SizedBox(height: 5),
                        Text(eventTitle, style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.all(20),
                    child: Column(
                      children: [
                        _detailRow('Title:', eventTitle),
                        _detailRow('City:', city),
                        _detailRow('Date:', formattedDate),
                        _detailRow('Venue:', venue),
                        Divider(height: 30),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text('Ticket Information', style: TextStyle(color: Colors.grey, fontSize: 12)),
                        ),
                        SizedBox(height: 10),
                        _detailRow('Name:', ticketInfo['name'] ?? ''),
                        _detailRow('Type:', ticketInfo['type'] ?? ''),
                        _detailRow('Ticket ID:', ticketDisplayId, isBadge: true),
                        _detailRow('Price:', '\$USD ${ticket['total']}'),
                      ],
                    ),
                  ),
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(30),
                    color: Colors.grey[50],
                    child: Column(
                      children: [
                        Text('Scan for Entry', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        Text('Present this QR code at the venue', style: TextStyle(color: Colors.grey, fontSize: 12)),
                        SizedBox(height: 20),
                        Container(
                          width: 200,
                          height: 200,
                          padding: EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.grey[200]!),
                          ),
                          child: PrettyQrView.data(
                            data: ticketId,
                          ),
                        ),
                        SizedBox(height: 10),
                        Text('Valid QR token for secure verification', style: TextStyle(color: Colors.grey, fontSize: 10)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.info_outline, size: 14, color: Colors.grey),
                SizedBox(width: 5),
                Text('Keep this ticket secure and do not share', style: TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                minimumSize: Size(double.infinity, 50),
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: BorderSide(color: Colors.grey[300]!),
                ),
              ),
              child: Text('Close'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value, {bool isBadge = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 80, child: Text(label, style: TextStyle(color: Colors.grey))),
          Expanded(
            child: isBadge
                ? Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(value, style: TextStyle(fontWeight: FontWeight.w600)),
                  )
                : Text(value, style: TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}
