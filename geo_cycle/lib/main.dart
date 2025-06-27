import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'map_screen.dart';

void main() => runApp(GeoCycleApp());

class GeoCycleApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '餃輪 GeoCycle',
      home: GeoCycleHome(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class GeoCycleHome extends StatefulWidget {
  @override
  _GeoCycleHomeState createState() => _GeoCycleHomeState();
}

class _GeoCycleHomeState extends State<GeoCycleHome> {
  double distance = 20, elevation = 200, time = 60;
  int selectedGyotza = 0;
  final List<String> gyotzaTypes = ['焼餃子', '水餃子', '揚げ餃子'];

  Map<String, dynamic>? routeData;

  Future<void> fetchRoute() async {
    final url = Uri.parse('https://geo-cycle-api-300937800298.asia-northeast1.run.app/generate');
    final body = jsonEncode({
      'distance': distance.toInt(),
      'elevation': elevation.toInt(),
      'time': time.toInt(),
      'gyotza_type': gyotzaTypes[selectedGyotza],
    });

    final res = await http.post(url, body: body, headers: {'Content-Type': 'application/json'});

    if (res.statusCode == 200) {
      final responseText = utf8.decode(res.bodyBytes);  // ← ここが重要
      final data = jsonDecode(responseText);
      setState(() {
        routeData = data;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("取得失敗")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('餃輪 GeoCycle')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: routeData == null
            ? ListView(
                children: [
                  Text('距離: ${distance.toInt()} km'),
                  Slider(value: distance, min: 5, max: 100, onChanged: (v) => setState(() => distance = v)),
                  Text('標高: ${elevation.toInt()} m'),
                  Slider(value: elevation, min: 0, max: 1000, onChanged: (v) => setState(() => elevation = v)),
                  Text('時間: ${time.toInt()} 分'),
                  Slider(value: time, min: 30, max: 180, onChanged: (v) => setState(() => time = v)),
                  Text('餃子タイプ: ${gyotzaTypes[selectedGyotza]}'),
                  DropdownButton(
                    value: selectedGyotza,
                    items: List.generate(gyotzaTypes.length, (i) => DropdownMenuItem(value: i, child: Text(gyotzaTypes[i]))),
                    onChanged: (v) => setState(() => selectedGyotza = v as int),
                  ),
                  ElevatedButton(onPressed: fetchRoute, child: Text('ルートを提案')),
                ],
              )
            : Card(
                elevation: 4,
                child: ListTile(
                  title: Text(routeData!["gyotza_shop"]["name"]),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("距離: ${routeData!["route_summary"]["distance_km"]} km"),
                      Text("標高差: ${routeData!["route_summary"]["elevation_gain_m"]} m"),
                      Text("所要時間: ${routeData!["route_summary"]["duration_min"]} 分"),
                      Text("カロリー: ${routeData!["route_summary"]["calories_kcal"]} kcal"),
                    ],
                  ),
                  trailing: Icon(Icons.map),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => MapScreen(
                          shopName: routeData!["gyotza_shop"]["name"],
                          lat: routeData!["gyotza_shop"]["lat"],
                          lng: routeData!["gyotza_shop"]["lng"],
                        ),
                      ),
                    );
                  },
                ),
              ),
      ),
    );
  }
}
