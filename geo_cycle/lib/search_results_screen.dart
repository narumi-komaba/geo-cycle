import 'package:flutter/material.dart';
import 'map_screen.dart';
import 'widgets/custom_app_bar.dart';

class SearchResultsScreen extends StatelessWidget {
  final List<dynamic> results;

  const SearchResultsScreen({required this.results, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: "検索結果"),
      body: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: results.length,
        itemBuilder: (context, index) {
          final result = results[index];
          final shop = result["gyotza_shop"];
          final summary = result["route_summary"];
          final description = result["course_description"];
          final rawPhotoUrl = shop["photo_url"];

          String? imageUrl;
          if (rawPhotoUrl != null) {
            final ref = Uri.parse(rawPhotoUrl).queryParameters['photoreference'];
            if (ref != null) {
              imageUrl = "https://place-photo-300937800298.asia-northeast1.run.app/place-photo?ref=$ref";
            }
          }

          return Card(
            elevation: 4,
            margin: const EdgeInsets.only(bottom: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (imageUrl != null)
                  Image.network(
                    imageUrl,
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        const SizedBox(height: 200, child: Center(child: Text("画像読み込み失敗"))),
                  ),
                ListTile(
                  title: Text(shop["name"]),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),
                      Text("距離: ${summary["distance_km"]} km"),
                      Text("標高差: ${summary["elevation_gain_m"]} m"),
                      Text("所要時間: ${summary["duration_min"]} 分"),
                      Text("カロリー: ${summary["calories_kcal"]} kcal"),
                      const SizedBox(height: 8),
                      Text(description),
                    ],
                  ),
                  trailing: const Icon(Icons.map),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => MapScreen(
                          shopName: shop["name"],
                          lat: shop["lat"],
                          lng: shop["lng"],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
