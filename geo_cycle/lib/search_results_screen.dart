import 'package:flutter/material.dart';
import 'course_detail_screen.dart';
import 'widgets/custom_app_bar.dart';
import 'package:collection/collection.dart';

class SearchResultsScreen extends StatelessWidget {
  final List<dynamic> results;

  const SearchResultsScreen({required this.results, Key? key}) : super(key: key);

  double _calculateBurnRatio(Map<String, dynamic> summary) {
    final burned = (summary["calories_kcal"] ?? 0).toDouble();
    final intake = (summary["gyoza_calories"] ?? 1).toDouble(); // 0除算対策
    return (burned / intake).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: "検索結果"),
      body: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: results.length,
        itemBuilder: (context, index) {
          final result = results[index];
          final summary = result["route_summary"];
          final description = result["course_description"];
          final title = result["course_title"] ?? "コース";
          final spotDetails = result["spot_details"] ?? [];
          final photoUrl = spotDetails.isNotEmpty ? spotDetails[0]["photo_url"] : result["photo_url"];
          final stops = result["stops"] ?? [];
          final stopsList = List<String>.from(stops);

          final ref = Uri.parse(photoUrl ?? '').queryParameters['ref'] ??
              Uri.parse(photoUrl ?? '').queryParameters['photoreference'];
          final imageUrl = ref != null
              ? "https://place-photo-300937800298.asia-northeast1.run.app/place-photo?ref=$ref"
              : photoUrl;

          return Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            margin: const EdgeInsets.only(bottom: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (imageUrl != null)
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                    child: Image.network(
                      imageUrl,
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          const SizedBox(height: 200, child: Center(child: Text("画像読み込み失敗"))),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      Text(description),
                      const SizedBox(height: 12),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // めぐるスポット
                          Expanded(
                            flex: 5,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: stopsList.mapIndexed((i, stop) {
                                  return Column(
                                    children: [
                                      Text(stop,
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(fontSize: 14)),
                                      if (i < stops.length - 1)
                                        const Text("↓", textAlign: TextAlign.center),
                                    ],
                                  );
                                }).toList(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          // 距離など
                          Expanded(
                            flex: 5,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(children: [
                                  const Icon(Icons.route, size: 20, color: Colors.grey),
                                  const SizedBox(width: 8),
                                  const SizedBox(
                                      width: 80,
                                      child: Text("距離",
                                          textAlign: TextAlign.left,
                                          style: TextStyle(
                                            fontWeight: FontWeight.w500,
                                            fontSize: 13,
                                            ))),
                                  const Text("："),
                                  const SizedBox(width: 8),
                                  Expanded(
                                      child: Text("${summary["distance_km"]} km",
                                          textAlign: TextAlign.right))
                                ]),
                                Row(children: [
                                  const Icon(Icons.terrain, size: 20, color: Colors.grey),
                                  const SizedBox(width: 8),
                                  const SizedBox(
                                      width: 80,
                                      child: Text("標高差",
                                          textAlign: TextAlign.left,
                                          style: TextStyle(
                                            fontWeight: FontWeight.w500,
                                            fontSize: 13,
                                            ))),
                                  const Text("："),
                                  const SizedBox(width: 8),
                                  Expanded(
                                      child: Text("${summary["elevation_gain_m"]} m",
                                          textAlign: TextAlign.right))
                                ]),
                                Row(children: [
                                  const Icon(Icons.timer, size: 20, color: Colors.grey),
                                  const SizedBox(width: 8),
                                  const SizedBox(
                                      width: 80,
                                      child: Text("所要時間",
                                          textAlign: TextAlign.left,
                                          style: TextStyle(
                                            fontWeight: FontWeight.w500,
                                            fontSize: 13,
                                            ))),
                                  const Text("："),
                                  const SizedBox(width: 8),
                                  Expanded(
                                      child: Text("${summary["duration_min"]} 分",
                                          textAlign: TextAlign.right))
                                ]),
                                Row(children: [
                                  const Icon(Icons.local_fire_department, size: 20, color: Colors.grey),
                                  const SizedBox(width: 8),
                                  const SizedBox(
                                      width: 80,
                                      child: Text("消費カロリー",
                                          textAlign: TextAlign.left,
                                          style: TextStyle(
                                            fontWeight: FontWeight.w500,
                                            fontSize: 13,
                                            ))),
                                  const Text("："),
                                  const SizedBox(width: 8),
                                  Expanded(
                                      child: Text("${summary["calories_kcal"]} kcal",
                                          textAlign: TextAlign.right))
                                ]),
                                Row(children: [
                                  const Icon(Icons.fastfood, size: 20, color: Colors.grey),
                                  const SizedBox(width: 8),
                                  const SizedBox(
                                      width: 80,
                                      child: Text("摂取カロリー",
                                          textAlign: TextAlign.left,
                                          style: TextStyle(
                                            fontWeight: FontWeight.w500,
                                            fontSize: 13,
                                            ))),
                                  const Text("："),
                                  const SizedBox(width: 8),
                                  Expanded(
                                      child: Text("${summary["gyoza_calories"]} kcal",
                                          textAlign: TextAlign.right))
                                ]),
                                const SizedBox(height: 12),
                                Text("カロリー消費率", style: TextStyle(fontSize: 13)),
                                const SizedBox(height: 6),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: LinearProgressIndicator(
                                    value: _calculateBurnRatio(summary),
                                    backgroundColor: Colors.grey[300],
                                    color: Color(0xFFFFA410),
                                    minHeight: 20, // ← バーの高さ（太さ）を大きく
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "${(_calculateBurnRatio(summary) * 100).clamp(0, 999).toStringAsFixed(1)}%",
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                                  textAlign: TextAlign.right,
                                ),
                              ],
                            ),
                          )
                        ],
                      ),
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerRight,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => CourseDetailScreen(
                                  shopName: result['course_title'],
                                  description: result['course_description'],
                                  courseDetail: result['course_detail'],
                                  routeSummary: result['route_summary'],
                                  routePolyline: List<List<double>>.from(result["route_polyline"].map((p) => List<double>.from(p))),
                                  stopCoords: List<List<double>>.from(result["stop_coords"].map((p) => List<double>.from(p))),
                                  stopNames: List<String>.from(result['stops']),
                                  spotDetails: List<Map<String, dynamic>>.from(result['spot_details']),
                                )
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFFA410),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text("コースの詳細"),
                        ),
                      )
                    ],
                  ),
                )
              ],
            ),
          );
        },
      ),
    );
  }
}
