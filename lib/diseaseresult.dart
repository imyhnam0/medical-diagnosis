import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:lottie/lottie.dart';
import 'RefinedDiseasePage.dart';

class DiseaseResultPage extends StatefulWidget {
  final List<String> selectedSymptoms;
  final String userInput;

  const DiseaseResultPage({
    super.key,
    required this.selectedSymptoms,
    required this.userInput,
  });

  @override
  State<DiseaseResultPage> createState() => _DiseaseResultPageState();
}

class _DiseaseResultPageState extends State<DiseaseResultPage> {
  final String apiKey = "AIzaSyCIYlmRYTOdfi_qOtcxHlp046oqZC-3uPI"; // 🔑 Gemini API 키 넣기
  bool isLoading = true;
  bool isFinished = false;
  Map<String, double> prevProbabilities = {};

  List<Map<String, dynamic>> candidateDiseases = [];
  Map<String, double> diseaseProbabilities = {};
  String? currentQuestion;
  String? finalDisease;
  int currentStep = 0;
  List<Map<String, String>> questionHistory = [];

  @override
  void initState() {
    super.initState();
    _initializeDiagnosis();
  }

  // ✅ 초기 진단 데이터 로딩 (개선 버전)
  Future<void> _initializeDiagnosis() async {
    final snapshot = await FirebaseFirestore.instance.collection("diseases_ko").get();

    final matches = snapshot.docs.where((doc) {
      final data = doc.data();
      final symptoms = List<String>.from(data["증상"] ?? []);
      return widget.selectedSymptoms.any((s) => symptoms.contains(s));
    }).map((doc) {
      final d = doc.data();
      return {
        "질환명": d["질환명"],
        "과거 질환 이력": List<String>.from(d["과거 질환 이력"] ?? []),
        "사회적 이력": List<String>.from(d["사회적 이력"] ?? []),
        "악화 요인": List<String>.from(d["악화 요인"] ?? []),
        "위험 요인": List<String>.from(d["위험 요인"] ?? []),
      };
    }).toList();

    candidateDiseases = matches;

    // 초기 확률 균등 분포
    for (var d in candidateDiseases) {
      diseaseProbabilities[d["질환명"]] = 1 / candidateDiseases.length;
    }

    // 첫 질문 생성
    await _generateNextQuestion();
    setState(() => isLoading = false);
  }
  List<Map<String, dynamic>> _getTopPercentDiseases({double percent = 0.3}) {
    final sorted = diseaseProbabilities.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final count = (sorted.length * percent).ceil().clamp(1, sorted.length);
    final topKeys = sorted.take(count).map((e) => e.key).toSet();

    return candidateDiseases
        .where((d) => topKeys.contains(d["질환명"]))
        .toList();
  }



  // ✅ Gemini를 통한 질문 생성
  Future<void> _generateNextQuestion() async {
    currentStep++;

    late final List<Map<String, dynamic>> focusedCandidates;

    if (currentStep <= 5) {
      // 🔹 질문 1~5: 전체 후보 사용
      focusedCandidates = candidateDiseases;
    } else if (currentStep == 6) {
      // 🔹 질문 6: 확률 상위 30% 질병만 필터링
      focusedCandidates = _getTopPercentDiseases(percent: 0.3);
    } else {
      // 🔹 질문 7부터: 확률이 오른 질병만 사용
      focusedCandidates = _getIncreasedDiseases();
    }

    // 🔹 Firestore에서 불러온 각 질병의 세부 요인들을 카테고리별로 구조화
    final remainingDiseasesText = focusedCandidates.map((d) {
      final name = d["질환명"];
      final past = (d["과거 질환 이력"] ?? []).join(", ");
      final social = (d["사회적 이력"] ?? []).join(", ");
      final aggravating = (d["악화 요인"] ?? []).join(", ");
      final risk = (d["위험 요인"] ?? []).join(", ");
      return """
- $name  
  • 과거 질환 이력: $past  
  • 사회적 이력: $social  
  • 악화 요인: $aggravating  
  • 위험 요인: $risk
  """;
    }).join("\n");

    final askedTopics = questionHistory.map((q) => q["question"]).join(", ");

    final prompt = """
당신은 전문 의사입니다. 아래는 환자의 증상, 현재까지 남은 질병 후보들, 그리고 각 요인에 따라 분류된 질병 그룹입니다.

[환자 증상]
${widget.selectedSymptoms.join(", ")}

[남은 질병 후보 데이터]
$remainingDiseasesText

이전 질문 및 답변:
${questionHistory.map((q) => "Q: ${q["question"]} → A: ${q["answer"]}").join("\n")}

위 질문들에서 이미 다루어진 주제($askedTopics)와 같은 의미나 단어를 절대 반복하지 마세요.

다음 조건을 반드시 지키세요:
1️⃣ 이전 질문에서 이미 다룬 내용은 다시 묻지 않는다.  
2️⃣ 남은 질병들의 차이점을 기반으로 ‘새로운 구분 요인’을 찾아 질문한다.  
3️⃣ 질문은 예/아니오로 대답 가능해야 한다.  
4️⃣ 한 문장만 출력한다.

출력 예시:
"최근에 식후에 통증이 심해지나요?"  
"황달 증상이 있나요?"
""";

    final res = await http.post(
      Uri.parse("https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent"),
      headers: {
        "Content-Type": "application/json",
        "X-goog-api-key": apiKey,
      },
      body: jsonEncode({
        "contents": [
          {"parts": [{"text": prompt}]}
        ]
      }),
    );

    final data = jsonDecode(res.body);
    final text = data["candidates"][0]["content"]["parts"][0]["text"].trim();

// ✅ 같은 질문이거나, 유사한 의미면 다시 요청
    if (questionHistory.any((q) => q["question"]?.trim() == text.trim())) {
      print("⚠️ 중복 질문 감지 → 다시 요청");
      await _generateNextQuestion();
      return;
    }


    setState(() => currentQuestion = text);

  }
  List<Map<String, dynamic>> _getIncreasedDiseases() {
    final increasedKeys = diseaseProbabilities.entries.where((e) {
      final prev = prevProbabilities[e.key] ?? 0;
      return e.value > prev; // 🔼 이전보다 확률이 상승한 질병만
    }).map((e) => e.key).toSet();

    final filtered = candidateDiseases
        .where((d) => increasedKeys.contains(d["질환명"]))
        .toList();

    // 🔁 상승한 질병이 하나도 없으면 전체 후보 유지
    return filtered.isEmpty ? candidateDiseases : filtered;
  }


