import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'main.dart';
import 'ChatConsultPage.dart';

class RefinedDiseasePage extends StatefulWidget {
  final String predictedDisease; // ✅ DiseaseResultPage에서 받은 질병 이름
  final String userInput;
  final List<String> selectedSymptoms;
  final Map<String, String?> questionHistory;// ✅ 추가
  final Map<String, String>? personalInfo;

  const RefinedDiseasePage({
    super.key,
    required this.predictedDisease,
    required this.userInput,
    required this.selectedSymptoms,
    required this.questionHistory,
    this.personalInfo,
  });

  @override
  State<RefinedDiseasePage> createState() => _RefinedDiseasePageState();
}

class _RefinedDiseasePageState extends State<RefinedDiseasePage> {
  String? diseaseDescription;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchDiseaseDescription();
  }

  // ✅ Gemini로 질병 설명 불러오기
  Future<void> _fetchDiseaseDescription() async {
    final prompt = """
당신은 전문 의료 해설가입니다.
아래 질병에 대해 일반인이 이해하기 쉬운 해설을 작성하세요.

형식:
1️⃣ 질병 개요  
2️⃣ 주요 원인  
3️⃣ 주요 증상  
4️⃣ 진단 및 치료 방법  
5️⃣ 예후 및 주의사항

질병: ${widget.predictedDisease}
""";

    try {
      final res = await http.post(
        Uri.parse(
            "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent"),
        headers: {
          "Content-Type": "application/json",
          "X-goog-api-key": "AIzaSyCIYlmRYTOdfi_qOtcxHlp046oqZC-3uPI", // 🔑 실제 키로 교체
        },
        body: jsonEncode({
          "contents": [
            {"parts": [{"text": prompt}]}
          ]
        }),
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final text =
        data["candidates"][0]["content"]["parts"][0]["text"].trim();
        setState(() {
          diseaseDescription = text;
          isLoading = false;
        });
      } else {
        setState(() {
          diseaseDescription = "⚠️ 질병 설명을 불러오지 못했습니다. (API 오류)";
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        diseaseDescription = "⚠️ 네트워크 오류로 설명을 불러올 수 없습니다.";
        isLoading = false;
      });
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
          child: isLoading
              ? _buildLoadingUI(isSmallScreen, primaryColor)
              : SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
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
                            "AI 진단 결과",
                            style: TextStyle(
                              fontSize: isSmallScreen ? 20 : 24,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "정확한 진단을 위해 의료진 상담을 권장합니다",
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
                
                // 메인 결과 카드
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // 헤더 섹션
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(isSmallScreen ? 20 : 24),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [primaryColor.withOpacity(0.1), primaryColor.withOpacity(0.05)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(24),
                            topRight: Radius.circular(24),
                          ),
                        ),
                        child: _buildHeader(primaryColor, isSmallScreen),
                      ),
                      
                      // 질병 설명 섹션
                      Padding(
                        padding: EdgeInsets.all(isSmallScreen ? 20 : 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 섹션 제목
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: primaryColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    Icons.medical_information,
                                    color: primaryColor,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  "질병 상세 정보",
                                  style: TextStyle(
                                    fontSize: isSmallScreen ? 16 : 18,
                                    fontWeight: FontWeight.w700,
                                    color: primaryColor,
                                  ),
                                ),
                              ],
                            ),
                            
                            const SizedBox(height: 16),
                            
                            // 질병 설명
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.grey[50],
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: primaryColor.withOpacity(0.1),
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                diseaseDescription ?? "AI가 질병 설명을 불러오는 중입니다...",
                                style: TextStyle(
                                  fontSize: isSmallScreen ? 14 : 15,
                                  height: 1.6,
                                  color: Colors.grey[800],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // 액션 버튼들
                _buildActionButtons(context, primaryColor, isSmallScreen),
                
                const SizedBox(height: 16),
                
                // 문진표 버튼
                _buildQuestionnaireButton(context, primaryColor, isSmallScreen),
                
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ✅ 로딩 UI
  Widget _buildLoadingUI(bool isSmallScreen, Color primaryColor) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(isSmallScreen ? 24 : 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // AI 분석 아이콘
            Container(
              width: isSmallScreen ? 100 : 120,
              height: isSmallScreen ? 100 : 120,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [primaryColor, primaryColor.withOpacity(0.7)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: primaryColor.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Icon(
                Icons.psychology,
                color: Colors.white,
                size: isSmallScreen ? 50 : 60,
              ),
            ),
            
            SizedBox(height: isSmallScreen ? 24 : 32),
            
            // 로딩 텍스트
            Text(
              "AI가 질병 정보를 분석 중입니다",
              style: TextStyle(
                fontSize: isSmallScreen ? 18 : 20,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 8),
            
            Text(
              "잠시만 기다려주세요...",
              style: TextStyle(
                fontSize: isSmallScreen ? 14 : 16,
                color: Colors.white.withOpacity(0.8),
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 32),
            
            // 로딩 인디케이터
            CircularProgressIndicator(
              color: Colors.white,
              strokeWidth: 3,
            ),
          ],
        ),
      ),
    );
  }

  // ✅ 상단 헤더
  Widget _buildHeader(Color primaryColor, bool isSmallScreen) {
    return Center(
      child: Column(
        children: [
          // 성공 아이콘
          Container(
            width: isSmallScreen ? 80 : 100,
            height: isSmallScreen ? 80 : 100,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.green, Colors.green[400]!],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.green.withOpacity(0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Icon(
              Icons.check_circle,
              color: Colors.white,
              size: isSmallScreen ? 40 : 50,
            ),
          ),
          
          SizedBox(height: isSmallScreen ? 16 : 20),
          
          Text(
            "AI 분석 완료",
            style: TextStyle(
              fontSize: isSmallScreen ? 18 : 20,
              fontWeight: FontWeight.w700,
              color: primaryColor,
            ),
          ),
          
          const SizedBox(height: 8),
          
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: primaryColor.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Text(
              "예상 질병: ${widget.predictedDisease}",
              style: TextStyle(
                fontSize: isSmallScreen ? 16 : 18,
                fontWeight: FontWeight.w600,
                color: primaryColor,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  // ✅ 문진표 버튼
  Widget _buildQuestionnaireButton(BuildContext context, Color primaryColor, bool isSmallScreen) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: primaryColor.withOpacity(0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => QuestionnairePage(
                  questionHistory: widget.questionHistory,
                  predictedDisease: widget.predictedDisease,
                  userInput: widget.userInput,
                  selectedSymptoms: widget.selectedSymptoms,
                  personalInfo: widget.personalInfo,
                ),
              ),
            );
          },
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: 20,
              vertical: isSmallScreen ? 16 : 18,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.assignment_outlined,
                  color: primaryColor,
                  size: isSmallScreen ? 20 : 22,
                ),
                const SizedBox(width: 12),
                Text(
                  "문진표 보기",
                  style: TextStyle(
                    color: primaryColor,
                    fontSize: isSmallScreen ? 16 : 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ✅ 액션 버튼들
  Widget _buildActionButtons(BuildContext context, Color primaryColor, bool isSmallScreen) {
    return Column(
      children: [
        // AI 상담 버튼
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [primaryColor, primaryColor.withOpacity(0.8)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: primaryColor.withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ChatConsultPage(
                      diseaseName: widget.predictedDisease,
                    ),
                  ),
                );
              },
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: isSmallScreen ? 16 : 18,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.chat_bubble_outline,
                      color: Colors.white,
                      size: isSmallScreen ? 20 : 22,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      "AI에게 후속 질문하기",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: isSmallScreen ? 16 : 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        
        const SizedBox(height: 16),
        
        // 홈으로 돌아가기 버튼
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: primaryColor.withOpacity(0.3),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => HomeBackground()),
                      (route) => false,
                );
              },
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: isSmallScreen ? 16 : 18,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.home_outlined,
                      color: primaryColor,
                      size: isSmallScreen ? 20 : 22,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      "홈으로 돌아가기",
                      style: TextStyle(
                        color: primaryColor,
                        fontSize: isSmallScreen ? 16 : 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        
        const SizedBox(height: 20),
        
        // 주의사항 안내
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.amber[50],
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.amber.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: Colors.amber[700],
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  "이 결과는 참고용이며, 정확한 진단을 위해서는 의료진 상담을 받으시기 바랍니다.",
                  style: TextStyle(
                    fontSize: isSmallScreen ? 12 : 13,
                    color: Colors.amber[800],
                    fontWeight: FontWeight.w500,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ✅ 문진표 페이지
class QuestionnairePage extends StatefulWidget {
  final Map<String, String?> questionHistory;
  final String predictedDisease;
  final String userInput;
  final List<String> selectedSymptoms;
  final Map<String, String>? personalInfo;

  const QuestionnairePage({
    super.key,
    required this.questionHistory,
    required this.predictedDisease,
    required this.userInput,
    required this.selectedSymptoms,
    this.personalInfo,
  });

  @override
  State<QuestionnairePage> createState() => _QuestionnairePageState();
}

class _QuestionnairePageState extends State<QuestionnairePage> {
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
                padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
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
                            "문진표",
                            style: TextStyle(
                              fontSize: isSmallScreen ? 20 : 24,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "전체 문진 내용을 확인하세요",
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
              
              // 문진표 내용
              Expanded(
                child: Container(
                  margin: EdgeInsets.all(screenWidth * 0.05),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // 헤더
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(isSmallScreen ? 20 : 24),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [primaryColor.withOpacity(0.1), primaryColor.withOpacity(0.05)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(24),
                            topRight: Radius.circular(24),
                          ),
                        ),
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: primaryColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Icon(
                                Icons.assignment_outlined,
                                color: primaryColor,
                                size: isSmallScreen ? 32 : 40,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              "문진표",
                              style: TextStyle(
                                fontSize: isSmallScreen ? 20 : 24,
                                fontWeight: FontWeight.w700,
                                color: primaryColor,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "예상 질병: ${widget.predictedDisease}",
                              style: TextStyle(
                                fontSize: isSmallScreen ? 14 : 16,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      // 문진 내용 리스트
                      Expanded(
                        child: SingleChildScrollView(
                          padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // 초기 증상 정보
                              _buildSection(
                                "초기 증상",
                                Icons.sick,
                                [
                                  "사용자 입력: ${widget.userInput}",
                                  "선택된 증상: ${widget.selectedSymptoms.join(', ')}",
                                ],
                                primaryColor,
                                isSmallScreen,
                              ),
                              
                              const SizedBox(height: 20),

                              // 개인정보 섹션 (개인정보가 있을 때만 표시)
                              if (widget.personalInfo != null) ...[
                                _buildSection(
                                  "개인정보",
                                  Icons.person_outline,
                                  [
                                    "나이: ${widget.personalInfo!['age']}세",
                                    "몸무게: ${widget.personalInfo!['weight']}kg",
                                    "성별: ${widget.personalInfo!['gender']}",
                                    "음주: ${widget.personalInfo!['drinking']}",
                                    "흡연: ${widget.personalInfo!['smoking']}",
                                    "직업: ${widget.personalInfo!['job']}",
                                    "운동: ${widget.personalInfo!['exercise']}",
                                    "과거질환: ${widget.personalInfo!['pastDiseases']}",
                                  ],
                                  primaryColor,
                                  isSmallScreen,
                                ),
                                
                                const SizedBox(height: 20),
                              ],
                              
                              // 문진 질문과 답변
                              _buildSection(
                                "문진 질문 및 답변",
                                Icons.quiz,
                                widget.questionHistory.entries.map((entry) {
                                  return "Q. ${entry.key}\nA. ${_getAnswerText(entry.value)}";
                                }).toList(),
                                primaryColor,
                                isSmallScreen,
                              ),
                            ],
                          ),
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

  Widget _buildSection(String title, IconData icon, List<String> items, Color primaryColor, bool isSmallScreen) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: primaryColor.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 섹션 헤더
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.05),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
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
                    icon,
                    color: primaryColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: isSmallScreen ? 16 : 18,
                    fontWeight: FontWeight.w700,
                    color: primaryColor,
                  ),
                ),
              ],
            ),
          ),
          
          // 섹션 내용
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: items.asMap().entries.map((entry) {
                final index = entry.key;
                final item = entry.value;
                return Container(
                  margin: EdgeInsets.only(bottom: index < items.length - 1 ? 12 : 0),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.grey[200]!,
                      width: 1,
                    ),
                  ),
                  child: Text(
                    item,
                    style: TextStyle(
                      fontSize: isSmallScreen ? 13 : 14,
                      height: 1.5,
                      color: Colors.grey[800],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  String _getAnswerText(String? answer) {
    if (answer == null) return "답변 없음";
    
    switch (answer) {
      case "1":
        return "전혀 그렇지 않다";
      case "2":
        return "그렇지 않다";
      case "3":
        return "보통이다";
      case "4":
        return "그렇다";
      case "5":
        return "매우 그렇다";
      default:
        return answer;
    }
  }
}
