import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'widgets/custom_app_bar.dart';

class MapScreen extends StatelessWidget {
  final String shopName;
  final List<List<double>> routePolyline;
  final List<List<double>> stopCoords;
  final List<String> stopNames;

  const MapScreen({
    required this.shopName,
    required this.routePolyline,
    required this.stopCoords,
    required this.stopNames,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final routePoints = routePolyline.map((p) => LatLng(p[0], p[1])).toList();

    final bounds = LatLngBounds(routePoints.first, routePoints.first);
    for (var p in routePoints) {
      bounds.extend(p);
    }

    final markers = <Marker>[];
    for (int i = 0; i < stopCoords.length; i++) {
      final latlng = LatLng(stopCoords[i][0], stopCoords[i][1]);
      final isStart = i == 0;
      final isEnd = i == stopCoords.length - 1;

      markers.add(
        Marker(
          point: latlng,
          width: 40,
          height: 40,
          child: GestureDetector(
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(stopNames[i]),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
            child: Icon(
              Icons.location_on,
              color: isStart || isEnd ? Colors.red : Colors.grey[800],
              size: 30,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: CustomAppBar(title: "$shopNameのルート"),
      body: FlutterMap(
        options: MapOptions(
          bounds: bounds,
          boundsOptions: const FitBoundsOptions(padding: EdgeInsets.all(32)),
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.example.geocycle',
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
          MarkerLayer(markers: markers),
        ],
      ),
    );
  }
}
