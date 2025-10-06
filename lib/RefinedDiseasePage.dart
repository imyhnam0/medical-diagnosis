import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:lottie/lottie.dart';
import 'main.dart';
import 'ChatConsultPage.dart';

class RefinedDiseasePage extends StatefulWidget {
  final List<Map<String, dynamic>> diseases;
  final Map<String, List<String>> questionToDiseases;

  const RefinedDiseasePage({
    super.key,
    required this.diseases,
    required this.questionToDiseases,
  });

  @override
  State<RefinedDiseasePage> createState() => _RefinedDiseasePageState();
}

class _RefinedDiseasePageState extends State<RefinedDiseasePage> {
  late Set<String> candidateDiseases;
  late Set<String> remainingQuestions;

  String? currentQuestion;
  bool started = false;

  @override
  void initState() {
    super.initState();
    candidateDiseases = widget.diseases
        .map((e) => (e["질환명"] ?? e["name"] ?? "").toString())
        .where((s) => s.isNotEmpty)
        .toSet();

    remainingQuestions = widget.questionToDiseases.keys.toSet();
  }


  String? _pickNextQuestion() {
    final candidates = remainingQuestions
        .where((q) => widget.questionToDiseases[q]!
        .any(candidateDiseases.contains))
        .toList();

    if (candidates.isEmpty) return null;

    String bestQ = candidates.first;
    int bestScore = 1 << 30;

    for (final q in candidates) {
      final yesCount = widget.questionToDiseases[q]!
          .where(candidateDiseases.contains)
          .length;
      final noCount = candidateDiseases.length - yesCount;
      final diff = (yesCount - noCount).abs();

      if (diff < bestScore) {
        bestScore = diff;
        bestQ = q;
      }
    }
    return bestQ;
  }

  void _nextQuestion() {
    setState(() {
      currentQuestion = _pickNextQuestion();
      if (currentQuestion == null) {
        _showResult();
      }
    });
  }

  void _answer(bool? yes) {
    if (currentQuestion == null) return;
    final affected = widget.questionToDiseases[currentQuestion]!.toSet();

    setState(() {
      if (yes == true) {
        candidateDiseases = candidateDiseases.intersection(affected);
      } else if (yes == false) {
        candidateDiseases.removeAll(affected);
      }
      remainingQuestions.remove(currentQuestion);
      currentQuestion = null;

      // ✅ 남은 질환 없으면 종료
      if (candidateDiseases.isEmpty) {
        _showResult(message: "조건에 맞는 질환이 없습니다.");
        return;
      }

      // ✅ 남은 질문이 없을 때 처리
      if (remainingQuestions.isEmpty) {
        // 여러 질병이 남았을 때 → 하나만 무작위 선택
        if (candidateDiseases.length > 1) {
          final singleDisease = candidateDiseases.first;
          candidateDiseases = {singleDisease};
        }
        _showResult(); // 무조건 하나만 보여주기
        return;
      }

      // ✅ 하나 남으면 바로 결과 출력
      if (candidateDiseases.length == 1) {
        _showResult();
        return;
      }

      // ✅ 계속 질문
      _nextQuestion();
    });
  }

