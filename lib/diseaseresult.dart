import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'RefinedDiseasePage.dart';
import 'package:lottie/lottie.dart';

class DiseaseResultPage extends StatefulWidget {
  final List<String> selectedSymptoms;

  const DiseaseResultPage({super.key, required this.selectedSymptoms});

  @override
  State<DiseaseResultPage> createState() => _DiseaseResultPageState();
}

class _DiseaseResultPageState extends State<DiseaseResultPage> {
  List<Map<String, dynamic>> diseases = [];
  Map<String, List<String>> questionToDiseases = {}; // ✅ 질문 ↔ 질병 매핑

  // ✅ 중복 제거된 리스트 저장
  Set<String> pastHistories = {};
  Set<String> socialHistories = {};
  Set<String> aggravatingFactors = {};

  // ✅ factor → 관련 질병 매핑
  Map<String, Set<String>> factorToDiseases = {};

  @override
  void initState() {
    super.initState();
    fetchMatchingDiseases();
  }

  /// ✅ LLM API를 통해 사용자 친화적 질문으로 변환
  Future<Map<String, String>> generateQuestions(Set<String> items) async {
    if (items.isEmpty) return {};

    final prompt = """
    당신은 임상 문진용 질문을 작성하는 의료 전문 어시스턴트입니다.  
    아래 리스트는 질병 데이터베이스에 포함된 3가지 요인 카테고리에 속한 항목들입니다.  
    각 항목은 환자의 상태를 평가하기 위한 근거로 사용됩니다.
    
    - "악화 요인" 항목은 증상이 악화되는 상황을 의미합니다.  
      → 질문 예시: "스트레스" → "스트레스를 받을 때 증상이 더 심해지시나요?"  
      → "추위" → "추운 날씨에 증상이 심해지나요?"
    
    - "사회적 이력" 항목은 생활습관이나 환경적 요인을 의미합니다.  
      → 질문 예시: "수면 부족" → "평소에 수면이 부족하신가요?"  
      → "정서적 스트레스" → "정서적으로 스트레스를 자주 느끼시나요?"
    
    - "과거 질환 이력" 항목은 과거에 진단받거나 앓았던 질병을 의미합니다.  
      → 질문 예시: "우울증" → "과거에 우울증을 앓은 적이 있나요?"  
      → "만성 피로 증후군" → "이전에 만성 피로 증후군 진단을 받은 적이 있나요?"
    
    아래 리스트의 각 항목을 보고, 위의 맥락에 맞게 환자에게 실제로 문진 시 사용할 수 있는  
    짧고 자연스러운 한국어 질문문으로 변환하세요.  
    질문은 반드시 예/아니오로 대답할 수 있어야 합니다.
    
    출력 형식:
    "원본항목:변환된 질문"  
    각 항목은 줄바꿈으로 구분해주세요.
    
    항목:
    ${items.join("\n")}
    """;


    final response = await http.post(
      Uri.parse("https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent"),
      headers: {
        "Content-Type": "application/json",
        "X-goog-api-key": "AIzaSyCIYlmRYTOdfi_qOtcxHlp046oqZC-3uPI", // 🔑 본인 API 키로 교체
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
      final rawText =
      data["candidates"][0]["content"]["parts"][0]["text"].trim();

      // "원본:질문" 형식 → Map 변환
      final Map<String, String> factorToQuestion = {};
      for (var line in rawText.split("\n")) {
        if (line.contains(":")) {
          final parts = line.split(":");
          if (parts.length >= 2) {
            final original = parts[0].trim();
            final question = parts.sublist(1).join(":").trim();
            factorToQuestion[original] = question;
          }
        }
      }

      print("✅ 생성된 질문 개수: ${factorToQuestion.length}");
      return factorToQuestion;
    } else {
      print("⚠️ API Error: ${response.body}");
      return {};
    }
  }

  Future<void> fetchMatchingDiseases() async {
    final firestore = FirebaseFirestore.instance;
    final snapshot = await firestore.collection("diseases_ko").get();

    // ✅ 선택된 증상 중 하나라도 포함된 질환만 가져오기
    final matches = snapshot.docs
        .where((doc) {
      final data = doc.data();
      final diseaseSymptoms = List<String>.from(data["증상"] ?? []);
      return widget.selectedSymptoms
          .any((symptom) => diseaseSymptoms.contains(symptom));
    })
        .map((doc) => doc.data())
        .toList();

    // ✅ factor → disease 매핑
    for (var disease in matches) {
      final name = disease["질환명"] ?? "이름 없음";

      for (var factor in List<String>.from(disease["과거 질환 이력"] ?? [])) {
        pastHistories.add(factor);
        factorToDiseases.putIfAbsent(factor, () => {}).add(name);
      }
      for (var factor in List<String>.from(disease["사회적 이력"] ?? [])) {
        socialHistories.add(factor);
        factorToDiseases.putIfAbsent(factor, () => {}).add(name);
      }
      for (var factor in List<String>.from(disease["악화 요인"] ?? [])) {
        aggravatingFactors.add(factor);
        factorToDiseases.putIfAbsent(factor, () => {}).add(name);
      }
    }

    print("📌 과거 질환 이력 개수: ${pastHistories.length}");
    print("📌 사회적 이력 개수: ${socialHistories.length}");
    print("📌 악화 요인 개수: ${aggravatingFactors.length}");

    // ✅ LLM을 이용해 질문 변환
    final allFactors = {
      ...pastHistories,
      ...socialHistories,
      ...aggravatingFactors
    };
    final factorToQuestion = await generateQuestions(allFactors);

    // ✅ 질문 ↔ 질병 매핑 생성
    final Map<String, List<String>> qToDiseases = {};
    factorToQuestion.forEach((factor, question) {
      final related = factorToDiseases[factor]?.toList() ?? [];
      qToDiseases[question] = related;
    });

    setState(() {
      diseases = matches;
      questionToDiseases = qToDiseases;
    });

    // 🔍 Debug 출력
    questionToDiseases.forEach((q, ds) {
      print("❓ $q → ${ds.join(", ")}");
    });

    // ✅ 질문까지 생성되면 바로 다음 페이지로 이동
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => RefinedDiseasePage(
          diseases: diseases,
          questionToDiseases: questionToDiseases,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          backgroundColor: const Color(0xFF1E3C72),
          title: const Text(
            "질병 결과",
            style: TextStyle(color: Colors.white),
          ),
        ),
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF90CAF9), Color(0xFFE3F2FD)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Center(
            child: Card(
              elevation: 6,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: Padding(
                padding: const EdgeInsets.all(30),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Lottie.asset(
                      "assets/medical_loading.json",
                      width: 120,
                      height: 120,
                      repeat: true,
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      "결과를 분석하는 중입니다...",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ),
          ),
        )

    );
  }
}
