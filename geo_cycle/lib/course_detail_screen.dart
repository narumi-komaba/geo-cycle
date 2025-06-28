import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'widgets/custom_app_bar.dart';
import 'widgets/map_area.dart';

class CourseDetailScreen extends StatelessWidget {
  final String shopName;
  final String description;
  final String courseDetail;
  final Map<String, dynamic> routeSummary;
  final List<List<double>> routePolyline;
  final List<List<double>> stopCoords;
  final List<String> stopNames;
  final List<dynamic> spotDetails;

  const CourseDetailScreen({
    super.key,
    required this.shopName,
    required this.description,
    required this.courseDetail,
    required this.routeSummary,
    required this.routePolyline,
    required this.stopCoords,
    required this.stopNames,
    this.spotDetails = const [],
  });

  Widget _buildInfoCard(IconData icon, String label, String value) {
    return Expanded(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: Colors.grey[700]),
              const SizedBox(width: 4),
              Text(label, style: const TextStyle(fontSize: 12)),
            ],
          ),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  void _openRouteInGoogleMaps(BuildContext context) async {
    if (stopCoords.length >= 2) {
      final start = stopCoords.first;
      final end = stopCoords.last;

      // 経由地（始点と終点を除く）
      final waypoints = stopCoords
          .sublist(1, stopCoords.length - 1)
          .map((coord) => '${coord[0]},${coord[1]}')
          .join('|');

      final url = Uri.parse(
        'https://www.google.com/maps/dir/?api=1'
        '&origin=${start[0]},${start[1]}'
        '&destination=${end[0]},${end[1]}'
        '&travelmode=bicycling'
        '${waypoints.isNotEmpty ? '&waypoints=$waypoints' : ''}',
      );

      if (await canLaunchUrl(url)) {
        await launchUrl(url);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Googleマップを開けませんでした")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalCalories = spotDetails.fold<int>(0, (sum, item) => sum + ((item['calorie'] ?? 0) as num).toInt());
    final totalPrice = spotDetails.fold<int>(0, (sum, item) => sum + ((item['price'] ?? 0) as num).toInt());

    return Scaffold(
      appBar: CustomAppBar(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 地図プレビュー
            SizedBox(
              height: 200,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: MapArea(
                  shopName: shopName,
                  routePolyline: routePolyline,
                  stopCoords: stopCoords,
                  stopNames: stopNames,
                  isPreview: true,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ルート概要（見出しなし）
            Row(
              children: [
                _buildInfoCard(Icons.route, "距離", "${routeSummary['distance_km']} km"),
                _buildInfoCard(Icons.timer, "時間", "${routeSummary['duration_min']} 分"),
                _buildInfoCard(Icons.terrain, "標高差", "${routeSummary['elevation_gain_m']} m"),
                _buildInfoCard(Icons.local_fire_department, "消費", "${routeSummary['calories_kcal']} kcal"),
                _buildInfoCard(Icons.fastfood, "摂取", "${routeSummary['gyoza_calories']} kcal"),
              ],
            ),
            const SizedBox(height: 24),

            // コース解説
            Row(
              children: const [
                Icon(Icons.menu_book, color: Color(0xFFFFA410)),
                SizedBox(width: 6),
                Text("コース解説", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 8),
            Text(description, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 16),
            Text(courseDetail, style: const TextStyle(fontSize: 14)),
            const SizedBox(height: 24),

            // スポット詳細
            if (spotDetails.isNotEmpty) ...[
              Row(
                children: const [
                  Icon(Icons.store, color: Color(0xFFFFA410)),
                  SizedBox(width: 6),
                  Text("スポット詳細", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    const Text("合計", style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(width: 8),
                    Text("¥$totalPrice"),
                    const SizedBox(width: 12),
                    const Icon(Icons.fastfood, size: 16),
                    Text("$totalCalories kcal"),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              for (var spot in spotDetails)
                Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 160), // 高さ160を最小値に変更
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start, // 高さが違う場合の調整
                      children: [
                        if (spot['photo_url'] != null)
                          Builder(builder: (_) {
                            final photoUrl = spot['photo_url'];
                            final ref = Uri.parse(photoUrl).queryParameters['ref'] ??
                                Uri.parse(photoUrl).queryParameters['photoreference'];
                            final imageUrl = ref != null
                                ? "https://place-photo-300937800298.asia-northeast1.run.app/place-photo?ref=$ref"
                                : photoUrl;

                            return ClipRRect(
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(8),
                                bottomLeft: Radius.circular(8),
                              ),
                              child: Image.network(
                                imageUrl,
                                width: 140,
                                height: 160, // 固定でOK
                                fit: BoxFit.cover,
                                errorBuilder: (context, _, __) => const SizedBox(
                                  width: 140,
                                  child: Center(child: Text("画像\n読み込み\n失敗", textAlign: TextAlign.center)),
                                ),
                              ),
                            );
                          }),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min, // 子の高さに合わせる
                              children: [
                                Text(spot['name'] ?? '',
                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 6),
                                Text(spot['description'] ?? '',
                                    style: const TextStyle(fontSize: 13),
                                    maxLines: 3,
                                    overflow: TextOverflow.ellipsis),
                                const SizedBox(height: 8),
                                Text(spot['menu'] ?? '', style: const TextStyle(fontSize: 13)),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Text("¥${spot['price'] ?? '-'}"),
                                    const SizedBox(width: 12),
                                    const Icon(Icons.fastfood, size: 14),
                                    const SizedBox(width: 2),
                                    Text("${spot['calorie'] ?? '-'} kcal"),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        )
                      ],
                    ),
                  ),
                ),
            ],

            const SizedBox(height: 24),

            // 地図を見るボタン
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.map),
                label: const Text("地図を見る"),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => Scaffold(
                        appBar: CustomAppBar(),
                        body: MapArea(
                          shopName: shopName,
                          routePolyline: routePolyline,
                          stopCoords: stopCoords,
                          stopNames: stopNames,
                          isPreview: false,
                        ),
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFA410),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Googleマップルートボタン
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.directions_bike),
                label: const Text("Googleマップでルート案内を開く"),
                onPressed: () => _openRouteInGoogleMaps(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey.shade800,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
