import 'package:flutter/material.dart';

class RefinedDiseasePage extends StatefulWidget {
  final List<Map<String, dynamic>> diseases;
  final Map<String, List<String>> questionToDiseases; // 질문 ↔ 질병 매핑

  const RefinedDiseasePage({
    super.key,
    required this.diseases,
    required this.questionToDiseases,
  });

  @override
  State<RefinedDiseasePage> createState() => _RefinedDiseasePageState();
}

class _RefinedDiseasePageState extends State<RefinedDiseasePage> {
  int currentPage = 0; // 현재 페이지 (10개씩 나눔)
  final Set<String> answeredQuestions = {}; // ✅ 체크된 질문
  Map<String, int> diseaseScores = {}; // ✅ 질병별 점수

  @override
  void initState() {
    super.initState();
    // 초기 점수 0으로 설정
    for (var disease in widget.diseases) {
      final name = disease["질환명"] ?? "이름 없음";
      diseaseScores[name] = 0;
    }
  }

  /// ✅ 전체 질문 리스트 (순서 고정)
  List<String> get allQuestions => widget.questionToDiseases.keys.toList();

  /// ✅ 현재 페이지의 질문 10개만 가져오기
  List<String> get currentQuestions {
    final start = currentPage * 10;
    final end = (start + 10).clamp(0, allQuestions.length);
    return allQuestions.sublist(start, end);
  }

  /// ✅ 체크 이벤트
  void toggleAnswer(String question, bool checked) {
    setState(() {
      if (checked) {
        answeredQuestions.add(question);
        // 질문과 연결된 질병 점수 올리기
        for (var disease in widget.questionToDiseases[question] ?? []) {
          diseaseScores[disease] = (diseaseScores[disease] ?? 0) + 1;
        }
      } else {
        answeredQuestions.remove(question);
        // 체크 해제 시 점수 차감
        for (var disease in widget.questionToDiseases[question] ?? []) {
          diseaseScores[disease] = (diseaseScores[disease] ?? 0) - 1;
        }
      }
    });
  }

  /// ✅ 다음 페이지로 이동
  void goToNextPage() {
    if ((currentPage + 1) * 10 >= allQuestions.length) {
      // 마지막 페이지 → 결과 보여주기
      showFinalResult();
    } else {
      setState(() {
        currentPage++;
      });
    }
  }

  /// ✅ 최종 결과 계산
  void showFinalResult() {
    final sorted = diseaseScores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topDisease = sorted.isNotEmpty ? sorted.first.key : "알 수 없음";

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.7, // 다이얼로그 최대 높이 제한
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 상단 아이콘 + 대표 질병
                  const Icon(Icons.health_and_safety,
                      color: Colors.redAccent, size: 48),
                  const SizedBox(height: 12),
                  Text(
                    "가장 가능성이 높은 질병",
                    style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    topDisease,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ✅ 질병 리스트 스크롤 가능하게 변경
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        children: sorted.map((e) {
                          final percentage = sorted.first.value == 0
                              ? 0.0
                              : e.value / sorted.first.value;
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "${e.key} (${e.value}점)",
                                  style: const TextStyle(fontSize: 14),
                                ),
                                const SizedBox(height: 4),
                                LinearProgressIndicator(
                                  value: percentage,
                                  minHeight: 8,
                                  backgroundColor: Colors.grey[300],
                                  color: e.key == topDisease
                                      ? Colors.redAccent
                                      : Colors.blueAccent,
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // 확인 버튼
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                    ),
                    child: const Text(
                      "확인",
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }



  @override
  Widget build(BuildContext context) {
    if (allQuestions.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text("질문 검사")),
        body: const Center(child: Text("질문이 없습니다.")),
      );
    }

    final progress = ((currentPage * 10) / allQuestions.length).clamp(0.0, 1.0);

    return Scaffold(
      appBar: AppBar(
        title: Text("질문 검사 (${currentPage + 1}/${(allQuestions.length / 10).ceil()})"),
      ),
      body: Column(
        children: [
          // 진행률 바
          LinearProgressIndicator(value: progress, minHeight: 6, backgroundColor: Colors.grey[300]),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: currentQuestions.length,
              itemBuilder: (context, index) {
                final q = currentQuestions[index];
                final checked = answeredQuestions.contains(q);

                return Card(
                  elevation: 3,
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  color: checked ? Colors.blue[50] : Colors.white,
                  child: ListTile(
                    leading: Icon(
                      checked ? Icons.check_circle : Icons.circle_outlined,
                      color: checked ? Colors.blue : Colors.grey,
                    ),
                    title: Text(
                      q,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: checked ? Colors.blue[900] : Colors.black,
                      ),
                    ),
                    onTap: () => toggleAnswer(q, !checked),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16),
        child: ElevatedButton(
          onPressed: goToNextPage,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: Text(
            (currentPage + 1) * 10 >= allQuestions.length ? "결과 보기" : "다음",
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
          ),
        ),
      ),
    );
  }
}
