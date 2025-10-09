import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:lottie/lottie.dart';
import 'main.dart';
import 'ChatConsultPage.dart';
import 'MedicalSummaryPage.dart';

class RefinedDiseasePage extends StatefulWidget {
  final String predictedDisease; // ✅ DiseaseResultPage에서 받은 질병 이름
  final String userInput;
  final List<String> selectedSymptoms;

  const RefinedDiseasePage({
    super.key,
    required this.predictedDisease,
    required this.userInput,
    required this.selectedSymptoms,
  });

  @override
  State<RefinedDiseasePage> createState() => _RefinedDiseasePageState();
}

class _RefinedDiseasePageState extends State<RefinedDiseasePage> {
  String? diseaseDescription;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchDiseaseDescription();
  }

  // ✅ Gemini로 질병 설명 불러오기
  Future<void> _fetchDiseaseDescription() async {
    final prompt = """
당신은 전문 의료 해설가입니다.
아래 질병에 대해 일반인이 이해하기 쉬운 해설을 작성하세요.

형식:
1️⃣ 질병 개요  
2️⃣ 주요 원인  
3️⃣ 주요 증상  
4️⃣ 진단 및 치료 방법  
5️⃣ 예후 및 주의사항

질병: ${widget.predictedDisease}
""";

    try {
      final res = await http.post(
        Uri.parse(
            "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent"),
        headers: {
          "Content-Type": "application/json",
          "X-goog-api-key": "AIzaSyCIYlmRYTOdfi_qOtcxHlp046oqZC-3uPI", // 🔑 실제 키로 교체
        },
        body: jsonEncode({
          "contents": [
            {"parts": [{"text": prompt}]}
          ]
        }),
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final text =
        data["candidates"][0]["content"]["parts"][0]["text"].trim();
        setState(() {
          diseaseDescription = text;
          isLoading = false;
        });
      } else {
        setState(() {
          diseaseDescription = "⚠️ 질병 설명을 불러오지 못했습니다. (API 오류)";
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        diseaseDescription = "⚠️ 네트워크 오류로 설명을 불러올 수 없습니다.";
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = const Color(0xFF1E3C72);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFE3F2FD), Color(0xFFBBDEFB)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: isLoading
              ? _buildLoadingUI()
              : SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(24),
            child: Card(
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(primaryColor),
                    const SizedBox(height: 20),
                    const Divider(thickness: 1.2),
                    const SizedBox(height: 10),
                    Text(
                      diseaseDescription ??
                          "AI가 질병 설명을 불러오는 중입니다...",
                      style: const TextStyle(
                        fontSize: 15,
                        height: 1.6,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 30),
                    const Divider(thickness: 1.2),
                    const SizedBox(height: 20),
                    _buildActionButtons(context, primaryColor),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ✅ 로딩 UI
  Widget _buildLoadingUI() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Lottie.asset("assets/medical_loading.json", width: 140),
            const SizedBox(height: 24),
            const Text(
              "AI가 질병 정보를 분석 중입니다...",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ✅ 상단 헤더
  Widget _buildHeader(Color primaryColor) {
    return Center(
      child: Column(
        children: [
          Lottie.asset("assets/medical_done.json", width: 130, repeat: false),
          const SizedBox(height: 12),
          Text(
            "AI 분석 결과",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: primaryColor,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            "예상 질병: ${widget.predictedDisease}",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: primaryColor,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ✅ 버튼 3개
  Widget _buildActionButtons(BuildContext context, Color primaryColor) {
    return Column(
      children: [
        ElevatedButton.icon(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ChatConsultPage(
                  diseaseName: widget.predictedDisease,
                ),
              ),
            );
          },
          icon: const Icon(Icons.chat_bubble_outline, color: Colors.white),
          label: const Text(
            "AI에게 후속 질문하기",
            style: TextStyle(color: Colors.white),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            minimumSize: const Size(double.infinity, 50),
          ),
        ),
        const SizedBox(height: 14),
        ElevatedButton.icon(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => MedicalSummaryPage(
                  userInput: widget.userInput,
                  selectedSymptoms: widget.selectedSymptoms,
                  answers: const {},
                  predictedDisease: widget.predictedDisease,
                ),
              ),
            );
          },
          icon: const Icon(Icons.assignment_outlined, color: Colors.white),
          label: const Text(
            "문진표 보기",
            style: TextStyle(color: Colors.white),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.indigo,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            minimumSize: const Size(double.infinity, 50),
          ),
        ),
        const SizedBox(height: 14),
        OutlinedButton.icon(
          onPressed: () {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => HomeBackground()),
                  (route) => false,
            );
          },
          icon: const Icon(Icons.home_outlined, color: Color(0xFF1E3C72)),
          label: const Text(
            "홈으로 돌아가기",
            style: TextStyle(color: Color(0xFF1E3C72)),
          ),
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: Color(0xFF1E3C72), width: 2),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            minimumSize: const Size(double.infinity, 50),
          ),
        ),
      ],
    );
  }
}
