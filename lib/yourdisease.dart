//두번째 페이지
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'DiseaseDataManager.dart';
import 'AggravatingPage.dart';

class YourDiseasePage extends StatefulWidget {
  final String? followUpQuestion;
  final String? similarSentence;

  const YourDiseasePage({
    super.key,
    this.followUpQuestion,
    this.similarSentence,
  });

  @override
  State<YourDiseasePage> createState() => _YourDiseasePageState();
}

class _YourDiseasePageState extends State<YourDiseasePage> {

  late String _currentQuestion;
  bool _isLoading = false;
  int _questionStep = 1; // 현재 질문 단계 (1~4)
  final int _maxQuestions = 4; // 마지막은 "다른 증상 있나요?"
  final Set<String> _allSelectedSymptoms = {}; // 전체 누적 증상
  final Map<String, Map<String, dynamic>> _aggregatedDiseases = {};
  bool _isLastStep = false; // 마지막 질문 여부
  static const String _finalQuestionText = "지금까지 말한 증상 말고 다른 증상이 있나요?";
  static const String _completedQuestionText = "모든 질문이 완료되었습니다. 다음 단계 버튼을 눌러주세요.";
  bool _canProceedNextStep = false;
  bool _initialExtractionDone = false;

  int get _answeredQuestionCount {
    if (_canProceedNextStep) {
      return _maxQuestions;
    }
    final count = _questionStep - 1;
    if (count < 0) {
      return 0;
    }
    return count > _maxQuestions ? _maxQuestions : count;
  }

  int get _remainingQuestionCount {
    final remaining = _maxQuestions - _answeredQuestionCount;
    if (remaining < 0) {
      return 0;
    }
    return remaining;
  }

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

