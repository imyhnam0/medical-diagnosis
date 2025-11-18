import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'PastDisease.dart';

class ExerciseStressPage extends StatefulWidget {
  const ExerciseStressPage({super.key});

  @override
  State<ExerciseStressPage> createState() => _ExerciseStressPageState();
}

class _ExerciseStressPageState extends State<ExerciseStressPage> {
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  bool _isLoading = false;
  List<String> _extractedKeywords = [];
  String? _currentQuestion;
  bool _isComplete = false;
  List<Map<String, String>> _conversationHistory = [];
  int _currentQuestionIndex = 0;
  bool _canProceed = false;

  static const List<String> _questions = [
    "평소 생활에서 운동이나 신체활동은 어느 정도 하시나요?",
    "최근 스트레스를 느끼는 일이 있었나요? 구체적으로 말씀해주실 수 있을까요?",
  ];

  final primaryColor = const Color(0xFF0F4C75);
  final secondaryColor = const Color(0xFF3282B8);

  @override
  void initState() {
    super.initState();
    _currentQuestion = _questions[0];
    _conversationHistory.add({
      "role": "assistant",
      "content": _currentQuestion!,
    });
  }

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _analyzeExerciseStress() async {
    final input = _inputController.text.trim();

    if (input.isEmpty) {
      _showSnackBar("답변을 입력해주세요.");
      return;
    }

    if (_currentQuestionIndex >= _questions.length) {
      _showSnackBar("모든 질문에 답변하셨습니다.");
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final currentQuestion = _questions[_currentQuestionIndex];

    // Add user's answer to conversation history
    _conversationHistory.add({
      "role": "user",
      "content": input,
    });

    try {
      final url = Uri.parse(
        "http://98.91.66.27:8080/api/analyze/exercise-stress"
      );

      final payload = {
        "question": currentQuestion,
        "answer": input,
        "questionIndex": _currentQuestionIndex,
      };

      print("📤 요청 전송: $payload");

      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final keywords = List<String>.from(data["keywords"] ?? []);

        // 키워드가 있으면 추가
        for (final keyword in keywords) {
          if (!_extractedKeywords.contains(keyword)) {
            setState(() {
              _extractedKeywords.add(keyword);
            });
          }
        }

        // 다음 질문으로 이동
        _currentQuestionIndex++;

        if (_currentQuestionIndex < _questions.length) {
          final nextQuestion = _questions[_currentQuestionIndex];
          setState(() {
            _currentQuestion = nextQuestion;
          });

          // Add the next question to conversation history
          _conversationHistory.add({
            "role": "assistant",
            "content": nextQuestion,
          });
        } else {
          setState(() {
            _isComplete = true;
            _currentQuestion = null;
            _canProceed = true;
          });
        }

        _inputController.clear();

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scrollController.hasClients) {
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          }
        });
      } else {
        _showSnackBar("서버 오류가 발생했습니다. (${response.statusCode})");
        print("⚠️ 서버 오류: ${response.statusCode} - ${response.body}");
      }
    } catch (e) {
      _showSnackBar("분석 중 오류가 발생했습니다: $e");
      print("❌ 분석 오류: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: primaryColor,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [primaryColor, secondaryColor],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: const Text(
          "운동 및 스트레스 분석",
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.white,
            fontSize: 20,
            letterSpacing: 0.5,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // 대화 및 결과 영역
          Expanded(
            child: SingleChildScrollView(
              controller: _scrollController,
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 대화 기록 표시
                  ..._conversationHistory.map((message) {
                    final isUser = message["role"] == "user";
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Align(
                        alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.of(context).size.width * 0.75,
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: isUser
                                ? primaryColor
                                : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.1),
                                blurRadius: 5,
                                offset: const Offset(0, 2),
                              ),
                            ],
                            border: !isUser
                                ? Border.all(
                                    color: primaryColor.withOpacity(0.2),
                                    width: 1,
                                  )
                                : null,
                          ),
                          child: Text(
                            message["content"] ?? "",
                            style: TextStyle(
                              fontSize: 14,
                              color: isUser ? Colors.white : Colors.black87,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ),
                    );
                  }),

                  // 추출된 키워드 표시
                  if (_extractedKeywords.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.all(20),
                      margin: const EdgeInsets.only(top: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                        border: Border.all(
                          color: primaryColor.withOpacity(0.1),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                _isComplete ? Icons.check_circle : Icons.info,
                                color: _isComplete ? Colors.green : primaryColor,
                                size: 24,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                "추출된 키워드",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: primaryColor,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _extractedKeywords.map((keyword) {
                              return Chip(
                                label: Text(
                                  keyword,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                backgroundColor: primaryColor.withOpacity(0.1),
                                side: BorderSide(color: primaryColor.withOpacity(0.3)),
                                labelStyle: TextStyle(color: primaryColor),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),

          // 입력 영역
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Column(
              children: [
                // 현재 질문 표시
                if (_currentQuestion != null && !_isComplete)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: primaryColor.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.help_outline, color: primaryColor, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _currentQuestion!,
                            style: TextStyle(
                              fontSize: 14,
                              color: primaryColor,
                              fontWeight: FontWeight.w500,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                // 완료 메시지
                if (_isComplete)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.green.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.green, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            "모든 질문에 답변하셨습니다.",
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.green[700],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                // 입력 필드
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: primaryColor.withOpacity(0.2),
                      width: 1.5,
                    ),
                  ),
                  child: TextFormField(
                    controller: _inputController,
                    maxLines: 3,
                    style: const TextStyle(
                      fontSize: 15,
                      height: 1.5,
                    ),
                    decoration: InputDecoration(
                      hintText: _isComplete
                          ? "모든 질문에 답변하셨습니다"
                          : "답변을 입력하세요",
                      hintStyle: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 14,
                        height: 1.5,
                      ),
                      enabled: !_isComplete,
                      prefixIcon: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Icon(Icons.fitness_center, color: primaryColor, size: 24),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: primaryColor, width: 2),
                      ),
                      filled: true,
                      fillColor: Colors.transparent,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 20,
                      ),
                      suffixIcon: _isLoading
                          ? const Padding(
                              padding: EdgeInsets.all(16.0),
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            )
                          : IconButton(
                              icon: Icon(Icons.send, color: _isComplete ? Colors.grey : primaryColor),
                              onPressed: (_isLoading || _isComplete) ? null : _analyzeExerciseStress,
                            ),
                    ),
                    onFieldSubmitted: (_) {
                      if (!_isLoading && !_isComplete) {
                        _analyzeExerciseStress();
                      }
                    },
                  ),
                ),
                const SizedBox(height: 12),
                // 다음으로 버튼 (모든 질문 완료 시 활성화)
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: _canProceed
                        ? () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const PastDiseasePage()),
                            );
                          }
                        : null,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: BorderSide(color: _canProceed ? primaryColor : Colors.grey.shade400, width: 1.5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      foregroundColor: _canProceed ? primaryColor : Colors.grey,
                    ),
                    child: Text(
                      "다음으로",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: _canProceed ? primaryColor : Colors.grey,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
