import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'widgets/custom_app_bar.dart';
import 'widgets/loading_overlay.dart';
import 'search_results_screen.dart';
import 'package:google_fonts/google_fonts.dart';

void main() => runApp(GeoCycleApp());

class GeoCycleApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '餃輪 GeoCycle',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        textTheme: GoogleFonts.notoSansJpTextTheme(),
        primaryColor: const Color(0xFFFFA410),
        scaffoldBackgroundColor: Colors.white,
      ),
      home: GeoCycleHome(),
    );
  }
}

class GeoCycleHome extends StatefulWidget {
  @override
  _GeoCycleHomeState createState() => _GeoCycleHomeState();
}

class _GeoCycleHomeState extends State<GeoCycleHome> {
  String selectedCourse = '半日コース';
  late Set<String> selectedGyozaTypes;
  bool includeSightseeing = true;
  bool isLoading = false;
  final TextEditingController startController = TextEditingController();

  final List<String> courseOptions = ['半日コース', '1日コース'];
  final List<String> gyotzaTypes = ['焼き餃子', '揚げ餃子', '水餃子'];

  @override
  void initState() {
    super.initState();
    startController.text = '宇都宮駅';
    selectedGyozaTypes = gyotzaTypes.toSet();
  }

  Future<void> fetchRoute() async {
    setState(() => isLoading = true);
    final url = Uri.parse('https://geo-cycle-api-300937800298.asia-northeast1.run.app/generate');
    final startPoint = startController.text.trim().isEmpty
        ? '宇都宮駅'
        : startController.text.trim();
    final body = jsonEncode({
      'course_type': selectedCourse,
      'gyoza_type': selectedGyozaTypes.toList(),
      'include_sightseeing': includeSightseeing,
      'start_point': startPoint,
    });

    try {
      final res = await http.post(url, body: body, headers: {'Content-Type': 'application/json'});

      if (res.statusCode == 200) {
        final responseText = utf8.decode(res.bodyBytes);
        final data = jsonDecode(responseText);
        if (!mounted) return;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => SearchResultsScreen(results: data),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("取得失敗")));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("エラー: $e")));
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Widget buildOptionButtons({
    required List<String> options,
    required String selected,
    required void Function(String) onSelect,
    required int itemsPerRow,
    Color? selectedTextColor,
  }) {
    final spacing = 12.0;
    final itemWidth = (MediaQuery.of(context).size.width - 32 - spacing * (itemsPerRow - 1)) / itemsPerRow;

    return Wrap(
      spacing: spacing,
      runSpacing: spacing,
      children: options.map((opt) {
        final isSelected = opt == selected;
        return SizedBox(
          width: itemWidth,
          height: 48,
          child: OutlinedButton(
            onPressed: () => onSelect(opt),
            style: OutlinedButton.styleFrom(
              backgroundColor: isSelected ? const Color(0xFFFFA410) : Colors.white,
              foregroundColor: isSelected ? (selectedTextColor ?? Colors.black87) : Colors.black87,
              side: BorderSide(
                color: isSelected ? const Color(0xFFFFA410) : Colors.grey.shade400,
              ),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text(opt, style: const TextStyle(fontSize: 14)),
          ),
        );
      }).toList(),
    );
  }

  Widget buildMultiSelectButtons({
    required List<String> options,
    required Set<String> selectedValues,
    required void Function(String, bool) onSelect,
    required int itemsPerRow,
  }) {
    final spacing = 12.0;
    final itemWidth = (MediaQuery.of(context).size.width - 32 - spacing * (itemsPerRow - 1)) / itemsPerRow;

    return Wrap(
      spacing: spacing,
      runSpacing: spacing,
      children: options.map((opt) {
        final isSelected = selectedValues.contains(opt);
        return SizedBox(
          width: itemWidth,
          height: 48,
          child: OutlinedButton(
            onPressed: () => onSelect(opt, !isSelected),
            style: OutlinedButton.styleFrom(
              backgroundColor: isSelected ? const Color(0xFFFFA410) : Colors.white,
              foregroundColor: Colors.black87,
              side: BorderSide(
                color: isSelected ? const Color(0xFFFFA410) : Colors.grey.shade400,
              ),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text(opt, style: const TextStyle(fontSize: 14)),
          ),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(),
      body: LoadingOverlay(
        isLoading: isLoading,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ListView(
            children: [
              const Text('自転車コースを選択', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              buildOptionButtons(
                options: courseOptions,
                selected: selectedCourse,
                onSelect: (val) => setState(() => selectedCourse = val),
                itemsPerRow: 2,
              ),

              const SizedBox(height: 24),
              const Text('餃子の種類（複数選択可）', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              buildMultiSelectButtons(
                options: gyotzaTypes,
                selectedValues: selectedGyozaTypes,
                onSelect: (val, selected) {
                  setState(() {
                    if (selected) {
                      selectedGyozaTypes.add(val);
                    } else {
                      selectedGyozaTypes.remove(val);
                    }
                  });
                },
                itemsPerRow: 3,
              ),

              const SizedBox(height: 24),
              CheckboxListTile(
                title: const Text('観光名所もめぐる'),
                value: includeSightseeing,
                activeColor: const Color(0xFFFFA410),
                onChanged: (v) => setState(() => includeSightseeing = v ?? false),
                controlAffinity: ListTileControlAffinity.leading,
              ),

              const SizedBox(height: 24),
              TextField(
                controller: startController,
                decoration: const InputDecoration(
                  labelText: 'スタート地点（例：宇都宮駅）',
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: fetchRoute,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFA410),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                icon: const Icon(Icons.directions_bike),
                label: const Text('ルートを提案'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
