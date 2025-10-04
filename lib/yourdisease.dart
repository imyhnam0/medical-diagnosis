//두번째 페이지

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'diseaseresult.dart';

class YourDiseasePage extends StatefulWidget {
  const YourDiseasePage({super.key});

  @override
  State<YourDiseasePage> createState() => _YourDiseasePageState();
}

class _YourDiseasePageState extends State<YourDiseasePage> {
  final Map<String, List<String>> symptomCategories = {
    "흉부 관련 증상": [
      "흉통", "협심증 유사 흉통", "갑작스러운 흉통", "설명되지 않는 흉통",
      "안정 시 흉통", "작열성 흉통", "흉골 뒤 압박감", "흉부 불편감",
      "흉부 압박감", "흉벽 통증", "흉벽 불편감", "늑골 압통",
      "방사통", "방사성 흉통"
    ],

    "호흡기 증상": [
      "호흡곤란", "가벼운 호흡곤란", "운동 시 호흡곤란",
      "야간 발작성 호흡곤란", "기침", "가래", "객혈",
      "마른기침", "흉막성 통증", "천명음"
    ],

    "심혈관/전신 증상": [
      "발열", "야간 발한", "피로", "전신 권태", "체중 감소",
      "두근거림", "실신", "어지럼증", "다리 부종"
    ],

    "소화기 증상": [
      "오심", "구토", "설사", "소화기 증상", "속쓰림", "역류",
      "연하곤란", "상복부 불편감", "명치 통증", "복부 불편감",
      "복부 팽만"
    ],

    "신경/근골격계 증상": [
      "목 통증", "등 통증", "등통증", "등/허리 통증",
      "관절통", "국소 근육통", "국소 통증", "근육통",
      "골통", "이질통", "작열통", "압통",
      "움직임 제한", "근력 약화", "팔 약화",
      "감각 이상", "저림", "전신 통증",
      "두개골/흉부 변형", "뻣뻣함", "통증"
    ],

    "피부/감각 증상": [
      "발진", "작열감", "가려움", "유방 멍울", "멍"
    ],

    "신경/인지 기능 증상": [
      "시각 증상", "수면 문제"
    ],

    "정신/심리 증상": [
      "건강 불안", "신체 증상에 대한 집착", "걱정", "플래시백"
    ],

    "여성 생식 관련 증상": [
      "골반 통증", "생리 문제"
    ],

    "기타/기온 반응 관련 증상": [
      "우상복부 통증", "측두부 통증", "설명되지 않는 다발성 증상",
      "추위 불내성"
    ]
  };


  final Set<String> selectedSymptoms = {};
  final TextEditingController _controller = TextEditingController();

