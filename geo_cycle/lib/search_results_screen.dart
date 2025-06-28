import 'package:flutter/material.dart';
import 'course_detail_screen.dart';
import 'widgets/custom_app_bar.dart';
import 'package:collection/collection.dart';

class SearchResultsScreen extends StatelessWidget {
  final List<dynamic> results;

  const SearchResultsScreen({required this.results, Key? key}) : super(key: key);

  double _calculateBurnRatio(Map<String, dynamic> summary) {
    final burned = (summary["calories_kcal"] ?? 0).toDouble();
    final intake = (summary["gyoza_calories"] ?? 1).toDouble();
    return (burned / intake).clamp(0.0, 1.0);
  }

  Widget _buildLabelValueAligned({
    required IconData icon,
    required String label,
    required String value,
    double labelWidth = 66.4,
    double valueWidth = 62.7,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.grey),
          const SizedBox(width: 8),
          Flexible(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isNarrow = constraints.maxWidth < (labelWidth + valueWidth + 16);
                if (isNarrow) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: labelWidth,
                        child: Text(
                          "$label：",
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                        ),
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: SizedBox(
                          width: valueWidth,
                          child: Text(
                            value,
                            textAlign: TextAlign.right,
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                      ),
                    ],
                  );
                } else {
                  return Row(
                    children: [
                      SizedBox(
                        width: labelWidth,
                        child: Text(
                          "$label：",
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: valueWidth,
                        child: Text(
                          value,
                          textAlign: TextAlign.right,
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                    ],
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(),
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
                      Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      Text(description),
                      const SizedBox(height: 12),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
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
                          Expanded(
                            flex: 5,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildLabelValueAligned(
                                  icon: Icons.route,
                                  label: "距離",
                                  value: "${summary["distance_km"]} km",
                                ),
                                _buildLabelValueAligned(
                                  icon: Icons.terrain,
                                  label: "標高差",
                                  value: "${summary["elevation_gain_m"]} m",
                                ),
                                _buildLabelValueAligned(
                                  icon: Icons.timer,
                                  label: "所要時間",
                                  value: "${summary["duration_min"]} 分",
                                ),
                                _buildLabelValueAligned(
                                  icon: Icons.local_fire_department,
                                  label: "消費",
                                  value: "${summary["calories_kcal"]} kcal",
                                ),
                                _buildLabelValueAligned(
                                  icon: Icons.fastfood,
                                  label: "摂取",
                                  value: "${summary["gyoza_calories"]} kcal",
                                ),
                                const SizedBox(height: 12),
                                Text("カロリー消費率", style: TextStyle(fontSize: 13)),
                                const SizedBox(height: 6),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: LinearProgressIndicator(
                                    value: _calculateBurnRatio(summary),
                                    backgroundColor: Colors.grey[300],
                                    color: const Color(0xFFFFA410),
                                    minHeight: 20,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "${(_calculateBurnRatio(summary) * 100).clamp(0, 999).toStringAsFixed(1)}%",
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
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
                                ),
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