  @override
  void initState() {
    super.initState();
    final question = widget.followUpQuestion?.trim();
    _currentQuestion = (question != null && question.isNotEmpty)
        ? question
        : "가슴이 아픈게 어떻게 아프시고\n관련된 증상이 더 있나요";

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _runInitialSymptomExtraction();
    });
  }
  
  Future<void> _handleUserInput(String input) async {
    if (_isLoading) return;
    final wasFinalQuestion =
        _isLastStep && _currentQuestion.trim() == _finalQuestionText;

    final newSymptoms = await _matchSymptoms(input, showConfirmation: false);

    if (wasFinalQuestion) {
      _controller.clear();
      setState(() {
        _canProceedNextStep = true;
        _currentQuestion = _completedQuestionText;
      });
      return;
    }

    setState(() {
      _questionStep++;

      if (_questionStep == _maxQuestions) {
        _currentQuestion = _finalQuestionText;
        _isLastStep = true;
        _canProceedNextStep = false;
      } else {
        _canProceedNextStep = false;
      }
    });

    if (newSymptoms.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("추출된 증상이 없지만 다음 질문으로 진행합니다.")),
      );
    }

    _controller.clear();
  }

  Future<void> _finishSurvey() async {
    if (selectedSymptoms.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("AI가 추출한 증상을 먼저 확인해주세요.")),
      );
      return;
    }

    final aggregatedList = _aggregatedDiseases.values.where((disease) {
      final symptoms = List<String>.from(disease["증상"] ?? const []);
      if (symptoms.isEmpty) return false;
      return _allSelectedSymptoms.any(symptoms.contains);
    }).toList();

    if (aggregatedList.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("저장할 질병 정보를 찾지 못했지만 다음 단계로 진행합니다."),
        ),
      );
    } else {
      final manager = DiseaseDataManager();
      debugPrint(
          "💾 저장할 질병 목록: ${aggregatedList.map((d) => d['질환명']).toList()} (${aggregatedList.length}개)");

      final selectedSymptomList = _allSelectedSymptoms
          .map((symptom) => symptom.trim())
          .where((symptom) => symptom.isNotEmpty)
          .toList();

      manager.addScoresForKeywordMatches(
        diseases: aggregatedList,
        keywords: selectedSymptomList,
        attributeKey: '증상',
      );

      final dedupedDiseases = <String, Map<String, dynamic>>{
        for (final disease in aggregatedList)
          (disease['질환명']?.toString() ?? jsonEncode(disease)): disease,
      };
      final symptomMatches = <String, List<String>>{};

      for (final symptom in selectedSymptomList) {
        final matched = <String>[];
        for (final entry in dedupedDiseases.entries) {
          final symptomField = entry.value['증상'];
          if (symptomField is String) {
            if (symptomField.trim() == symptom) {
              matched.add(entry.key);
            }
          } else if (symptomField is Iterable) {
            final values = symptomField
                .map((value) => value.toString().trim())
                .where((value) => value.isNotEmpty)
                .toSet();
            if (values.contains(symptom)) {
              matched.add(entry.key);
            }
          }
        }
        if (matched.isNotEmpty) {
          symptomMatches[symptom] = matched;
        }
      }

      manager.printScoreTotals();
      debugPrint("🧩 증상별 점수 누적 현황: $symptomMatches");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("누적 증상 기반으로 ${aggregatedList.length}개 질병을 저장했습니다.")),
      );
    }

    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AggravatingPage(),
      ),
    );

    if (!mounted) return;
    setState(() {
      _canProceedNextStep = false;
    });
  }


  
  void _showConfirmDialog(BuildContext context, List<String> matchedSymptoms) {
    final TextEditingController popupController = TextEditingController();
    final primaryColor = const Color(0xFF0F4C75);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              child: Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.8,
                  maxWidth: MediaQuery.of(context).size.width * 0.9,
                ),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  gradient: LinearGradient(
                    colors: [Colors.white, const Color(0xFFF8F9FA)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: primaryColor.withOpacity(0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                    // 제목 + 아이콘
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(Icons.check_circle, color: primaryColor, size: 24),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          "증상 확인",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: primaryColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // 선택된 증상 리스트
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: primaryColor.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: primaryColor.withOpacity(0.2)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "선택된 증상 (${selectedSymptoms.length}개)",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: primaryColor,
                            ),
                          ),
                          const SizedBox(height: 8),
                          // 증상이 많을 때 스크롤 가능하도록 제한
                          ConstrainedBox(
                            constraints: BoxConstraints(
                              maxHeight: 200, // 최대 높이 제한
                            ),
                            child: SingleChildScrollView(
                              child: Column(
                                children: selectedSymptoms.map((symptom) {
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 3),
                                    child: Row(
                                      children: [
                                        Icon(Icons.check_circle, color: primaryColor, size: 16),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            symptom, 
                                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // 추가 입력창
                    TextField(
                      controller: popupController,
                      decoration: InputDecoration(
                        hintText: "추가 증상이 있나요?",
                        hintStyle: TextStyle(color: Colors.grey[400]),
                        prefixIcon: Icon(Icons.add_comment, color: primaryColor),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: primaryColor.withOpacity(0.3)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: Colors.grey.withOpacity(0.3)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: primaryColor, width: 2),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // 버튼 영역
                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(color: Colors.grey.withOpacity(0.3)),
                              ),
                            ),
                            onPressed: () {
                              Navigator.pop(context); // 팝업 닫기
                              
                            },
                            child: Text(
                              "없습니다",
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryColor,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              elevation: 2,
                            ),
                            onPressed: () async {
                              final newInput = popupController.text.trim();
                              if (newInput.isNotEmpty) {
                                final newMatches = await _matchSymptoms(
                                  newInput,
                                  showConfirmation: false,
                                );
                                if (newMatches.isNotEmpty) {
                                  setStateDialog(() {}); // 팝업 UI 갱신
                                  popupController.clear();
                                }
                              }
                            },
                            child: const Text(
                              "추가 입력",
                              style: TextStyle(
                                color: Colors.white, 
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    )
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }





  Future<List<String>> _matchSymptoms(
    String input, {
    bool showConfirmation = true,
    String? questionOverride,
  }) async {
    final trimmedInput = input.trim();
    if (trimmedInput.isEmpty) return [];

    final payload = {
      "question": questionOverride ?? _currentQuestion,
      "answer": trimmedInput,
      "symptomCategories": symptomCategories,
      "previousSymptoms": selectedSymptoms.toList(),
    };

    final url = Uri.parse("http://localhost:8080/api/analyze/symptoms");

    try {
      setState(() {
        _isLoading = true;
      });

      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final nextQuestion = (data["nextQuestion"] as String?)?.trim();
        final matchedSymptoms =
            List<String>.from(data["matchedSymptoms"] ?? []).map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
        final diseases =
            List<Map<String, dynamic>>.from(data["diseases"] ?? []);

        if (matchedSymptoms.isNotEmpty) {
          setState(() {
            selectedSymptoms.addAll(matchedSymptoms);
            _allSelectedSymptoms.addAll(matchedSymptoms);
            for (final disease in diseases) {
              final rawName = disease["질환명"];
              if (rawName == null) continue;
              final name = rawName.toString().trim();
              if (name.isEmpty) continue;
              _aggregatedDiseases[name] = disease;
            }
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("증상을 매칭하지 못했습니다.")),
          );
        }

        if (nextQuestion != null && nextQuestion.isNotEmpty) {
          setState(() {
            _currentQuestion = nextQuestion;
          });
        } else if (matchedSymptoms.isNotEmpty && showConfirmation) {
          _showConfirmDialog(context, matchedSymptoms);
        }

        _controller.clear();
        return matchedSymptoms;
      } else {
        print("⚠️ 서버 오류: ${response.statusCode}");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("서버 오류가 발생했습니다 (${response.statusCode})")),
        );
      }
    } catch (e) {
      print("💥 서버 연결 오류: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("서버 연결 오류가 발생했습니다: $e")),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }

    return [];
  }

  Future<void> _runInitialSymptomExtraction() async {
    if (_initialExtractionDone) return;
    final similarSentence = widget.similarSentence?.trim();
    if (similarSentence == null || similarSentence.isEmpty) {
      _initialExtractionDone = true;
      return;
    }

    _initialExtractionDone = true;
    await _matchSymptoms(
      "네",
      showConfirmation: false,
      questionOverride: similarSentence,
    );
  }




  String _buildFollowUpText() {
    return _currentQuestion;
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = const Color(0xFF0F4C75); // main.dart와 동일한 색상
    final secondaryColor = const Color(0xFF3282B8);
    final answeredQuestions = _answeredQuestionCount;
    final remainingQuestions = _remainingQuestionCount;
    final double progress = _maxQuestions == 0
        ? 0
        : answeredQuestions.clamp(0, _maxQuestions) / _maxQuestions;

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
          "증상 입력 / 선택", 
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
      body: SingleChildScrollView(
        child: Column(
          children: [
            // AI 기반 증상 매칭 시스템 안내
          

            // 증상 입력 섹션
            Container(
              width: double.infinity,
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(20),
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
                  // 섹션 제목
                  Row(
                    children: [
                      Icon(
                        Icons.edit_note,
                        color: primaryColor,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          _buildFollowUpText(),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: primaryColor,
                          ),
                          softWrap: true,
                          overflow: TextOverflow.visible,
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
                        hintText: "입력칸에 증상을 입력해주세요",
                        hintStyle: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 14,
                        ),
                        prefixIcon: Icon(Icons.medical_services, color: primaryColor),
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
                  
                  const SizedBox(height: 16),
                  
                  // 확인 버튼
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
                      onPressed: _isLoading
                          ? null
                          : () => _handleUserInput(_controller.text),
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
                  if (_isLoading) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: primaryColor,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          "AI가 응답을 분석하고 있어요...",
                          style: TextStyle(
                            color: primaryColor,
                            fontWeight: FontWeight.w500,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 20),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: primaryColor.withOpacity(0.1),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.timeline, color: secondaryColor, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          "지금까지 누적된 증상",
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: secondaryColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (_allSelectedSymptoms.isEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          vertical: 24,
                          horizontal: 12,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5F9FF),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          "AI 분석 결과가 여기에 표시됩니다.",
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                            height: 1.4,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      )
                    else
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _allSelectedSymptoms.map((symptom) {
                          return Chip(
                            label: Text(
                              symptom,
                              style: TextStyle(color: primaryColor),
                            ),
                            backgroundColor: primaryColor.withOpacity(0.1),
                          );
                        }).toList(),
                      ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 100), // 하단 네비게이션 바 공간 확보
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
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
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: (_canProceedNextStep ? primaryColor : secondaryColor)
                      .withOpacity(0.08),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _canProceedNextStep
                              ? Icons.check_circle
                              : Icons.assignment_outlined,
                          color: _canProceedNextStep
                              ? primaryColor
                              : secondaryColor,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _canProceedNextStep
                                ? "모든 질문을 완료했습니다!"
                                : "남은 질문 ${remainingQuestions}개 · 총 $_maxQuestions개",
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: _canProceedNextStep
                                  ? primaryColor
                                  : secondaryColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 6,
                        backgroundColor: Colors.grey[300],
                        valueColor: AlwaysStoppedAnimation<Color>(
                          _canProceedNextStep ? primaryColor : secondaryColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: _canProceedNextStep ? _finishSurvey : null,
                  style: ElevatedButton.styleFrom(
                    elevation: _canProceedNextStep ? 4 : 0,
                    backgroundColor: _canProceedNextStep
                        ? Colors.transparent
                        : Colors.grey[300],
                    shadowColor: _canProceedNextStep
                        ? Colors.black26
                        : Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: EdgeInsets.zero,
                  ),
                  child: _canProceedNextStep
                      ? Ink(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [primaryColor, secondaryColor],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Container(
                            alignment: Alignment.center,
                            child: Text(
                              "다음 단계로 (${_allSelectedSymptoms.length}개 증상)",
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        )
                      : Container(
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Text(
                            "모든 질문을 완료하면 다음 단계가 활성화됩니다",
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Colors.black54,
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