  // ✅ 확률 업데이트 (Softmax 스타일, 필드 구분 반영)
  void _updateProbabilities(bool isYes) {
    const double alpha = 1.25; // 반응 민감도
    const double decay = 0.9; // 불일치시 감쇠율

    for (var d in candidateDiseases) {
      final name = d["질환명"];

      // 🔹 네 가지 요인 모두 합쳐서 하나의 리스트로
      final allFactors = [
        ...List<String>.from(d["과거 질환 이력"] ?? []),
        ...List<String>.from(d["사회적 이력"] ?? []),
        ...List<String>.from(d["악화 요인"] ?? []),
        ...List<String>.from(d["위험 요인"] ?? []),
      ];

      final hasRelation = allFactors.any((f) => currentQuestion!.contains(f));

      if (hasRelation) {
        diseaseProbabilities[name] =
            (diseaseProbabilities[name]! * (isYes ? alpha : decay))
                .clamp(0.001, 1.0);
      } else {
        diseaseProbabilities[name] =
            (diseaseProbabilities[name]! * (isYes ? decay : alpha))
                .clamp(0.001, 1.0);
      }
    }

    // 🔹 확률 정규화
    final total = diseaseProbabilities.values.reduce((a, b) => a + b);
    diseaseProbabilities.updateAll((k, v) => v / total);
  }


  Future<void> _handleAnswer(bool? isYes) async {
    if (currentQuestion == null) return;

    // ✅ 기록에는 "모르겠어요"도 포함
    questionHistory.add({
      "question": currentQuestion!,
      "answer": isYes == null ? "모르겠어요" : (isYes ? "예" : "아니오"),
    });

    // ✅ 모르겠어요면 확률 업데이트 생략
    if (isYes != null) {
      prevProbabilities = Map<String, double>.from(diseaseProbabilities);
      _updateProbabilities(isYes);
    }

    final top = diseaseProbabilities.entries.reduce(
          (a, b) => a.value > b.value ? a : b,
    );

    if (top.value >= 0.8 || currentStep >= 10) {
      setState(() {
        isFinished = true;
        finalDisease = top.key;
      });

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => RefinedDiseasePage(
            predictedDisease: finalDisease ?? "알 수 없음",
            userInput: widget.userInput,
            selectedSymptoms: widget.selectedSymptoms,
            questionHistory: questionHistory,
          ),
        ),
      );
      return;
    }

    await _generateNextQuestion();
    setState(() {});
  }



  // ✅ 질문 UI
  Widget _buildQuestionUI() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Lottie.asset("assets/medical_loading.json", width: 120),
            const SizedBox(height: 30),
            Text(
              currentQuestion ?? "질문 생성 중...",
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 40),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () => _handleAnswer(true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text("예", style: TextStyle(fontSize: 18)),
                ),
                ElevatedButton(
                  onPressed: () => _handleAnswer(false),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text("아니오", style: TextStyle(fontSize: 18)),
                ),
                ElevatedButton(
                  onPressed: () => _handleAnswer(null), // ✅ null로 처리
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey,
                    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text("모르겠어요", style: TextStyle(fontSize: 18)),
                ),

              ],
            ),
            const SizedBox(height: 50),
            LinearProgressIndicator(
              value: currentStep / 10,
              backgroundColor: Colors.grey.shade200,
              color: Colors.blueAccent,
              minHeight: 8,
              borderRadius: BorderRadius.circular(8),
            ),
            const SizedBox(height: 10),
            Text("진단 진행도: $currentStep / 10",
                style: const TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("AI 질병 추론", style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF1E3C72),
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
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : _buildQuestionUI(),

      ),
    );
  }
}
