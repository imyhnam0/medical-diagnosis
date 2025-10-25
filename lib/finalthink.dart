import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'main.dart';

class FinalThinkingPage extends StatelessWidget {
  final List<String> predictedDiseases; // ✅ 최종 질병 후보들
  final String userInput; // ✅ 사용자가 처음 입력한 증상 문장
  final List<String> selectedSymptoms; // ✅ 선택된 증상 리스트
  final Map<String, String?> questionHistory; // ✅ 전체 문진 기록

  const FinalThinkingPage({
    super.key,
    required this.predictedDiseases,
    required this.userInput,
    required this.selectedSymptoms,
    required this.questionHistory,
  });

  @override
  Widget build(BuildContext context) {
    final primaryColor = const Color(0xFF1E3C72);

    return Scaffold(
      appBar: AppBar(
        title: const Text("AI 진단 결과", style: TextStyle(color: Colors.white)),
        backgroundColor: primaryColor,
        centerTitle: true,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFE3F2FD), Color(0xFFBBDEFB)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Lottie.asset("assets/medical_done.json", width: 140, repeat: false),
                const SizedBox(height: 16),
                const Text(
                  "AI의 최종 진단 후보",
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Text(
                  "입력된 증상: \"$userInput\"",
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 15, color: Colors.black87, fontStyle: FontStyle.italic),
                ),
                const SizedBox(height: 25),

                // ✅ 질병 후보 리스트 출력
                ListView.builder(
                  itemCount: predictedDiseases.length,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemBuilder: (context, index) {
                    final disease = predictedDiseases[index];
                    return Card(
                      elevation: 3,
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: primaryColor,
                          child: Text(
                            "${index + 1}",
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                        title: Text(
                          disease,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        subtitle: const Text(
                          "AI가 높은 확률로 추정한 질병",
                          style: TextStyle(color: Colors.black54),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 20),
                const Divider(thickness: 1.2),
                const SizedBox(height: 10),

                // ✅ 선택된 증상 보기
                ExpansionTile(
                  title: const Text("🩹 선택된 증상 보기"),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: selectedSymptoms
                            .map((s) => Chip(label: Text(s)))
                            .toList(),
                      ),
                    ),
                  ],
                ),

                // ✅ 문진 내역 보기
                ExpansionTile(
                  title: const Text("📋 문진 내역 전체 보기"),
                  children: questionHistory.entries.map((e) {
                    return ListTile(
                      title: Text(e.key),
                      subtitle: Text(
                        e.value ?? "응답 없음",
                        style: const TextStyle(color: Colors.black87),
                      ),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 30),

                // ✅ 버튼 영역
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => HomeBackground()),
                          (route) => false,
                    );
                  },
                  icon: const Icon(Icons.home_outlined, color: Colors.white),
                  label: const Text("홈으로 돌아가기",
                      style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    minimumSize: const Size(double.infinity, 50),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
