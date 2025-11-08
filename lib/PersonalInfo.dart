import 'package:flutter/material.dart';
import 'DiseaseDataManager.dart';
import 'isdiseaseright.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class PersonalInfoPage extends StatefulWidget {
  const PersonalInfoPage({super.key});

  @override
  State<PersonalInfoPage> createState() => _PersonalInfoPageState();
}

class _PersonalInfoPageState extends State<PersonalInfoPage>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // 개인정보 입력 필드들
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _jobController = TextEditingController();
  final TextEditingController _pastDiseasesController = TextEditingController();
  final TextEditingController _drinkingController = TextEditingController();
  final TextEditingController _smokingController = TextEditingController();
  final TextEditingController _exerciseController = TextEditingController();
  
  String? _selectedGender;

  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    
    // 새로운 진단 시작 시 전역 데이터 초기화
    DiseaseDataManager().initializeNewDiagnosis();
    
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic));

    _fadeController.forward();
    Future.delayed(const Duration(milliseconds: 200), () {
      _slideController.forward();
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _ageController.dispose();
    _weightController.dispose();
    _jobController.dispose();
    _pastDiseasesController.dispose();
    _drinkingController.dispose();
    _smokingController.dispose();
    _exerciseController.dispose();
    super.dispose();
  }

  void _submitForm() async {
    if (_formKey.currentState!.validate() && 
        _selectedGender != null) {
      
      // 로딩 표시
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );
      
      // 개인정보를 Map으로 정리
      final personalInfo = <String, dynamic>{
        'age': _ageController.text,
        'weight': _weightController.text,
        'gender': _selectedGender!,
        'drinking': _drinkingController.text,
        'smoking': _smokingController.text,
        'job': _jobController.text,
        'exercise': _exerciseController.text,
        'pastDiseases': _pastDiseasesController.text,
      };

      try {
        // 개인정보 분석 실행
        final response = await http.post(
          Uri.parse("http://localhost:8080/api/analyze/social-history"), // Node.js 서버 주소
          headers: {"Content-Type": "application/json"},
          body: jsonEncode(personalInfo),
        );

        if (response.statusCode == 200) {
          final analysisResult = jsonDecode(response.body); // ✅ 백엔드에서 보낸 JSON 응답
          // 이후 로직 그대로 유지 가능
          final pastDiseases = (analysisResult['pastDiseases'] as List<dynamic>? ?? [])
              .map((d) => d as Map<String, dynamic>)
              .toList();
          final socialDiseases = (analysisResult['socialDiseases'] as List<dynamic>? ?? [])
              .map((d) => d as Map<String, dynamic>)
              .toList();

          DiseaseDataManager().setPastDiseases(pastDiseases);
          DiseaseDataManager().setSocialDiseases(socialDiseases);
        } else {
          print("⚠️ 서버 오류: ${response.statusCode}");
        }
        



        // AggravatingPage로 이동하면서 개인정보 전달
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => IsDiseaseRightPage(),
          ),
        );
      } catch (e) {
        // 로딩 다이얼로그 닫기
        Navigator.pop(context);
        print("❌ 개인정보 분석 중 오류: $e");
        _submitForm();

        
       
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("모든 항목을 입력해주세요."),
          backgroundColor: const Color(0xFF0F4C75),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
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
                padding: const EdgeInsets.all(20),
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
                            "개인정보 입력",
                            style: TextStyle(
                              fontSize: isSmallScreen ? 20 : 24,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "정확한 진단을 위해 개인정보를 입력해주세요",
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
              
              // 개인정보 입력 폼
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        // 나이 입력
                        _buildInputCard(
                          icon: Icons.cake,
                          title: "나이",
                          child: TextFormField(
                            controller: _ageController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              hintText: "나이를 입력하세요",
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              filled: true,
                              fillColor: Colors.grey[100],
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return "나이를 입력해주세요";
                              }
                              final age = int.tryParse(value);
                              if (age == null || age < 0 || age > 150) {
                                return "올바른 나이를 입력해주세요";
                              }
                              return null;
                            },
                          ),
                        ),

                        const SizedBox(height: 16),

                        // 몸무게 입력
                        _buildInputCard(
                          icon: Icons.monitor_weight,
                          title: "몸무게 (kg)",
                          child: TextFormField(
                            controller: _weightController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              hintText: "몸무게를 입력하세요",
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              filled: true,
                              fillColor: Colors.grey[100],
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return "몸무게를 입력해주세요";
                              }
                              final weight = double.tryParse(value);
                              if (weight == null || weight < 0 || weight > 500) {
                                return "올바른 몸무게를 입력해주세요";
                              }
                              return null;
                            },
                          ),
                        ),

                        const SizedBox(height: 16),

                        // 성별 선택
                        _buildInputCard(
                          icon: Icons.person,
                          title: "성별",
                          child: Row(
                            children: [
                              Expanded(
                                child: _buildSelectionButton(
                                  "남성",
                                  _selectedGender == "남성",
                                  () => setState(() => _selectedGender = "남성"),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildSelectionButton(
                                  "여성",
                                  _selectedGender == "여성",
                                  () => setState(() => _selectedGender = "여성"),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        // 음주 여부
                        _buildInputCard(
                          icon: Icons.local_drink,
                          title: "음주 여부",
                          child: TextFormField(
                            controller: _drinkingController,
                            decoration: const InputDecoration(
                              hintText: "예: 주 2-3회, 소주 1-2병 정도 마심",
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.all(12),
                            ),
                            maxLines: 2,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return '음주 여부를 입력해주세요';
                              }
                              return null;
                            },
                          ),
                        ),

                        const SizedBox(height: 16),

                        // 흡연 여부
                        _buildInputCard(
                          icon: Icons.smoking_rooms,
                          title: "흡연 여부",
                          child: TextFormField(
                            controller: _smokingController,
                            decoration: const InputDecoration(
                              hintText: "예: 하루 1갑 정도, 금연 3년차, 전혀 안 함",
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.all(12),
                            ),
                            maxLines: 2,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return '흡연 여부를 입력해주세요';
                              }
                              return null;
                            },
                          ),
                        ),

                        const SizedBox(height: 16),

                        // 직업 입력
                        _buildInputCard(
                          icon: Icons.work,
                          title: "직업",
                          child: TextFormField(
                            controller: _jobController,
                            decoration: InputDecoration(
                              hintText: "직업을 입력하세요",
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              filled: true,
                              fillColor: Colors.grey[100],
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return "직업을 입력해주세요";
                              }
                              return null;
                            },
                          ),
                        ),

                        const SizedBox(height: 16),

                        // 정기적인 운동 여부
                        _buildInputCard(
                          icon: Icons.fitness_center,
                          title: "정기적인 운동 여부",
                          child: TextFormField(
                            controller: _exerciseController,
                            decoration: const InputDecoration(
                              hintText: "예: 주 3회 헬스장, 매일 30분 걷기, 거의 안 함",
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.all(12),
                            ),
                            maxLines: 2,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return '운동 여부를 입력해주세요';
                              }
                              return null;
                            },
                          ),
                        ),

                        const SizedBox(height: 16),

                        // 과거 질환 이력
                        _buildInputCard(
                          icon: Icons.medical_services,
                          title: "과거 질환 이력",
                          child: TextFormField(
                            controller: _pastDiseasesController,
                            maxLines: 3,
                            decoration: InputDecoration(
                              hintText: "과거에 앓았던 질병을 입력하세요 (없으면 '없음' 입력)",
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              filled: true,
                              fillColor: Colors.grey[100],
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return "과거 질환 이력을 입력해주세요";
                              }
                              return null;
                            },
                          ),
                        ),

                        const SizedBox(height: 32),

                        // 제출 버튼
                        FadeTransition(
                          opacity: _fadeAnimation,
                          child: SlideTransition(
                            position: _slideAnimation,
                            child: SizedBox(
                              width: double.infinity,
                              height: 56,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  elevation: 4,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  padding: EdgeInsets.zero,
                                ),
                                onPressed: _submitForm,
                                child: Ink(
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
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.arrow_forward,
                                          color: Colors.white,
                                          size: 20,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          "진단 시작하기",
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),
                      ],
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

  Widget _buildInputCard({
    required IconData icon,
    required String title,
    required Widget child,
  }) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Container(
          padding: const EdgeInsets.all(20),
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
              color: Colors.white.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F4C75).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      icon,
                      color: const Color(0xFF0F4C75),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A202C),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              child,
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSelectionButton(String text, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected 
              ? const Color(0xFF0F4C75).withOpacity(0.1)
              : Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected 
                ? const Color(0xFF0F4C75)
                : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: isSelected 
                ? const Color(0xFF0F4C75)
                : Colors.grey[700],
          ),
        ),
      ),
    );
  }
}