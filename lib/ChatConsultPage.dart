import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ChatConsultPage extends StatefulWidget {
  final String diseaseName;
  const ChatConsultPage({super.key, required this.diseaseName});

  @override
  State<ChatConsultPage> createState() => _ChatConsultPageState();
}

class _ChatConsultPageState extends State<ChatConsultPage> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<Map<String, String>> _messages = [];
  bool _isLoading = false;

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    setState(() {
      _messages.add({"role": "user", "content": text});
      _isLoading = true;
    });

    _controller.clear();

    await Future.delayed(const Duration(milliseconds: 300));
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent + 100,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOut,
    );

    final prompt = """
당신은 전문 의료 상담 AI입니다.
환자가 '${widget.diseaseName}' 진단 결과를 받고 추가 질문을 합니다.
의학적으로 정확하고 친절하게 답변하세요.
응급 상황이 의심되면 반드시 "즉시 병원 내원이 필요합니다"라고 안내하세요.

질문: "$text"
""";

    try {
      final response = await http.post(
        Uri.parse(
            "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent"),
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
        final reply =
        data["candidates"][0]["content"]["parts"][0]["text"].trim();
        setState(() {
          _messages.add({"role": "ai", "content": reply});
        });
      } else {
        setState(() {
          _messages.add({
            "role": "ai",
            "content": "⚠️ 서버 오류가 발생했습니다. 다시 시도해주세요."
          });
        });
      }
    } catch (e) {
      setState(() {
        _messages.add({
          "role": "ai",
          "content": "⚠️ 네트워크 오류가 발생했습니다. 인터넷 연결을 확인해주세요."
        });
      });
    } finally {
      setState(() {
        _isLoading = false;
        _controller.clear();
      });
      await Future.delayed(const Duration(milliseconds: 300));
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent + 200,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOut,
      );
    }
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
          child: Column(
            children: [
              // 상단 앱바
              Container(
                padding: EdgeInsets.all(screenWidth * 0.05),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                    ),
                    Expanded(
                      child: Column(
                        children: [
                          Text(
                            "AI 의료 상담",
                            style: TextStyle(
                              fontSize: isSmallScreen ? 18 : 20,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            widget.diseaseName,
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
              ),
              
              // 메인 채팅 영역
              Expanded(
                child: Container(
                  margin: EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(25),
                      topRight: Radius.circular(25),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 20,
                        offset: const Offset(0, -5),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // 상단 질병 정보 카드
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.all(20),
                        padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [primaryColor.withOpacity(0.1), primaryColor.withOpacity(0.05)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: primaryColor.withOpacity(0.2),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: primaryColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.psychology,
                                color: primaryColor,
                                size: isSmallScreen ? 20 : 24,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "AI 의료 상담",
                                    style: TextStyle(
                                      fontSize: isSmallScreen ? 14 : 16,
                                      fontWeight: FontWeight.w600,
                                      color: primaryColor,
                                    ),
                                  ),
                                  Text(
                                    "진단된 질병: ${widget.diseaseName}",
                                    style: TextStyle(
                                      fontSize: isSmallScreen ? 12 : 13,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      // 메시지 리스트
                      Expanded(
                        child: _messages.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      width: isSmallScreen ? 60 : 80,
                                      height: isSmallScreen ? 60 : 80,
                                      decoration: BoxDecoration(
                                        color: primaryColor.withOpacity(0.1),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        Icons.chat_bubble_outline,
                                        color: primaryColor,
                                        size: isSmallScreen ? 30 : 40,
                                      ),
                                    ),
                                    SizedBox(height: isSmallScreen ? 16 : 20),
                                    Text(
                                      "AI에게 질문해보세요",
                                      style: TextStyle(
                                        fontSize: isSmallScreen ? 16 : 18,
                                        fontWeight: FontWeight.w600,
                                        color: primaryColor,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      "진단 결과에 대해 궁금한 점을\n자유롭게 질문하실 수 있습니다",
                                      style: TextStyle(
                                        fontSize: isSmallScreen ? 12 : 14,
                                        color: Colors.grey[600],
                                        height: 1.4,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              )
                            : ListView.builder(
                                controller: _scrollController,
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                                itemCount: _messages.length,
                                itemBuilder: (context, index) {
                                  final msg = _messages[index];
                                  final isUser = msg["role"] == "user";

                                  return Container(
                                    margin: const EdgeInsets.symmetric(vertical: 6),
                                    child: Row(
                                      mainAxisAlignment: isUser 
                                          ? MainAxisAlignment.end 
                                          : MainAxisAlignment.start,
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        if (!isUser) ...[
                                          Container(
                                            width: isSmallScreen ? 32 : 36,
                                            height: isSmallScreen ? 32 : 36,
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                colors: [primaryColor, secondaryColor],
                                                begin: Alignment.topLeft,
                                                end: Alignment.bottomRight,
                                              ),
                                              shape: BoxShape.circle,
                                            ),
                                            child: Icon(
                                              Icons.psychology,
                                              color: Colors.white,
                                              size: isSmallScreen ? 16 : 18,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                        ],
                                        Flexible(
                                          child: Container(
                                            padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
                                            constraints: BoxConstraints(
                                              maxWidth: screenWidth * 0.7,
                                            ),
                                            decoration: BoxDecoration(
                                              gradient: isUser
                                                  ? LinearGradient(
                                                      colors: [primaryColor, secondaryColor],
                                                      begin: Alignment.topLeft,
                                                      end: Alignment.bottomRight,
                                                    )
                                                  : null,
                                              color: isUser ? null : Colors.grey[50],
                                              borderRadius: BorderRadius.only(
                                                topLeft: const Radius.circular(18),
                                                topRight: const Radius.circular(18),
                                                bottomLeft: isUser
                                                    ? const Radius.circular(18)
                                                    : const Radius.circular(4),
                                                bottomRight: isUser
                                                    ? const Radius.circular(4)
                                                    : const Radius.circular(18),
                                              ),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black.withOpacity(0.1),
                                                  blurRadius: 8,
                                                  offset: const Offset(0, 2),
                                                ),
                                              ],
                                            ),
                                            child: Text(
                                              msg["content"]!,
                                              style: TextStyle(
                                                color: isUser ? Colors.white : Colors.grey[800],
                                                fontSize: isSmallScreen ? 14 : 15,
                                                height: 1.4,
                                              ),
                                            ),
                                          ),
                                        ),
                                        if (isUser) ...[
                                          const SizedBox(width: 8),
                                          Container(
                                            width: isSmallScreen ? 32 : 36,
                                            height: isSmallScreen ? 32 : 36,
                                            decoration: BoxDecoration(
                                              color: Colors.grey[300],
                                              shape: BoxShape.circle,
                                            ),
                                            child: Icon(
                                              Icons.person,
                                              color: Colors.grey[600],
                                              size: isSmallScreen ? 16 : 18,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  );
                                },
                              ),
                      ),

                      // 로딩 상태
                      if (_isLoading)
                        Container(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Container(
                                width: isSmallScreen ? 32 : 36,
                                height: isSmallScreen ? 32 : 36,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [primaryColor, secondaryColor],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.psychology,
                                  color: Colors.white,
                                  size: isSmallScreen ? 16 : 18,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.grey[100],
                                  borderRadius: BorderRadius.circular(18),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    SizedBox(
                                      width: isSmallScreen ? 16 : 20,
                                      height: isSmallScreen ? 16 : 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: primaryColor,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      "AI가 답변을 준비 중입니다...",
                                      style: TextStyle(
                                        fontSize: isSmallScreen ? 12 : 14,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                      // 입력창
                      Container(
                        padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border(
                            top: BorderSide(
                              color: Colors.grey.withOpacity(0.2),
                              width: 1,
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.grey[50],
                                  borderRadius: BorderRadius.circular(25),
                                  border: Border.all(
                                    color: primaryColor.withOpacity(0.2),
                                    width: 1,
                                  ),
                                ),
                                child: TextField(
                                  controller: _controller,
                                  maxLines: null,
                                  decoration: InputDecoration(
                                    hintText: "AI에게 질문을 입력하세요...",
                                    hintStyle: TextStyle(
                                      color: Colors.grey[400],
                                      fontSize: isSmallScreen ? 14 : 15,
                                    ),
                                    border: InputBorder.none,
                                    contentPadding: EdgeInsets.symmetric(
                                      horizontal: isSmallScreen ? 16 : 20,
                                      vertical: isSmallScreen ? 12 : 16,
                                    ),
                                  ),
                                  onSubmitted: (value) => sendMessage(value),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Container(
                              width: isSmallScreen ? 48 : 52,
                              height: isSmallScreen ? 48 : 52,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [primaryColor, secondaryColor],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: primaryColor.withOpacity(0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(26),
                                  onTap: () => sendMessage(_controller.text),
                                  child: Icon(
                                    Icons.send_rounded,
                                    color: Colors.white,
                                    size: isSmallScreen ? 20 : 22,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
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
