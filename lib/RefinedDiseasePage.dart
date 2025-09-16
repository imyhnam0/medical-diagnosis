import 'package:flutter/material.dart';

class RefinedDiseasePage extends StatefulWidget {
  final List<Map<String, dynamic>> diseases;

  const RefinedDiseasePage({super.key, required this.diseases});

  @override
  State<RefinedDiseasePage> createState() => _RefinedDiseasePageState();
}

class _RefinedDiseasePageState extends State<RefinedDiseasePage> {
  final Set<String> selectedWorseningFactors = {};
  final Set<String> selectedHistory = {};
  final Set<String> selectedSocial = {};

  bool stepWorsening = true;
  bool stepHistory = false;
  bool stepSocial = false;
  bool stepResult = false;

  // ✅ 최종 점수 저장
  Map<String, int> scores = {};

  @override
  void initState() {
    super.initState();
    // ✅ 초기 점수는 모든 질환에 대해 1점
    for (var d in widget.diseases) {
      scores[d["질환명"] as String] = 1;
    }
  }

  // ✅ 선택한 요인 점수 추가 (2점씩)
  void applyScoring(Set<String> selected, String fieldName) {
    for (var d in widget.diseases) {
      final factors = List<String>.from(d[fieldName] ?? []);
      if (selected.any((s) => factors.contains(s))) {
        final name = d["질환명"] as String;
        scores[name] = (scores[name] ?? 0) + 2;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (stepWorsening) {
      return buildSelectionScreen(
        title: "악화 요인 선택",
        options: widget.diseases
            .expand((d) => List<String>.from(d["악화 요인"] ?? []))
            .toSet()
            .toList(),
        selected: selectedWorseningFactors,
        onNext: () {
          applyScoring(selectedWorseningFactors, "악화 요인");
          setState(() {
            stepWorsening = false;
            stepHistory = true;
          });
        },
      );
    }

    if (stepHistory) {
      return buildSelectionScreen(
        title: "과거 질환 이력 선택",
        options: widget.diseases
            .expand((d) => List<String>.from(d["과거 질환 이력"] ?? []))
            .toSet()
            .toList(),
        selected: selectedHistory,
        onNext: () {
          applyScoring(selectedHistory, "과거 질환 이력");
          setState(() {
            stepHistory = false;
            stepSocial = true;
          });
        },
      );
    }

    if (stepSocial) {
      return buildSelectionScreen(
        title: "사회적 이력 선택",
        options: widget.diseases
            .expand((d) => List<String>.from(d["사회적 이력"] ?? []))
            .toSet()
            .toList(),
        selected: selectedSocial,
        onNext: () {
          applyScoring(selectedSocial, "사회적 이력");
          setState(() {
            stepSocial = false;
            stepResult = true;
          });
        },
      );
    }

    if (stepResult) {
      // ✅ 최종 결과: 점수를 퍼센트로 변환 + 내림차순 정렬
      final totalScore = scores.values.fold<int>(0, (a, b) => a + b);
      final result = scores.entries.map((e) {
        final percent = totalScore > 0 ? (e.value / totalScore * 100).toStringAsFixed(1) : "0";
        return {"질환명": e.key, "점수": e.value, "퍼센트": percent};
      }).toList();

      result.sort((a, b) => (b["점수"] as int).compareTo(a["점수"] as int));

      return Scaffold(
        appBar: AppBar(
          title: const Text("최종 후보 질환"),
          centerTitle: true,
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF1E3C72), Color(0xFF2A5298)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          foregroundColor: Colors.white,
        ),
        body: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: result.length,
          itemBuilder: (context, index) {
            final r = result[index];
            return Card(
              elevation: 4,
              margin: const EdgeInsets.symmetric(vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      r["질환명"] as String,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: double.tryParse(r["퍼센트"].toString())! / 100,
                      minHeight: 8,
                      borderRadius: BorderRadius.circular(8),
                      backgroundColor: Colors.grey[300],
                      valueColor: AlwaysStoppedAnimation<Color>(
                        index == 0 ? Colors.redAccent : Colors.blueAccent,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text("점수: ${r["점수"]}, 확률: ${r["퍼센트"]}%"),
                  ],
                ),
              ),
            );
          },
        ),
      );
    }

    return const SizedBox.shrink();
  }

  // ✅ 공통 선택 화면
  Widget buildSelectionScreen({
    required String title,
    required List<String> options,
    required Set<String> selected,
    required VoidCallback onNext,
  }) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF1E3C72), Color(0xFF2A5298)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: options.map((opt) {
          return Card(
            elevation: 2,
            margin: const EdgeInsets.symmetric(vertical: 6),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: CheckboxListTile(
              title: Text(opt),
              value: selected.contains(opt),
              activeColor: Colors.blueAccent,
              onChanged: (checked) {
                setState(() {
                  if (checked!) {
                    selected.add(opt);
                  } else {
                    selected.remove(opt);
                  }
                });
              },
            ),
          );
        }).toList(),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton.icon(
            onPressed: onNext,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueAccent,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              elevation: 4,
            ),
            icon: const Icon(Icons.navigate_next, color: Colors.white),
            label: const Text(
              "다음",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ),
        ),
      ),
    );
  }
}
