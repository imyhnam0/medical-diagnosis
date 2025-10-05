import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'yourdisease.dart';

class IsDiseaseRightPage extends StatefulWidget {
  const IsDiseaseRightPage({super.key});

  @override
  State<IsDiseaseRightPage> createState() => _IsDiseaseRightPageState();
}

class _IsDiseaseRightPageState extends State<IsDiseaseRightPage> {
  final TextEditingController _controller = TextEditingController();
  String? _errorMessage;
  bool _isLoading = false;

  String? _matchedSentence; // ✅ Gemini가 유사하다고 판단한 문장
  bool _awaitingUserConfirm = false; // ✅ “예/아니요” 상태 관리

  // ✅ 예시 문장 → 사용자에게 보여줄 질문 텍스트 매핑
  final Map<String, String> symptomToQuestion = {
    "가슴이 아파요": "가슴에 통증이 있으신가요?",
    "가슴이 짓눌리는 느낌이에요": "가슴이 눌리거나 짓누르는 느낌이 있으신가요?",
    "가슴이 쿡쿡 쑤셔요": "가슴을 쿡쿡 찌르는 듯한 통증이 있으신가요?",
    "가슴이 무거워요": "가슴이 무겁게 느껴지시나요?",
    "가슴이 조여요": "가슴이 조이는 느낌이 있으신가요?",
    "가슴이 터질 것 같아요": "가슴이 터질 듯한 통증을 느끼시나요?",
    "가슴이 타는 것 같아요": "가슴이 화끈거리거나 타는 느낌이 있으신가요?",
    "가슴이 찢어질 것 같아요": "가슴이 찢어지는 듯한 통증이 있으신가요?",
    "가슴이 따가워요": "가슴이 따갑게 아프신가요?",
    "바늘로 찌르는 느낌이에요": "가슴이 바늘로 찌르는 듯한 느낌이 드시나요?",
    "쥐어짜는 듯해요": "가슴을 쥐어짜는 듯한 통증이 있으신가요?",
    "가슴이 화끈거려요": "가슴이 화끈거리거나 뜨겁게 느껴지시나요?",
    "가슴이 얼얼해요": "가슴이 얼얼하거나 저린 느낌이 있으신가요?",
    "가슴이 벌어질 것 같아요": "가슴이 벌어질 듯한 느낌이 드시나요?",
    "가슴이 뜨거워요": "가슴이 뜨겁게 달아오르는 느낌이 있으신가요?",
    "심장이 쿵쿵 뛰어요": "심장이 빠르게 뛰거나 두근거리시나요?",
    "가슴이 벌렁거려요": "가슴이 벌렁거리거나 심장이 불안정하게 뛰시나요?",
    "심장이 불규칙해요": "심장 박동이 불규칙하게 느껴지시나요?",
    "숨 쉴 때 가슴이 아파요": "숨을 쉴 때 가슴에 통증이 느껴지시나요?",
    "기침하면 가슴이 아파요": "기침할 때 가슴이 아프신가요?",
    "운동하고 나면 아파요": "운동 후에 가슴 통증이 생기시나요?",
    "스트레스 받으면 아파요": "스트레스를 받을 때 가슴이 아프신가요?",
    "식사 후에 아파요": "식사 후 가슴이 아프거나 더부룩하신가요?",
    "가슴이 조여서 숨이 안 쉬어져요": "가슴이 조여서 숨쉬기 힘드신가요?",
    "가슴이 울렁거려요": "가슴이 울렁거리거나 속이 메스꺼우신가요?",
    "가슴이 답답해요": "가슴이 답답하거나 숨이 막히는 느낌이 있으신가요?",
    "심장이 멎을 것 같아요": "심장이 멎을 듯한 불안감이나 두려움을 느끼시나요?",
    "숨이 막혀요": "숨이 막히거나 답답하게 느껴지시나요?",
    "가슴이 무언가 걸린 것 같아요": "가슴에 뭔가 걸린 듯한 이물감이 있으신가요?",
    "계단 오르면 가슴이 아파요": "계단을 오를 때 가슴에 통증이 있으신가요?",
    "가만히 있어도 아파요": "가만히 있을 때도 가슴이 아프신가요?",
    "누우면 아파요": "누워 있을 때 가슴 통증이 생기시나요?",
    "앉아있기 힘들어요": "가슴이 불편해서 앉아있기 힘드신가요?",
    "왼쪽 가슴이 아파요": "왼쪽 가슴 부위에 통증이 있으신가요?",
    "오른쪽 가슴이 아파요": "오른쪽 가슴 부위에 통증이 있으신가요?",
    "중앙이 아파요": "가슴 중앙 부위에 통증이 있으신가요?",
    "팔로 통증이 퍼져요": "가슴 통증이 팔로 퍼지시나요?",
    "턱까지 아파요": "가슴 통증이 턱까지 퍼지시나요?",
    "등까지 아파요": "가슴 통증이 등 쪽까지 번지시나요?",
    "숨 쉴 때 통증이 심해져요": "숨을 쉴 때 통증이 더 심해지시나요?",
    "심장 쪽이 욱신거려요": "심장 부위가 욱신거리게 아프신가요?",
    "기운이 없어요": "최근에 기운이 없거나 쉽게 피로해지시나요?",
    "어지러워요": "어지러움이나 균형감 저하가 있으신가요?",
    "토할 것 같아요": "메스꺼움이나 구토감이 있으신가요?",
    "메스꺼워요": "속이 메스껍거나 구역질이 나시나요?",
    "식은땀이 나요": "갑자기 식은땀이 나거나 땀이 많이 나시나요?",
    "숨이 가빠요": "숨이 차거나 호흡이 가빠지시나요?",
    "숨을 크게 쉬기 어려워요": "숨을 깊게 쉬기가 힘드신가요?",
    "날카로운 통증이에요": "가슴에 날카로운 통증이 느껴지시나요?",
    "찌릿한 통증이에요": "가슴에 찌릿한 전기 오는 듯한 통증이 있으신가요?",
    "화끈거려요": "가슴이 화끈거리거나 뜨거운 느낌이 있으신가요?",
    "심장이 덜컥 내려앉는 느낌이에요": "심장이 덜컥 내려앉는 듯한 느낌이 있으신가요?",
    "심장 박동이 느껴져요": "심장 박동이 강하게 느껴지시나요?",
    "맥이 빨라요": "맥박이 빠르게 뛰는 느낌이 있으신가요?",
    "맥이 느려요": "맥박이 느리게 뛰거나 약하게 느껴지시나요?",
    "피곤해요": "요즘 피로감이 심하게 느껴지시나요?",
    "죽을 것 같아요": "생명이 위태롭다고 느껴질 정도로 불안하시나요?",
    "생명 위협 느껴요": "생명이 위험하다고 느껴질 때가 있으신가요?",
    "병원 가야 할 것 같아요": "지금 증상 때문에 병원에 가야 할 것 같다고 느끼시나요?",
    "차가운 땀이 나요": "식은땀이나 차가운 땀이 나시나요?",
    "공기가 안 통해요": "숨이 막혀 공기가 통하지 않는 느낌이 드시나요?",
    "한숨 쉬고 싶어요": "답답해서 자꾸 한숨을 쉬고 싶으신가요?",
    "심장이 조여요": "심장이 조이는 듯한 통증을 느끼시나요?",
    "계속 뭔가 불편해요": "가슴이 계속 불편하거나 찝찝하게 느껴지시나요?",
    "불쾌감이 있어요": "가슴 부위에 불쾌감이나 이상감이 있으신가요?",
    "움직이기 힘들어요": "몸을 움직이기 힘들거나 가슴이 불편하신가요?",
    "숨이 차요": "숨이 차거나 호흡이 짧게 느껴지시나요?",
    "눌리는 느낌이에요": "가슴이 눌리는 듯한 느낌이 드시나요?",
    "압박감이 있어요": "가슴에 압박감이나 조이는 느낌이 있으신가요?",
    "밤에 통증이 심해져요": "밤에 가슴 통증이 더 심해지시나요?",
    "아침에 더 아파요": "아침에 통증이 더 심하게 느껴지시나요?",
    "몸을 구부리면 아파요": "몸을 구부릴 때 가슴이 아프신가요?",
    "긴장하면 아파요": "긴장하거나 불안할 때 가슴이 아프신가요?",
    "감기 후에 아파요": "감기 후에 가슴 통증이 생기셨나요?",
    "깜짝 놀랄 만큼 아파요": "갑자기 심하게 아프셔서 놀라셨나요?",
    "증상이 반복돼요": "가슴 통증이 반복적으로 나타나시나요?",
    "통증이 오락가락해요": "가슴 통증이 있다가 없어지기를 반복하시나요?",
    "약을 먹어도 안 나아요": "약을 먹어도 증상이 나아지지 않으신가요?",
    "가슴이 먹먹해요": "가슴이 먹먹하거나 답답하게 느껴지시나요?",
    "가슴에 무언가 눌린 느낌": "가슴에 뭔가 눌린 듯한 느낌이 있으신가요?",
    "가슴이 전기가 오는 것 같아요": "가슴에 전기가 오는 듯한 느낌이 드시나요?",
    "심장 부위에 통증이 있어요": "심장 부위에 통증이 있으신가요?",
    "숨을 참고 있어야 해요": "가슴이 아파서 숨을 참고 있게 되시나요?",
    "가슴에 맥이 튀어요": "가슴에서 맥이 튀는 듯한 느낌이 드시나요?",
    "화나면 아파요": "화가 날 때 가슴이 아프신가요?",
    "무서울 때 가슴이 아파요": "무서울 때 가슴이 아프거나 두근거리시나요?",
    "불안하면 아파요": "불안할 때 가슴이 아프거나 조여오시나요?",
    "식도가 아픈 것 같아요": "식도나 목 부위에 통증이 느껴지시나요?",
    "삼킬 때 아파요": "음식을 삼킬 때 가슴이나 목이 아프신가요?",
    "등 쪽으로 퍼지는 통증": "가슴 통증이 등 쪽으로 번지는 느낌이 있으신가요?",
  };



