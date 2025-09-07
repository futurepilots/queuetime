import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapView extends StatelessWidget {
  final List<Map<String,dynamic>> places;
  final LatLng initialPosition;

  const MapView({super.key, required this.places, required this.initialPosition});

  @override
  Widget build(BuildContext context) {
    Set<Marker> markers = places.map((p) => Marker(
      markerId: MarkerId(p['name']),
      position: LatLng(p['lat'], p['lng']),
      infoWindow: InfoWindow(
        title: p['name'],
        snippet: 'Wartezeit: ${p['waitTime']} min',
      ),
      icon: BitmapDescriptor.defaultMarkerWithHue(
        30.0 * (p['crowdLevel'] ?? 1),
      ),
    )).toSet();

    return SizedBox(
      height: 300,
      child: GoogleMap(
        initialCameraPosition: CameraPosition(
          target: initialPosition,
          zoom: 13,
        ),
        markers: markers,
      ),
    );
  }
}
