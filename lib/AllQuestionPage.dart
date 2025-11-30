import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'ResultPage.dart';
import 'utils/session_manager.dart';

class AllQuestionPage extends StatefulWidget {
  final String followUpQuestion;
  final String? initialUserInput;

  const AllQuestionPage({
    super.key,
    required this.followUpQuestion,
    this.initialUserInput,
  });

  @override
  State<AllQuestionPage> createState() => _AllQuestionPageState();
}

class _AllQuestionPageState extends State<AllQuestionPage> {
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  bool _isLoading = false;
  List<String> _allExtractedKeywords = [];
  List<Map<String, String>> _conversationHistory = [];
  
  // 현재 섹션과 질문 인덱스
  int _currentSectionIndex = 0;
  int _currentQuestionIndex = 0;
  bool _isComplete = false;

  // 각 섹션별 질문 리스트
  final List<List<String>> _sectionQuestions = [
    // 0: 증상 분석 (yourdisease)
    [
      "", // followUpQuestion으로 대체됨
      "운동 또는 스트레스와 관련이 있나요?",
      "지금까지 말한 증상말고 다른 증상이 있나요?",
    ],
    // 1: 악화 요인 (AggravatingPage)
    [
      "어떤 상황에서 증상이 더 심해지나요? (예: 움직이거나 눕거나 추울 때 등)",
    ],
    // 2: 위험 요인 (RiskFactorPage)
    [
      "현재 가지고 있는 질환이 있나요? (예: 당뇨, 고혈압, 암, 간질환 등)",
    ],
    // 3: 음주/흡연 (Drinking_smoking)
    [
      "평소에 얼마나 자주 음주를 하시나요?\n(예: 일주일에 몇 번, 한 번에 어느 정도 등)",
      "흡연을 하시나요? 혹은 주위에 흡연하는 사람이 있나요?\n(예: 네,아니요 등)",
    ],
    // 4: 직업 (JobPage)
    [
      "현재 어떤 일을 하고 계신가요?",
    ],
    // 5: 운동/스트레스 (Exercise_stress)
    [
      "평소 생활에서 운동이나 신체활동은 어느 정도 하시나요?",
    ],
    // 6: 과거 질환 (PastDisease)
    [
      "과거에 진단받은 만성 질환이 있나요?(예: 고혈압, 당뇨, 고지혈증, 심장질환, 간질환, 결합조직질환, 자가면역질환, 비만 등)",
    ],
  ];

  // 각 섹션별 API 엔드포인트
  final List<String> _sectionApiEndpoints = [
    "https://snumedai.store/api/analyze/symptoms",
    "https://snumedai.store/api/analyze/aggravation",
    "https://snumedai.store/api/analyze/riskfactor",
    "https://snumedai.store/api/analyze/drinking-smoking",
    "https://snumedai.store/api/analyze/job",
    "https://snumedai.store/api/analyze/exercise-stress",
    "https://snumedai.store/api/analyze/past-disease",
  ];

  // 각 섹션별 제목
  final List<String> _sectionTitles = [
    "증상 분석",
    "악화 요인 분석",
    "위험 요인 분석",
    "음주/흡연 분석",
    "직업 분석",
    "운동 및 스트레스 분석",
    "과거 질환 분석",
  ];

  final primaryColor = const Color(0xFF0F4C75);
  final secondaryColor = const Color(0xFF3282B8);