  /// ✅ Gemini 호출 (유사 문장 + TRUE/FALSE)
  Future<Map<String, dynamic>> checkChestPain(String input) async {
    final prompt = """
당신은 의료 데이터 분석 AI입니다.  
아래는 흉통(가슴 통증) 관련 증상 예시 문장들입니다.

예시:
가슴이 아파요
가슴이 짓눌리는 느낌이에요
가슴이 쿡쿡 쑤셔요
가슴이 무거워요
가슴이 조여요
가슴이 터질 것 같아요
가슴이 타는 것 같아요
가슴이 찢어질 것 같아요
가슴이 따가워요
바늘로 찌르는 느낌이에요
쥐어짜는 듯해요
가슴이 화끈거려요
가슴이 얼얼해요
가슴이 벌어질 것 같아요
가슴이 뜨거워요
심장이 쿵쿵 뛰어요
가슴이 벌렁거려요
심장이 불규칙해요
숨 쉴 때 가슴이 아파요
기침하면 가슴이 아파요
운동하고 나면 아파요
스트레스 받으면 아파요
식사 후에 아파요
가슴이 조여서 숨이 안 쉬어져요
가슴이 울렁거려요
가슴이 답답해요
심장이 멎을 것 같아요
숨이 막혀요
가슴이 무언가 걸린 것 같아요
계단 오르면 가슴이 아파요
가만히 있어도 아파요
누우면 아파요
앉아있기 힘들어요
왼쪽 가슴이 아파요
오른쪽 가슴이 아파요
중앙이 아파요
팔로 통증이 퍼져요
턱까지 아파요
등까지 아파요
숨 쉴 때 통증이 심해져요
심장 쪽이 욱신거려요
기운이 없어요
어지러워요
토할 것 같아요
메스꺼워요
식은땀이 나요
숨이 가빠요
숨을 크게 쉬기 어려워요
날카로운 통증이에요
찌릿한 통증이에요
화끈거려요
심장이 덜컥 내려앉는 느낌이에요
심장 박동이 느껴져요
맥이 빨라요
맥이 느려요
피곤해요
죽을 것 같아요
생명 위협 느껴요
병원 가야 할 것 같아요
차가운 땀이 나요
공기가 안 통해요
한숨 쉬고 싶어요
심장이 조여요
계속 뭔가 불편해요
불쾌감이 있어요
움직이기 힘들어요
숨이 차요
눌리는 느낌이에요
압박감이 있어요
밤에 통증이 심해져요
아침에 더 아파요
몸을 구부리면 아파요
긴장하면 아파요
감기 후에 아파요
깜짝 놀랄 만큼 아파요
증상이 반복돼요
통증이 오락가락해요
약을 먹어도 안 나아요
가슴이 먹먹해요
가슴에 무언가 눌린 느낌
가슴이 전기가 오는 것 같아요
심장 부위에 통증이 있어요
숨을 참고 있어야 해요
가슴에 맥이 튀어요
화나면 아파요
무서울 때 가슴이 아파요
불안하면 아파요
식도가 아픈 것 같아요
삼킬 때 아파요
등 쪽으로 퍼지는 통증

---

사용자가 입력한 문장이 위 예시들과 **의미적으로 유사한지** 판단하세요.  
만약 흉통 관련이라면 다음 JSON 형식으로만 출력하세요:
{"result":"TRUE","similar":"<가장 유사한 문장>"}

흉통과 무관하다면:
{"result":"FALSE"}
그 외의 말은 절대 하지 마세요.

사용자 입력: "$input"
""";

    final response = await http.post(
      Uri.parse(
          "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent"),
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
      final text = data["candidates"][0]["content"]["parts"][0]["text"].trim();

      try {
        final jsonResponse = jsonDecode(text);
        return jsonResponse;
      } catch (_) {
        debugPrint("⚠️ Gemini 응답 파싱 실패: $text");
        return {"result": "FALSE"};
      }
    } else {
      debugPrint("⚠️ API Error: ${response.body}");
      return {"result": "FALSE"};
    }
  }

