import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class MapScreen extends StatelessWidget {
  final String shopName;
  final double lat;
  final double lng;

  const MapScreen({
    required this.shopName,
    required this.lat,
    required this.lng,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final point = LatLng(lat, lng);

    return Scaffold(
      appBar: AppBar(title: Text(shopName)),
      body: FlutterMap(
        options: MapOptions(center: point, zoom: 15.0),
        children: [
          TileLayer(
            urlTemplate:
                'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
            subdomains: const ['a', 'b', 'c'],
          ),
          MarkerLayer(
            markers: [
              Marker(
                point: LatLng(36.5657, 139.8836),
                width: 80,
                height: 80,
                child: Icon(Icons.location_on, color: Colors.red, size: 40),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
