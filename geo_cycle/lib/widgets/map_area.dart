import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class MapArea extends StatelessWidget {
  final String shopName;
  final List<List<double>> routePolyline;
  final List<List<double>> stopCoords;
  final List<String> stopNames;
  final bool isPreview;

  const MapArea({
    super.key,
    required this.shopName,
    required this.routePolyline,
    required this.stopCoords,
    required this.stopNames,
    this.isPreview = false,
  });

  @override
  Widget build(BuildContext context) {
    final List<LatLng> routePoints =
        routePolyline.map((p) => LatLng(p[0], p[1])).toList();

    final List<Marker> stopMarkers = List.generate(stopCoords.length, (index) {
      final coord = stopCoords[index];
      final name = stopNames[index];

      final isStart = index == 0;
      final isEnd = index == stopCoords.length - 1;

      final pinColor = (isStart || isEnd) ? Colors.red : Colors.grey.shade800;

      return Marker(
        point: LatLng(coord[0], coord[1]),
        width: 80,
        height: 80,
        child: Column(
          children: [
            Icon(Icons.location_on, size: 30, color: pinColor),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(name, style: const TextStyle(fontSize: 10)),
            )
          ],
        ),
      );
    });

    // ルート全体を含むバウンディングボックスを計算
    final bounds = LatLngBounds.fromPoints(routePoints);

    return Scaffold(
      body: FlutterMap(
        options: MapOptions(
          bounds: bounds,
          boundsOptions: const FitBoundsOptions(padding: EdgeInsets.all(32)),
          interactiveFlags: isPreview ? InteractiveFlag.none : InteractiveFlag.all,
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.example.geo_cycle',
          ),
          PolylineLayer(
            polylines: [
              Polyline(
                points: routePoints,
                strokeWidth: 4.0,
                color: Colors.blue,
              ),
            ],
          ),
          MarkerLayer(markers: stopMarkers),
        ],
      ),
    );
  }
}