  /// ✅ “확인” 버튼 클릭
  Future<void> _onCheckPressed(BuildContext context) async {
    final input = _controller.text.trim();
    if (input.isEmpty) {
      setState(() => _errorMessage = "증상을 입력해주세요.");
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _matchedSentence = null;
      _awaitingUserConfirm = false;
    });

    try {
      final result = await checkChestPain(input);
      if (result["result"] == "TRUE") {
        final similar = result["similar"];
        debugPrint("✅ 유사한 문장: $similar"); // ✅ 콘솔 출력 (print 용도)
        final matchedQuestion = symptomToQuestion[similar];

        setState(() {
          _matchedSentence = matchedQuestion;
          _awaitingUserConfirm = true;
        });
      } else {
        setState(() {
          _errorMessage = "⚠️ 본 앱은 흉통 관련 증상만 판별이 가능합니다.";
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = "서버 오류가 발생했습니다: $e";
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// ✅ “예” 눌렀을 때
  void _onConfirmYes(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const YourDiseasePage()),
    );
  }

  /// ✅ “아니요” 눌렀을 때
  void _onConfirmNo() {
    setState(() {
      _awaitingUserConfirm = false;
      _matchedSentence = null;
      _controller.clear();
      _errorMessage = "증상을 조금 더 구체적으로 입력해주세요.";
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("증상 판별"),
        backgroundColor: const Color(0xFF1E3C72),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const SizedBox(height: 30),
            const Text(
              "현재 느끼는 주요 증상을 입력해주세요.\n입력하신 내용을 바탕으로 흉통 관련 여부를 우선 판별합니다.",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _controller,
              enabled: !_awaitingUserConfirm,
              decoration: InputDecoration(
                hintText: "예: 가슴이 답답해요, 숨이 막혀요 등",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                prefixIcon: const Icon(Icons.monitor_heart),
              ),
            ),
            const SizedBox(height: 25),

            if (_isLoading)
              const CircularProgressIndicator(color: Colors.blueAccent),

            // ✅ “유사 문장 확인 질문” UI
            if (_awaitingUserConfirm && _matchedSentence != null)
              Column(
                children: [
                  const SizedBox(height: 20),
                  Text(
                    // ✅ 사용자에게 자연스럽게 질문으로 표현
                    "${_matchedSentence!}",
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () => _onConfirmYes(context),
                        icon: const Icon(Icons.check),
                        label: const Text("예"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 30, vertical: 14),
                        ),
                      ),
                      const SizedBox(width: 20),
                      OutlinedButton.icon(
                        onPressed: _onConfirmNo,
                        icon: const Icon(Icons.close),
                        label: const Text("아니요"),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 30, vertical: 14),
                        ),
                      ),
                    ],
                  ),
                ],
              ),

            if (!_awaitingUserConfirm && !_isLoading)
              ElevatedButton(
                onPressed: () => _onCheckPressed(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  foregroundColor: Colors.white,
                  padding:
                  const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: const Text(
                  "확인",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),

            const SizedBox(height: 20),
            if (_errorMessage != null)
              Text(
                _errorMessage!,
                style: const TextStyle(
                  color: Colors.redAccent,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
          ],
        ),
      ),
    );
  }
}
