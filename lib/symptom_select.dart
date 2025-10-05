import 'package:flutter/material.dart';
import 'isdiseaseright.dart';

class SymptomSelectPage extends StatelessWidget {
  const SymptomSelectPage({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> symptoms = [
      {"title": "흉통 (가슴 통증)", "icon": Icons.monitor_heart, "color": Colors.redAccent},
      {"title": "복통 (배 통증)", "icon": Icons.accessibility_new, "color": Colors.orangeAccent},
      {"title": "두통 (머리 통증)", "icon": Icons.psychology, "color": Colors.blueAccent},
      {"title": "호흡곤란", "icon": Icons.air, "color": Colors.teal},
      {"title": "피로감 / 무기력", "icon": Icons.battery_alert, "color": Colors.amber},
      {"title": "어지럼증", "icon": Icons.blur_circular, "color": Colors.purpleAccent},
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text("판별할 증상 선택"),
        backgroundColor: const Color(0xFF1E3C72),
        foregroundColor: Colors.white,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFE3F2FD), Color(0xFFFFFFFF)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          itemCount: symptoms.length,
          itemBuilder: (context, index) {
            final item = symptoms[index];
            return GestureDetector(
              onTap: () {
                // ✅ 흉통 선택 시에만 현재는 IsDiseaseRightPage로 이동
                if (item["title"].toString().contains("흉통")) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const IsDiseaseRightPage(),
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("${item['title']} 판별은 곧 추가될 예정입니다.")),
                  );
                }
              },
              child: Card(
                elevation: 5,
                margin: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                  leading: CircleAvatar(
                    radius: 30,
                    backgroundColor: (item["color"] as Color).withOpacity(0.15),
                    child: Icon(item["icon"], color: item["color"], size: 30),
                  ),
                  title: Text(
                    item["title"],
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, color: Colors.black38, size: 20),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
