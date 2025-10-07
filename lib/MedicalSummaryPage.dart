import 'package:flutter/material.dart';

class MedicalSummaryPage extends StatelessWidget {
  final String userInput;
  final List<String> selectedSymptoms;
  final Map<String, String> answers;
  final String predictedDisease;

  const MedicalSummaryPage({
    super.key,
    required this.userInput,
    required this.selectedSymptoms,
    required this.answers,
    required this.predictedDisease,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E3C72),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context); // 🔹 뒤로가기 → RefinedDiseasePage 복귀
          },
        ),
        title: const Text(
          "문진표 요약",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: ListView(
          children: [
            _sectionTitle("🩺 사용자 입력"),
            _box(userInput),

            _sectionTitle("📋 선택한 증상"),
            _box(selectedSymptoms.join(", ")),

            _sectionTitle("🧠 AI 예상 질환"),
            _box(predictedDisease),


            _sectionTitle("🧾 문진 응답"),
            ...answers.entries.map((e) => ListTile(
              title: Text(e.key, style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text("응답: ${e.value}"),
              leading: const Icon(Icons.check_circle_outline, color: Color(0xFF1E3C72)),
            )),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String text) => Padding(
    padding: const EdgeInsets.only(top: 20, bottom: 10),
    child: Text(
      text,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E3C72)),
    ),
  );

  Widget _box(String text) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Colors.grey[100],
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Colors.black12),
    ),
    child: Text(
      text.isNotEmpty ? text : "정보 없음",
      style: const TextStyle(fontSize: 15, height: 1.5),
    ),
  );
}
