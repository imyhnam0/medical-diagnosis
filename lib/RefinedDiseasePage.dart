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
    // 가장 점수가 높은 질병 찾기
    final sorted = diseaseScores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topDisease = sorted.isNotEmpty ? sorted.first.key : "알 수 없음";

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("최종 결과"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("가장 가능성이 높은 질병: $topDisease"),
              const SizedBox(height: 12),
              ...sorted.map((e) => Text("${e.key}: ${e.value}점")),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("확인"),
            )
          ],
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

    return Scaffold(
      appBar: AppBar(
        title: Text("질문 검사 (${currentPage + 1}/${(allQuestions.length / 10).ceil()})"),
      ),
      body: ListView(
        children: currentQuestions.map((q) {
          final checked = answeredQuestions.contains(q);
          return CheckboxListTile(
            title: Text(q),
            value: checked,
            onChanged: (val) {
              toggleAnswer(q, val ?? false);
            },
          );
        }).toList(),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: goToNextPage,
        label: Text(
          (currentPage + 1) * 10 >= allQuestions.length ? "결과 보기" : "다음",
        ),
        icon: const Icon(Icons.arrow_forward),
      ),
    );
  }
}
