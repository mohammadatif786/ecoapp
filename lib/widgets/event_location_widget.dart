import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class EventLocationWidget extends StatelessWidget {
  final double? latitude;
  final double? longitude;
  final String venue;
  final String city;
  final String country;

  const EventLocationWidget({
    Key? key,
    this.latitude,
    this.longitude,
    required this.venue,
    required this.city,
    required this.country,
  }) : super(key: key);

  Future<void> _openGoogleMaps() async {
    final query = Uri.encodeComponent('$venue, $city, $country');
    final url = Uri.parse('https://www.google.com/maps/search/?api=1&query=$query');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final fullLocation = '$venue, $city, $country';
    final hasCoords = latitude != null && longitude != null;
    final position = LatLng(latitude ?? 25.7617, longitude ?? -80.1918);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.location_on, color: Color(0xff2d98e5), size: 18),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                fullLocation,
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                  color: Color(0xff0f172a),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (hasCoords)
          SizedBox(
            height: 180,
            width: double.infinity,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Stack(
                children: [
                  GoogleMap(
                    initialCameraPosition: CameraPosition(target: position, zoom: 15),
                    markers: {
                      Marker(
                        markerId: const MarkerId('event-location'),
                        position: position,
                        infoWindow: InfoWindow(title: venue, snippet: '$city, $country'),
                      ),
                    },
                    zoomControlsEnabled: false,
                    myLocationButtonEnabled: false,
                    gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
                      Factory<OneSequenceGestureRecognizer>(() => EagerGestureRecognizer()),
                    },
                  ),
                  Positioned(
                    right: 12,
                    bottom: 12,
                    child: ElevatedButton.icon(
                      onPressed: _openGoogleMaps,
                      icon: const Icon(Icons.directions, size: 16),
                      label: const Text('Directions'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xff2d98e5),
                        foregroundColor: Colors.white,
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