  Future<void> _showResult({String? message}) async {
    String diseaseText = candidateDiseases.join(", ");
    String description = "";

    // ✅ 1️⃣ 로딩 다이얼로그 표시
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Center(
        child: Container(
          width: 200,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Lottie.asset(
                "assets/medical_loading.json",
                width: 120,
                height: 120,
                repeat: true,
              ),
              const SizedBox(height: 16),
              const Text(
                "AI가 분석 중입니다...",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1E3C72),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    // ✅ 2️⃣ Gemini API 호출
    if (candidateDiseases.isNotEmpty) {
      final prompt = """
당신은 전문 의료 해설가입니다.
다음 질환에 대해 일반인이 이해하기 쉬운 형태로 설명을 작성해주세요.

형식:
1️⃣ 질병 개요 (무엇인지, 왜 생기는지)
2️⃣ 주요 원인
3️⃣ 주요 증상
4️⃣ 진단 및 치료 방법
5️⃣ 주의할 점 / 예후

질병: $diseaseText
""";

      final response = await http.post(
        Uri.parse("https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent"),
        headers: {
          "Content-Type": "application/json",
          "X-goog-api-key": "AIzaSyCIYlmRYTOdfi_qOtcxHlp046oqZC-3uPI",
        },
        body: jsonEncode({
          "contents": [
            {
              "parts": [
                {"text": prompt}
              ]
            }
          ]
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        description = data["candidates"][0]["content"]["parts"][0]["text"].trim();
      } else {
        description = "⚠️ 질병 설명을 불러오지 못했습니다. (API 오류)";
      }
    }

    // ✅ 3️⃣ 로딩 닫기
    if (mounted) Navigator.pop(context);

    // ✅ 4️⃣ 결과 다이얼로그 표시
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) {
        return Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFEDF3FF), Color(0xFFFFFFFF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.all(Radius.circular(25)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 상단 아이콘 + 제목
                Center(
                  child: Column(
                    children: const [
                      Icon(Icons.medical_information,
                          color: Color(0xFF1E3C72), size: 40),
                      SizedBox(height: 10),
                      Text(
                        "AI 분석 결과",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E3C72),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // ✅ 예상 질환 표시
                Center(
                  child: Text(
                    "예상 질환 : $diseaseText",
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1E3C72),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),

                const SizedBox(height: 16),
                const Divider(thickness: 1, color: Colors.black12),
                const SizedBox(height: 16),

                // ✅ 설명 본문 (스크롤 가능)
                Expanded(
                  child: SingleChildScrollView(
                    child: Text(
                      message ??
                          (description.isNotEmpty
                              ? description
                              : "AI가 결과를 불러오는 중입니다..."),
                      style: const TextStyle(
                        fontSize: 15,
                        height: 1.6,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      // 다이얼로그 닫고 메인 페이지로 이동
                      Navigator.pop(context); // 1️⃣ 다이얼로그 닫기
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => HomeBackground()),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E3C72),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      padding:
                      const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                    ),
                    icon: const Icon(Icons.check, color: Colors.white),
                    label: const Text(
                      "확인",
                      style: TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    icon: const Icon(Icons.chat_bubble_outline, color: Color(0xFF1E3C72)),
                    label: const Text("AI에게 후속 질문하기"),
                    onPressed: () {
                      Navigator.pop(context); // 다이얼로그 닫기
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ChatConsultPage(diseaseName: diseaseText),
                        ),
                      );
                    },
                  ),
                ),

              ],
            ),
          ),
        );
      },
    );
  }




  @override
  Widget build(BuildContext context) {
    final primary = Colors.blue[700];

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E3C72),
        title: const Text(
          "증상 설문",
          style: TextStyle(fontWeight: FontWeight.bold,color: Colors.white),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: !started
              ? Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.health_and_safety,
                  size: 100, color: Colors.blue),
              const SizedBox(height: 20),
              const Text(
                "증상에 대해 몇 가지 질문을 드릴게요.\n예/아니오로 답해주세요.",
                textAlign: TextAlign.center,
                style:
                TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: () {
                  setState(() => started = true);
                  _nextQuestion();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E3C72),
                  padding: const EdgeInsets.symmetric(
                      vertical: 14, horizontal: 40),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text("확인",
                    style: TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
              )
            ],
          )
              : Card(
            elevation: 6,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20)),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    currentQuestion ?? "모든 질문이 끝났습니다.",
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 40),
                  // 예/아니오/모르겠어요 버튼 (질문 화면)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _answerBtn("예", Colors.blue[700]!, () => _answer(true)),
                      _answerBtn("아니오", Colors.teal[400]!, () => _answer(false)),
                      _answerBtn("모르겠어요", Colors.grey[600]!, () => _answer(null), outlined: true),
                    ],
                  ),

                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _answerBtn(String text, Color color, VoidCallback onPressed,
      {bool outlined = false}) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: outlined
            ? OutlinedButton(
          onPressed: onPressed,
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14)),
            side: BorderSide(color: color, width: 2),
          ),
          child: Text(
            text,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color, // ⚡ "모르겠어요"는 원래 색
            ),
          ),
        )
            : ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14)),
            elevation: 2,
          ),
          child: Text(
            // ⚡ 예/아니오는 항상 흰색 글씨
            text,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}
