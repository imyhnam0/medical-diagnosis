import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'yourdisease.dart';

class IsDiseaseRightPage extends StatefulWidget {
  final Map<String, String>? personalInfo;
  
  const IsDiseaseRightPage({super.key, this.personalInfo});

  @override
  State<IsDiseaseRightPage> createState() => _IsDiseaseRightPageState();
}

class _IsDiseaseRightPageState extends State<IsDiseaseRightPage> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String? _errorMessage;
  bool _isLoading = false;

  String? _matchedSentence; // ✅ Gemini가 유사하다고 판단한 문장
  bool _awaitingUserConfirm = false; // ✅ "예/아니요" 상태 관리



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
      
      // AI 출력값 print
      print("🤖 AI 응답: $text");

      try {
        final jsonResponse = jsonDecode(text);
        print("📊 파싱된 JSON: $jsonResponse");
        return jsonResponse;
      } catch (e) {
        debugPrint("⚠️ Gemini 응답 파싱 실패: $text");
        debugPrint("⚠️ 파싱 오류: $e");
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
      print("🔍 checkChestPain 결과: $result");
      
      if (result["result"] == "TRUE") {
        print("✅ 흉통 관련 증상으로 판단됨");
        print("📝 유사한 문장: ${result["similar"]}");
        
        // 흉통 관련 증상이면 바로 YourDiseasePage로 이동
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => YourDiseasePage(
              userInput: input,
              personalInfo: widget.personalInfo,
            ),
          ),
        );
      } else {
        print("❌ 흉통 관련이 아닌 것으로 판단됨");
        
        // 팝업으로 메시지 표시
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: Colors.orange[600]),
                  const SizedBox(width: 8),
                  const Text('알림'),
                ],
              ),
              content: const Text('흉통관련 질환이 아닙니다.'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('확인'),
                ),
              ],
            );
          },
        );
      }
    } catch (e) {
      print("💥 오류 발생: $e");
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
      MaterialPageRoute(
        builder: (_) => YourDiseasePage(
          userInput: _controller.text.trim(), // ✅ 사용자 입력 전달
        ),
      ),
    );
  }


  /// ✅ "아니요" 눌렀을 때
  void _onConfirmNo() {
    setState(() {
      _awaitingUserConfirm = false;
      _matchedSentence = null;
      _controller.clear();
      _errorMessage = "증상을 조금 더 구체적으로 입력해주세요.";
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenHeight < 700;

    final primaryColor = const Color(0xFF0F4C75);
    final secondaryColor = const Color(0xFF3282B8);
    final accentColor = const Color(0xFFBBE1FA);

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              primaryColor,
              secondaryColor,
              accentColor,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            stops: const [0.0, 0.6, 1.0],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // 기존 스크롤 가능한 내용
              SingleChildScrollView(
                controller: _scrollController,
                physics: const BouncingScrollPhysics(),
                child: Padding(
                  padding: EdgeInsets.all(screenWidth * 0.05),
                  child: Column(
                    children: [
                  // 상단 앱바
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                      ),
                      Expanded(
        child: Column(
          children: [
                            Text(
                              "AI 증상 판별",
                              style: TextStyle(
                                fontSize: isSmallScreen ? 20 : 24,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "흉통 관련 증상을 정확히 분석합니다",
                              style: TextStyle(
                                fontSize: isSmallScreen ? 12 : 14,
                                color: Colors.white.withOpacity(0.8),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 48), // 뒤로가기 버튼과 균형 맞추기
                    ],
                  ),

                  const SizedBox(height: 20),

                  // 개인정보 카드 (개인정보가 있을 때만 표시)
                  if (widget.personalInfo != null) ...[
                    _buildPersonalInfoCard(widget.personalInfo!, isSmallScreen, primaryColor),
                    const SizedBox(height: 20),
                  ],

                  // 메인 안내 카드
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(isSmallScreen ? 20 : 24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // AI 아이콘
                        Container(
                          width: isSmallScreen ? 60 : 80,
                          height: isSmallScreen ? 60 : 80,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [primaryColor, secondaryColor],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: primaryColor.withOpacity(0.3),
                                blurRadius: 15,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.psychology,
                            color: Colors.white,
                            size: isSmallScreen ? 30 : 40,
                          ),
                        ),

                        SizedBox(height: isSmallScreen ? 16 : 20),

                        Text(
                          "현재 느끼는 주요 증상을 입력해주세요",
                          style: TextStyle(
                            fontSize: isSmallScreen ? 18 : 22,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF1A202C),
                          ),
                          textAlign: TextAlign.center,
                        ),

                        SizedBox(height: isSmallScreen ? 8 : 12),

                        Text(
                          "AI가 입력하신 내용을 분석하여\n흉통 관련 증상 여부를 판별합니다",
                          style: TextStyle(
                            fontSize: isSmallScreen ? 14 : 16,
                            color: Colors.grey[600],
                            height: 1.4,
                          ),
              textAlign: TextAlign.center,
            ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // 증상 입력 섹션
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 섹션 제목
                        Row(
                          children: [
                            Icon(
                              Icons.edit_note,
                              color: primaryColor,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              "증상 입력",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: primaryColor,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // 입력창
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: primaryColor.withOpacity(0.2),
                              width: 1,
                            ),
                          ),
                          child: TextField(
              controller: _controller,
              enabled: !_awaitingUserConfirm,
                            maxLines: 3,
              decoration: InputDecoration(
                              hintText: "예: 가슴이 답답해요, 숨이 막혀요, 심장이 두근거려요",
                              hintStyle: TextStyle(
                                color: Colors.grey[400],
                                fontSize: 14,
                              ),
                              prefixIcon: Icon(Icons.favorite, color: primaryColor),
                border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide.none,
                              ),
                              filled: true,
                              fillColor: Colors.transparent,
                              contentPadding: const EdgeInsets.all(16),
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // 확인 버튼
                        if (!_awaitingUserConfirm && !_isLoading)
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryColor,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                elevation: 2,
                              ),
                              onPressed: () => _onCheckPressed(context),
                              icon: const Icon(
                                Icons.auto_awesome,
                                color: Colors.white,
                                size: 20,
                              ),
                              label: const Text(
                                "AI로 증상 분석하기",
                                style: TextStyle(
                                  color: Colors.white,
                      fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // AI 분석 결과 확인 UI
                  if (_awaitingUserConfirm && _matchedSentence != null)
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(isSmallScreen ? 20 : 24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 15,
                            offset: const Offset(0, 5),
                          ),
                        ],
                        border: Border.all(
                          color: Colors.green.withOpacity(0.3),
                          width: 2,
                        ),
                      ),
                      child: Column(
                        children: [
                          // 성공 아이콘
                          Container(
                            width: isSmallScreen ? 50 : 60,
                            height: isSmallScreen ? 50 : 60,
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.check_circle,
                              color: Colors.green,
                              size: isSmallScreen ? 30 : 36,
                            ),
                          ),

                          SizedBox(height: isSmallScreen ? 16 : 20),

                          Text(
                            "AI 분석 결과",
                            style: TextStyle(
                              fontSize: isSmallScreen ? 18 : 20,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF1A202C),
                            ),
                          ),

                          SizedBox(height: isSmallScreen ? 12 : 16),

                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.green[50],
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.green.withOpacity(0.2),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              _matchedSentence!,
                              style: TextStyle(
                                fontSize: isSmallScreen ? 15 : 17,
                                fontWeight: FontWeight.w600,
                                color: Colors.green[700],
                                height: 1.4,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),

                          SizedBox(height: isSmallScreen ? 20 : 24),

                          Text(
                            "이 증상이 맞나요?",
                            style: TextStyle(
                              fontSize: isSmallScreen ? 14 : 16,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),

                          SizedBox(height: isSmallScreen ? 16 : 20),

                          // 예/아니요 버튼
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () => _onConfirmYes(context),
                                  icon: const Icon(Icons.check, color: Colors.white),
                                  label: const Text(
                                    "예",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    elevation: 2,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: _onConfirmNo,
                                  icon: Icon(Icons.close, color: Colors.red[600]),
                                  label: Text(
                                    "아니요",
                                    style: TextStyle(
                                      color: Colors.red[600],
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    side: BorderSide(color: Colors.red[300]!),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                  ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
                    ),

                  const SizedBox(height: 20),

                  // 에러 메시지
                  if (_errorMessage != null)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.red[50],
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.red.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.warning_amber_rounded,
                            color: Colors.red[600],
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: TextStyle(
                                color: Colors.red[700],
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),

              // 로딩 오버레이 (화면 중앙)
              if (_isLoading)
                Positioned.fill(
                  child: Container(
                    color: Colors.black.withOpacity(0.3), // 반투명 배경
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 15,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircularProgressIndicator(
                              color: const Color(0xFF0F4C75),
                              strokeWidth: 3,
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              "AI가 증상을 분석하고 있습니다...",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF0F4C75),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),

      ),
    );
  }

  /// 개인정보 카드 위젯
  Widget _buildPersonalInfoCard(Map<String, String> personalInfo, bool isSmallScreen, Color primaryColor) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
        border: Border.all(
          color: primaryColor.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 헤더
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.person_outline,
                  color: primaryColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                "입력된 개인정보",
                style: TextStyle(
                  fontSize: isSmallScreen ? 16 : 18,
                  fontWeight: FontWeight.w700,
                  color: primaryColor,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // 개인정보 항목들
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _buildInfoChip("나이", "${personalInfo['age']}세", Icons.cake, primaryColor),
              _buildInfoChip("몸무게", "${personalInfo['weight']}kg", Icons.monitor_weight, primaryColor),
              _buildInfoChip("성별", personalInfo['gender']!, Icons.person, primaryColor),
              _buildInfoChip("음주", personalInfo['drinking']!, Icons.local_drink, primaryColor),
              _buildInfoChip("흡연", personalInfo['smoking']!, Icons.smoking_rooms, primaryColor),
              _buildInfoChip("직업", personalInfo['job']!, Icons.work, primaryColor),
              _buildInfoChip("운동", personalInfo['exercise']!, Icons.fitness_center, primaryColor),
              _buildInfoChip("과거질환", personalInfo['pastDiseases']!, Icons.medical_services, primaryColor),
            ],
          ),
        ],
      ),
    );
  }

  /// 개인정보 칩 위젯
  Widget _buildInfoChip(String label, String value, IconData icon, Color primaryColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: primaryColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: primaryColor.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: primaryColor,
          ),
          const SizedBox(width: 6),
          Text(
            "$label: $value",
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: primaryColor,
            ),
          ),
        ],
      ),
    );
  }
}
