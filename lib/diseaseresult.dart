import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'RefinedDiseasePage.dart';

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
    아래 리스트는 의학 데이터베이스에 저장된 위험 요인, 과거 질환 이력, 사회적 요인입니다.
    환자에게 이해하기 쉽게 짧은 질문으로 바꿔주세요.
    반드시 질문문으로 출력하고, 각 항목마다 "원본:질문" 형식으로 줄바꿈하여 출력해주세요.

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
          questionToDiseases: questionToDiseases, // ✅ 매핑 전달
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("질병 결과")),
      body: const Center(child: CircularProgressIndicator()),
    );
  }
}
