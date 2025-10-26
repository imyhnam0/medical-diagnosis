import 'package:flutter/material.dart';
import 'isdiseaseright.dart';

class SymptomSelectPage extends StatefulWidget {
  const SymptomSelectPage({super.key});

  @override
  State<SymptomSelectPage> createState() => _SymptomSelectPageState();
}

class _SymptomSelectPageState extends State<SymptomSelectPage>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    
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

    final List<Map<String, dynamic>> symptoms = [
      {
        "title": "흉통 (가슴 통증)", 
        "subtitle": "심장, 폐, 흉벽 관련 통증",
        "icon": Icons.favorite, 
        "color": const Color(0xFFE53E3E),
        "gradient": [const Color(0xFFE53E3E), const Color(0xFFFC8181)]
      },
      {
        "title": "복통 (배 통증)", 
        "subtitle": "소화기, 비뇨기, 부인과 관련 통증",
        "icon": Icons.medical_services, 
        "color": const Color(0xFFED8936),
        "gradient": [const Color(0xFFED8936), const Color(0xFFF6AD55)]
      },
      {
        "title": "두통 (머리 통증)", 
        "subtitle": "긴장성, 편두통, 군발성 두통",
        "icon": Icons.psychology, 
        "color": const Color(0xFF3182CE),
        "gradient": [const Color(0xFF3182CE), const Color(0xFF63B3ED)]
      },
      {
        "title": "호흡곤란", 
        "subtitle": "호흡기, 심혈관 관련 호흡 문제",
        "icon": Icons.air, 
        "color": const Color(0xFF38A169),
        "gradient": [const Color(0xFF38A169), const Color(0xFF68D391)]
      },
      {
        "title": "피로감 / 무기력", 
        "subtitle": "만성피로, 전신 무력감",
        "icon": Icons.battery_alert, 
        "color": const Color(0xFFD69E2E),
        "gradient": [const Color(0xFFD69E2E), const Color(0xFFF6E05E)]
      },
      {
        "title": "어지럼증", 
        "subtitle": "현훈, 실신, 균형감각 이상",
        "icon": Icons.blur_circular, 
        "color": const Color(0xFF805AD5),
        "gradient": [const Color(0xFF805AD5), const Color(0xFFB794F6)]
      },
    ];

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
                            "증상별 진단",
                            style: TextStyle(
                              fontSize: isSmallScreen ? 20 : 24,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "어떤 증상으로 진단을 받고 싶으신가요?",
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
              
              // 증상 목록
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
                  child: Column(
                    children: symptoms.asMap().entries.map((entry) {
                      final index = entry.key;
                      final item = entry.value;
                      
                      return FadeTransition(
                        opacity: _fadeAnimation,
                        child: SlideTransition(
                          position: _slideAnimation,
                          child: Container(
                            margin: EdgeInsets.only(
                              bottom: isSmallScreen ? 12 : 16,
                              top: index == 0 ? 0 : 0,
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(20),
                                onTap: () {
                                  // ✅ 흉통 선택 시에만 현재는 IsDiseaseRightPage로 이동
                                  if (item["title"].toString().contains("흉통")) {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => const IsDiseaseRightPage(),
                                      ),
                                    );
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text("${item['title']} 판별은 곧 추가될 예정입니다."),
                                        backgroundColor: primaryColor,
                                        behavior: SnackBarBehavior.floating,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                      ),
                                    );
                                  }
                                },
                                child: Container(
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
                                      color: Colors.white.withOpacity(0.2),
                                      width: 1,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      // 아이콘 영역
                                      Container(
                                        width: isSmallScreen ? 60 : 70,
                                        height: isSmallScreen ? 60 : 70,
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: item["gradient"] as List<Color>,
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                          ),
                                          borderRadius: BorderRadius.circular(16),
                                          boxShadow: [
                                            BoxShadow(
                                              color: (item["color"] as Color).withOpacity(0.3),
                                              blurRadius: 10,
                                              offset: const Offset(0, 4),
                                            ),
                                          ],
                                        ),
                                        child: Icon(
                                          item["icon"] as IconData,
                                          color: Colors.white,
                                          size: isSmallScreen ? 28 : 32,
                                        ),
                                      ),
                                      
                                      const SizedBox(width: 16),
                                      
                                      // 텍스트 영역
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              item["title"] as String,
                                              style: TextStyle(
                                                fontSize: isSmallScreen ? 16 : 18,
                                                fontWeight: FontWeight.w700,
                                                color: const Color(0xFF1A202C),
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              item["subtitle"] as String,
                                              style: TextStyle(
                                                fontSize: isSmallScreen ? 12 : 13,
                                                color: Colors.grey[600],
                                                height: 1.3,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      
                                      // 화살표
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: primaryColor.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Icon(
                                          Icons.arrow_forward_ios,
                                          color: primaryColor,
                                          size: isSmallScreen ? 16 : 18,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              
              // 하단 안내 메시지
              FadeTransition(
                opacity: _fadeAnimation,
                child: Container(
                  margin: const EdgeInsets.all(20),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Colors.white,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          "각 증상별로 맞춤형 진단 과정을 제공합니다",
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withOpacity(0.9),
                            fontWeight: FontWeight.w500,
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
}
