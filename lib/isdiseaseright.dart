import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'yourdisease.dart';

class IsDiseaseRightPage extends StatefulWidget {
  final Map<String, dynamic>? personalInfo;

  const IsDiseaseRightPage({super.key, this.personalInfo});

  @override
  State<IsDiseaseRightPage> createState() => _IsDiseaseRightPageState();
}

class _IsDiseaseRightPageState extends State<IsDiseaseRightPage> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;

  Future<Map<String, dynamic>> checkChestPain(String input) async {
    final url = Uri.parse("http://localhost:8080/api/analyze/chestpain"); // Node.js 서버 주소

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"userInput": input}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print("🤖 서버 응답: $data");
        return data;
      } else {
        print("⚠️ 서버 오류: ${response.statusCode}");
        return {"result": "FALSE"};
      }
    } catch (e) {
      print("💥 서버 연결 오류: $e");
      return {"result": "FALSE"};
    }
  }


  /// ✅ “확인” 버튼 클릭
  Future<void> _onCheckPressed(BuildContext context) async {
    final input = _controller.text.trim();
    if (input.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("증상을 입력해주세요."),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }
    setState(() {
      _isLoading = true;
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
          MaterialPageRoute(builder: (_) => YourDiseasePage()),
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("서버 오류가 발생했습니다: $e"),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
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
            colors: [primaryColor, secondaryColor, accentColor],
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
                            icon: const Icon(
                              Icons.arrow_back_ios,
                              color: Colors.white,
                            ),
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
                              ],
                            ),
                          ),
                          const SizedBox(width: 48), // 뒤로가기 버튼과 균형 맞추기
                        ],
                      ),

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
                              "AI가 입력하신 내용을 분석하여\n증상 여부를 판별합니다",
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
                                enabled: !_isLoading,
                                maxLines: 3,
                                decoration: InputDecoration(
                                  hintText: "예: 가슴이 답답해요, 숨이 막혀요, 심장이 두근거려요",
                                  hintStyle: TextStyle(
                                    color: Colors.grey[400],
                                    fontSize: 14,
                                  ),
                                  prefixIcon: Icon(
                                    Icons.favorite,
                                    color: primaryColor,
                                  ),
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
                            if (!_isLoading)
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: primaryColor,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                    ),
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

                      // 로딩 오버레이 (화면 중앙)
                    ],
                  ),
                ),
              ),
              if (_isLoading)
                Positioned.fill(
                  child: Container(
                    color: Colors.black.withOpacity(0.3),
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
}