  @override
  void initState() {
    super.initState();
    
    // 첫 번째 섹션의 첫 번째 질문을 followUpQuestion으로 설정
    _sectionQuestions[0][0] = widget.followUpQuestion;
    
    // 첫 번째 질문을 대화 기록에 추가
    _conversationHistory.add({
      "role": "assistant",
      "content": widget.followUpQuestion,
    });

    // 초기 진입 시 initialUserInput이 있으면 한 번 키워드 추출 호출
    if ((widget.initialUserInput ?? "").trim().isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _extractInitialKeywords(widget.initialUserInput!.trim());
      });
    }
  }

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // 초기 진입 시 키워드 추출
  Future<void> _extractInitialKeywords(String initialQuestion) async {
    try {
      final url = Uri.parse(_sectionApiEndpoints[0]);

      final payload = {
        "question": initialQuestion,
        "answer": "네",
        "questionIndex": 0,
      };

      print("📤 초기 키워드 추출 요청: $payload");
      final sessionId = SessionManager.getSessionId();
      
      final headers = <String, String>{
        "Content-Type": "application/json",
      };
      
      // 세션 ID가 있으면 헤더에 추가
      if (sessionId != null) {
        headers["X-Session-Id"] = sessionId;
      }

      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode(payload),
      );
      
      // 응답에서 세션 ID 저장
      SessionManager.saveSessionIdFromResponse(response.headers);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final keywords = List<String>.from(data["keywords"] ?? []);

        if (keywords.isNotEmpty && mounted) {
          setState(() {
            for (final keyword in keywords) {
              if (!_allExtractedKeywords.contains(keyword)) {
                _allExtractedKeywords.add(keyword);
              }
            }
          });
        }
      } else {
        print("⚠️ 초기 추출 서버 오류: ${response.statusCode} - ${response.body}");
      }
    } catch (e) {
      print("❌ 초기 키워드 추출 오류: $e");
    }
  }

  String? get _currentQuestion {
    if (_isComplete) return null;
    if (_currentSectionIndex >= _sectionQuestions.length) return null;
    if (_currentQuestionIndex >= _sectionQuestions[_currentSectionIndex].length) return null;
    return _sectionQuestions[_currentSectionIndex][_currentQuestionIndex];
  }

  Future<void> _submitAnswer() async {
    final input = _inputController.text.trim();

    if (input.isEmpty) {
      _showSnackBar("답변을 입력해주세요.");
      return;
    }

    if (_isComplete) {
      _showSnackBar("모든 질문에 답변하셨습니다.");
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final currentQuestion = _currentQuestion;
    if (currentQuestion == null) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    // 대화 기록에 사용자 입력 추가
    _conversationHistory.add({
      "role": "user",
      "content": input,
    });

    try {
      final url = Uri.parse(_sectionApiEndpoints[_currentSectionIndex]);
      final payload = {
        "question": currentQuestion,
        "answer": input,
        "questionIndex": _currentQuestionIndex,
      };

      print("📤 요청 전송: $payload");
      final sessionId = SessionManager.getSessionId();
      
      final headers = <String, String>{
        "Content-Type": "application/json",
      };
      
      // 세션 ID가 있으면 헤더에 추가
      if (sessionId != null) {
        headers["X-Session-Id"] = sessionId;
      }

      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode(payload),
      );
      
      // 응답에서 세션 ID 저장
      SessionManager.saveSessionIdFromResponse(response.headers);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final keywords = List<String>.from(data["keywords"] ?? []);

        // 키워드 추가
        for (final keyword in keywords) {
          if (!_allExtractedKeywords.contains(keyword)) {
            setState(() {
              _allExtractedKeywords.add(keyword);
            });
          }
        }

        // 다음 질문으로 이동
        _currentQuestionIndex++;

        // 현재 섹션의 모든 질문이 끝났는지 확인
        if (_currentQuestionIndex >= _sectionQuestions[_currentSectionIndex].length) {
          // 다음 섹션으로 이동
          _currentSectionIndex++;
          _currentQuestionIndex = 0;

          // 모든 섹션이 끝났는지 확인
          if (_currentSectionIndex >= _sectionQuestions.length) {
            // 모든 질문 완료
            setState(() {
              _isComplete = true;
            });
          } else {
            // 다음 섹션의 첫 번째 질문 추가
            final nextQuestion = _sectionQuestions[_currentSectionIndex][0];
            _conversationHistory.add({
              "role": "assistant",
              "content": nextQuestion,
            });
          }
        } else {
          // 같은 섹션의 다음 질문 추가
          final nextQuestion = _sectionQuestions[_currentSectionIndex][_currentQuestionIndex];
          _conversationHistory.add({
            "role": "assistant",
            "content": nextQuestion,
          });
        }

        // 입력 필드 초기화
        _inputController.clear();

        // 스크롤을 맨 아래로
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

  String get _currentSectionTitle {
    if (_isComplete) return "모든 질문 완료";
    if (_currentSectionIndex >= _sectionTitles.length) return "완료";
    return _sectionTitles[_currentSectionIndex];
  }

  // 총 질문 수 계산
  int get _totalQuestions {
    int total = 0;
    for (var section in _sectionQuestions) {
      total += section.length;
    }
    return total;
  }

  // 현재까지 답변한 질문 수 계산
  int get _answeredQuestions {
    int answered = 0;
    for (int i = 0; i < _currentSectionIndex; i++) {
      answered += _sectionQuestions[i].length;
    }
    answered += _currentQuestionIndex;
    return answered;
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
        title: Text(
          _currentSectionTitle,
          style: const TextStyle(
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
          // 진행 상황 표시
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "진행 상황",
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      LinearProgressIndicator(
                        value: _isComplete
                            ? 1.0
                            : _answeredQuestions / _totalQuestions,
                        backgroundColor: Colors.grey[200],
                        valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                        minHeight: 6,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  "$_answeredQuestions/$_totalQuestions",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: primaryColor,
                  ),
                ),
              ],
            ),
          ),

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
                            color: isUser ? primaryColor : Colors.white,
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
                  if (_allExtractedKeywords.isNotEmpty)
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
                          ConstrainedBox(
                            constraints: BoxConstraints(
                              maxHeight: 80, // 약 2줄 정도의 높이 (키워드 Chip 높이 + runSpacing 고려)
                            ),
                            child: SingleChildScrollView(
                              scrollDirection: Axis.vertical,
                              child: Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: _allExtractedKeywords.map((keyword) {
                                  return Chip(
                                    label: Text(
                                      keyword,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w500,
                                        fontSize: 11,
                                      ),
                                    ),
                                    backgroundColor: primaryColor.withOpacity(0.1),
                                    side: BorderSide(color: primaryColor.withOpacity(0.3)),
                                    labelStyle: TextStyle(color: primaryColor, fontSize: 11),
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  );
                                }).toList(),
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
                        child: Icon(Icons.chat_bubble_outline, color: primaryColor, size: 24),
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
                              onPressed: (_isLoading || _isComplete) ? null : _submitAnswer,
                            ),
                    ),
                    onFieldSubmitted: (_) {
                      if (!_isLoading && !_isComplete) {
                        _submitAnswer();
                      }
                    },
                  ),
                ),
                const SizedBox(height: 12),
                // 결과 보기 버튼 (모든 질문 완료 시 활성화)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isComplete
                        ? () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const ResultPage()),
                            );
                          }
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isComplete ? primaryColor : Colors.grey[300],
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: _isComplete ? 2 : 0,
                    ),
                    child: Text(
                      "결과 보기",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: _isComplete ? Colors.white : Colors.grey,
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