  Future<List<String>> _getMatchedSymptoms(String input) async {
    final allSymptoms = symptomCategories.values.expand((e) => e).toList();

    final prompt = """
      사용자가 입력한 문장을 증상 리스트와 비교해서,
      해당되는 모든 증상을 찾아주세요.
      출력은 반드시 증상 이름만 쉼표(,)로 구분된 리스트 형태로만 써주세요.
      
      사용자 입력: "$input"
      증상 리스트: ${allSymptoms.toString()}
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

      if (data["candidates"] != null &&
          data["candidates"].isNotEmpty &&
          data["candidates"][0]["content"] != null &&
          data["candidates"][0]["content"]["parts"] != null &&
          data["candidates"][0]["content"]["parts"].isNotEmpty) {
        final rawText = data["candidates"][0]["content"]["parts"][0]["text"].trim();

        // 쉼표 기준 분리 → 중복 제거
        final results = rawText.split(",").map((e) => e.trim()).toSet().toList();
        return List<String>.from(results);
      } else {
        print("⚠️ Gemini 응답 파싱 실패: ${response.body}");
        return <String>[];
      }
    } else {
      print("API Error: ${response.body}");
      return <String>[];
    }
  }
  void _showConfirmDialog(BuildContext context, List<String> matchedSymptoms) {
    final TextEditingController popupController = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: LinearGradient(
                    colors: [Colors.blue.shade50, Colors.white],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 제목 + 아이콘
                    Row(
                      children: const [
                        Icon(Icons.check_circle, color: Colors.blue, size: 28),
                        SizedBox(width: 8),
                        Text(
                          "증상 확인",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // 선택된 증상 리스트
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: selectedSymptoms.map((symptom) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              children: [
                                const Icon(Icons.check, color: Colors.blue, size: 18),
                                const SizedBox(width: 6),
                                Text(symptom, style: const TextStyle(fontSize: 15)),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),


                    const SizedBox(height: 16),

                    // 추가 입력창
                    TextField(
                      controller: popupController,
                      decoration: InputDecoration(
                        hintText: "추가 증상이 있나요?",
                        prefixIcon: const Icon(Icons.add_comment, color: Colors.blue),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.blue.shade200),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // 버튼 영역
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text(
                            "없습니다",
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 12),
                          ),
                          onPressed: () async {
                            final newInput = popupController.text.trim();
                            if (newInput.isNotEmpty) {
                              final newMatches = await _getMatchedSymptoms(newInput);
                              if (newMatches.isNotEmpty) {
                                setState(() {
                                  selectedSymptoms.addAll(newMatches);
                                });
                                setStateDialog(() {}); // 팝업 UI 갱신
                                popupController.clear();
                              }
                            }
                          },
                          child: const Text(
                            "추가 입력",
                            style: TextStyle(color: Colors.white, fontSize: 16),
                          ),
                        ),
                      ],
                    )
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }





  void _matchSymptoms(String input) async {
    if (input.trim().isEmpty) return;

    final matchedSymptoms = await _getMatchedSymptoms(input);

    if (matchedSymptoms.isNotEmpty) {
      setState(() {
        selectedSymptoms.addAll(matchedSymptoms);
      });

      _showConfirmDialog(context, matchedSymptoms); // ✅ 팝업 띄우기
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("증상을 매칭하지 못했습니다.")),
      );
    }

    _controller.clear();
  }



  Widget build(BuildContext context) {
    final primaryColor = Colors.blue;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        centerTitle: true,
        title: const Text("증상 입력 / 선택", style: TextStyle(fontWeight: FontWeight.bold,color: Colors.white,)),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            color: Color(0xFF1E3C72),
          ),
        ),
      ),
      body: Column(
        children: [
          // 입력창
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      hintText: "어떤 증상이 있으신가요?",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E3C72),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () => _matchSymptoms(_controller.text),
                  child: const Text("확인", style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ),
          // 증상 체크리스트
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: symptomCategories.entries.map((entry) {
                final hasSelected = entry.value.any((s) => selectedSymptoms.contains(s));

                return Card(
                  elevation: 4,
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: ExpansionTile(
                    leading: Icon(
                      hasSelected ? Icons.check_circle : Icons.circle_outlined,
                      color: hasSelected ? primaryColor : Colors.grey,
                    ),
                    title: Text(
                      entry.key,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: hasSelected ? primaryColor : Colors.black87,
                      ),
                    ),
                    children: entry.value.map((symptom) {
                      final isSelected = selectedSymptoms.contains(symptom);

                      return Container(
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.blue[50] : null,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: CheckboxListTile(
                          activeColor: primaryColor,
                          title: Text(symptom),
                          value: isSelected,
                          onChanged: (checked) {
                            setState(() {
                              if (checked!) {
                                selectedSymptoms.add(symptom);
                              } else {
                                selectedSymptoms.remove(symptom);
                              }
                            });
                          },
                        ),
                      );
                    }).toList(),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                elevation: 6,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: EdgeInsets.zero,
              ).copyWith(
                backgroundColor: WidgetStateProperty.resolveWith<Color?>((states) => null),
              ),
              onPressed: selectedSymptoms.isEmpty
                  ? null
                  : () {
                print("✅ 선택된 증상 리스트: $selectedSymptoms");
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => DiseaseResultPage(
                      selectedSymptoms: selectedSymptoms.toList(),
                    ),
                  ),
                );
              },
              child: Ink(
                decoration: const BoxDecoration(
                  color: Color(0xFF1E3C72),
                ),
                child: Container(

                  alignment: Alignment.center,
                  child: const Text(
                    "확인",
                    style: TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}