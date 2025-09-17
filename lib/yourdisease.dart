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
      "흉통", "협심증 유사 흉통", "갑작스러운 흉통", "설명되지 않는 흉통", "안정 시 흉통",
      "작열성 흉통", "흉골 뒤 압박감", "흉부 불편감", "흉부 압박감", "흉부 조임/답답함",
      "흉벽 통증", "흉벽 불편감", "늑골 압통", "방사통", "방사성 흉통"
    ],
    "호흡기 증상": [
      "호흡곤란", "가벼운 호흡곤란", "운동 시 호흡곤란", "야간 발작성 호흡곤란",
      "기침", "마른기침", "가래", "객혈", "흉막성 통증", "천명음"
    ],
    "심혈관/전신 증상": [
      "발열", "야간 발한", "피로", "전신 권태", "전신 쇠약감", "체중 감소",
      "두근거림", "가슴 두근거림과 어지럼증 동반", "실신", "어지럼증",
      "다리 부종"
    ],
    "소화기 증상": [
      "오심", "구토", "설사", "소화기 증상", "속쓰림", "역류",
      "연하곤란", "상복부 불편감", "명치 통증", "복부 불편감", "복부 팽만",
      "복부 팽만감", "간비대", "복수"
    ],
    "신경/근골격계 증상": [
      "목 통증", "등 통증", "등통증", "등/허리 통증",
      "관절통", "국소 근육통", "국소 통증", "근육통",
      "골통", "이질통", "작열통", "압통", "움직임 제한", "근력 약화", "팔 약화",
      "감각 이상", "저림", "전신 통증", "두개골/흉부 변형"
    ],
    "피부/감각 증상": [
      "발진", "작열감", "가려움", "유방 멍울"
    ],
    "신경/인지 기능 증상": [
      "시각 증상", "수면 문제", "기억력 저하", "청력 이상"
    ],
    "정신/심리 증상": [
      "건강 불안", "신체 증상에 대한 집착", "걱정", "우울감", "플래시백"
    ],
    "여성 생식 관련 증상": [
      "골반 통증", "생리 문제"
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
            return AlertDialog(
              title: const Text("증상 확인"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ✅ 전체 선택된 증상을 보여주도록 변경
                  Text(
                    "다음 증상으로 기록할게요:\n${selectedSymptoms.join(", ")}",
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: popupController,
                    decoration: const InputDecoration(
                      hintText: "추가 증상이 있나요?",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () async {
                    final newInput = popupController.text.trim();
                    if (newInput.isNotEmpty) {
                      final newMatches = await _getMatchedSymptoms(newInput);

                      if (newMatches.isNotEmpty) {
                        setState(() {
                          selectedSymptoms.addAll(newMatches);
                        });
                        // ✅ 팝업 내부 UI 갱신
                        setStateDialog(() {});
                        popupController.clear();
                      }
                    }
                  },
                  child: const Text("추가 입력"),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text("없습니다"),
                ),
              ],
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



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("증상 입력/선택")),
      body: Column(
        children: [
          // ✅ 텍스트 입력창
          Padding(
            padding: const EdgeInsets.all(12.0),
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
                  onPressed: () => _matchSymptoms(_controller.text),
                  child: const Text("확인"),
                ),
              ],
            ),
          ),

          // ✅ 체크박스 UI (자동 선택 반영)
          Expanded(
            child: ListView(
              children: symptomCategories.entries.map((entry) {
                final hasSelected = entry.value.any((s) => selectedSymptoms.contains(s));

                return Card(
                  child: ExpansionTile(
                    // ✅ 카테고리 타이틀을 Container로 감싸서 색상 지정
                    title: Container(
                      color: hasSelected ? Colors.red[100] : null,
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                      child: Text(
                        entry.key,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    children: entry.value.map((symptom) {
                      final isSelected = selectedSymptoms.contains(symptom);

                      return Container(
                        color: isSelected ? Colors.red[100] : null, // ✅ 선택된 항목만 빨강
                        child: CheckboxListTile(
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
          )

        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton(
            onPressed: selectedSymptoms.isEmpty
                ? null
                : () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => DiseaseResultPage(
                    selectedSymptoms: selectedSymptoms.toList(),
                  ),
                ),
              );
            },
            child: const Text("확인"),
          ),
        ),
      ),
    );
  }
}
