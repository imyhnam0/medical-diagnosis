import 'package:flutter/material.dart';

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

      if (candidateDiseases.isEmpty) {
        _showResult(message: "조건에 맞는 질환이 없습니다.");
      } else if (candidateDiseases.length <= 3 || remainingQuestions.isEmpty) {
        _showResult();
      } else {
        _nextQuestion();
      }
    });
  }

  void _showResult({String? message}) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          "예상 후보 질환",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        content: message != null
            ? Text(message)
            : Wrap(
          spacing: 8,
          runSpacing: 8,
          children: candidateDiseases
              .map((d) => Chip(
            label: Text(d,
                style: const TextStyle(
                    fontWeight: FontWeight.w500)),
            backgroundColor: Colors.blue[100],
          ))
              .toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("닫기"),
          )
        ],
      ),
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
          child: const Text(
            // ⚡ 예/아니오는 항상 흰색 글씨
            '',
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
