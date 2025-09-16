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
      "흉통", "흉부 불편감", "흉부 압박감", "흉부 조임/답답함",
      "방사통", "국소 흉벽 통증", "흉벽 압통", "멍/타박상"
    ],
    "호흡기 증상": [
      "호흡곤란", "운동 시 호흡곤란", "야간 호흡곤란", "흉부 압박과 호흡곤란 동반",
      "기침", "가래", "객혈", "발열", "오한/밤에 식은땀", "호흡 시 악화되는 통증"
    ],
    "심혈관/전신 증상": [
      "발한", "두근거림", "가슴 두근거림과 어지럼증 동반", "실신",
      "어지럼증", "피로", "전신 쇠약감", "하지 부종", "전신 쇠약과 피로"
    ],
    "소화기 증상": [
      "구역/구토", "상복부 통증", "상복부 불편감", "소화불량/더부룩함",
      "위산 역류/속쓰림", "트림/역류", "상복부 덩어리감", "복부 팽만감",
      "설사", "변비"
    ],
    "신경/근골격계 증상": [
      "근육통", "뻣뻣함", "국소 근육 운동 제한", "전신 통증",
      "팔 저림/무감각", "등 통증", "목 통증", "관절통",
      "운동 시 악화되는 통증", "신경병성 통증"
    ],
    "피부/감각 증상": [
      "피부 발진", "화끈거림/작열감", "가려움/따가움"
    ],
    "신경/인지 기능 증상": [
      "두통", "시야 이상", "청력 이상", "기억력 저하/집중력 저하"
    ],
    "정신/심리 증상": [
      "불면", "수면 장애", "불안/걱정", "우울감",
      "공황 발작", "플래시백"
    ],
    "여성 생식 관련 증상": [
      "여성 생리 관련 증상"
    ],
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
                    Navigator.pop(context); // 팝업 닫기
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => DiseaseResultPage(
                          selectedSymptoms: selectedSymptoms.toList(),
                        ),
                      ),
                    );
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
                return Card(
                  child: ExpansionTile(
                    title: Text(entry.key),
                    collapsedBackgroundColor: entry.value.any((s) => selectedSymptoms.contains(s))
                        ? Colors.red[100] // ✅ 해당 카테고리 안에서 하나라도 선택되면 파란색
                        : null,
                    backgroundColor: entry.value.any((s) => selectedSymptoms.contains(s))
                        ? Colors.red[100]
                        : null,
                    children: entry.value.map((symptom) {
                      return CheckboxListTile(
                        title: Text(symptom),
                        value: selectedSymptoms.contains(symptom),
                        onChanged: (checked) {
                          setState(() {
                            if (checked!) {
                              selectedSymptoms.add(symptom);
                            } else {
                              selectedSymptoms.remove(symptom);
                            }
                          });
                        },
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
