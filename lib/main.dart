import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'PersonalInfo.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'isdiseaseright.dart';



void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

//전체 질병 데이터를 가져오는 함수
Future<void> fetchAllDiseases() async {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final CollectionReference diseasesCollection = firestore.collection('diseases_ko');

  try {
    QuerySnapshot snapshot = await diseasesCollection.get();

    for (var doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;

      String diseaseName = data['질환명'] ?? '이름 없음';
      List symptoms = data['증상'] ?? [];
      List pastHistory = data['과거 질환 이력'] ?? [];
      List socialHistory = data['사회적 이력'] ?? [];
      List aggravatingFactors = data['악화 요인'] ?? [];
      List riskFactors = data['위험 요인'] ?? [];
      List clinicalFeatures = data['주요 임상 특징'] ?? [];

      print('🩺 질환명: $diseaseName');
      print('   증상: ${symptoms.join(', ')}');
      print('   과거 질환 이력: ${pastHistory.join(', ')}');
      print('   사회적 이력: ${socialHistory.join(', ')}');
      print('   악화 요인: ${aggravatingFactors.join(', ')}');
      print('   위험 요인: ${riskFactors.join(', ')}');
      print('   주요 임상 특징: ${clinicalFeatures.join(', ')}');
      print('---------------------------------------');
    }
  } catch (e) {
    print('❌ Firestore 데이터 불러오기 오류: $e');
  }
}

//악화요인만 가져오는 함수
Future<void> fetchUniqueAggravatingFactors() async {
  final firestore = FirebaseFirestore.instance;
  final snapshot = await firestore.collection('diseases_ko').get();

  Set<String> uniqueFactors = {}; // 중복 제거용 Set

  for (var doc in snapshot.docs) {
    final data = doc.data();
    List<dynamic> aggravatingFactors = data['사회적 이력'] ?? [];

    // 리스트 안의 요소들을 Set에 추가 (자동으로 중복 제거)
    for (var factor in aggravatingFactors) {
      if (factor is String) uniqueFactors.add(factor.trim());
    }
  }

  print('🧩 중복 제거된 목록:');
  for (var factor in uniqueFactors) {
    print('- $factor');
  }

  print('총 ${uniqueFactors.length}개 항목');
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Medical Diagnosis App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Pretendard',
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueAccent),
        useMaterial3: true,
      ),
      home: const HomeBackground(),
    );
  }
}

class HomeBackground extends StatefulWidget {
  const HomeBackground({super.key});

  @override
  State<HomeBackground> createState() => _HomeBackgroundState();
}

class _HomeBackgroundState extends State<HomeBackground>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    
    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic));

    // 애니메이션 시작
    _fadeController.forward();
    Future.delayed(const Duration(milliseconds: 300), () {
      _scaleController.forward();
    });
    Future.delayed(const Duration(milliseconds: 600), () {
      _slideController.forward();
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _scaleController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenHeight < 700;
    final isVerySmallScreen = screenHeight < 600;
    
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFF0F4C75),
              const Color(0xFF3282B8),
              const Color(0xFFBBE1FA),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            stops: const [0.0, 0.6, 1.0],
          ),
        ),
        child: Stack(
          children: [
            // 배경 장식 요소들
            Positioned(
              top: -50,
              right: -50,
              child: Container(
                width: screenWidth * 0.5,
                height: screenWidth * 0.5,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.05),
                ),
              ),
            ),
            Positioned(
              bottom: -100,
              left: -100,
              child: Container(
                width: screenWidth * 0.8,
                height: screenWidth * 0.8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.03),
                ),
              ),
            ),
            Positioned(
              top: screenHeight * 0.2,
              left: -30,
              child: Container(
                width: screenWidth * 0.25,
                height: screenWidth * 0.25,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.08),
                ),
              ),
            ),
            
            // 메인 컨텐츠
            SafeArea(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: screenHeight - MediaQuery.of(context).padding.top - MediaQuery.of(context).padding.bottom,
                  ),
                  child: IntrinsicHeight(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(height: isVerySmallScreen ? 20 : (isSmallScreen ? 30 : 40)),
                        
                        // 앱 아이콘 (애니메이션)
                        FadeTransition(
                          opacity: _fadeAnimation,
                          child: ScaleTransition(
                            scale: _scaleAnimation,
                            child: Container(
                              width: isSmallScreen ? 100 : (screenWidth * 0.35).clamp(100.0, 140.0),
                              height: isSmallScreen ? 100 : (screenWidth * 0.35).clamp(100.0, 140.0),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.white.withOpacity(0.2),
                                    Colors.white.withOpacity(0.1),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.white.withOpacity(0.3),
                                    blurRadius: 20,
                                    spreadRadius: 5,
                                  ),
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 30,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: Icon(
                                Icons.health_and_safety_rounded,
                                size: isSmallScreen ? 50 : (screenWidth * 0.2).clamp(50.0, 80.0),
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        
                        SizedBox(height: isVerySmallScreen ? 20 : (isSmallScreen ? 30 : 40)),

                        // 앱 제목 (슬라이드 애니메이션)
                        SlideTransition(
                          position: _slideAnimation,
                          child: FadeTransition(
                            opacity: _fadeAnimation,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  '의료 데이터 기반',
                                  style: TextStyle(
                                    fontSize: isVerySmallScreen ? 20 : (isSmallScreen ? 24 : 28),
                                    fontWeight: FontWeight.w300,
                                    color: Colors.white,
                                    letterSpacing: 2.0,
                                    height: 1.2,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                Text(
                                  '진단 시스템',
                                  style: TextStyle(
                                    fontSize: isVerySmallScreen ? 24 : (isSmallScreen ? 28 : 32),
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                    letterSpacing: 1.5,
                                    height: 1.2,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                SizedBox(height: isSmallScreen ? 12 : 16),
                                Center(
                                  child: Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: isSmallScreen ? 16 : 20, 
                                      vertical: isSmallScreen ? 6 : 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: Colors.white.withOpacity(0.3),
                                        width: 1,
                                      ),
                                    ),
                                    child: Text(
                                      'Graduation Project',
                                      style: TextStyle(
                                        fontSize: isSmallScreen ? 12 : 14,
                                        color: Colors.white,
                                        fontWeight: FontWeight.w500,
                                        letterSpacing: 1.0,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        
                        SizedBox(height: isVerySmallScreen ? 40 : (isSmallScreen ? 60 : 80)),

                        // 시작 버튼 (슬라이드 애니메이션)
                        SlideTransition(
                          position: _slideAnimation,
                          child: FadeTransition(
                            opacity: _fadeAnimation,
                            child: Center(
                              child: Container(
                                width: (screenWidth * 0.7).clamp(250.0, 280.0),
                                height: isSmallScreen ? 55 : 65,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Colors.white, Color(0xFFF8F9FA)],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(35),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.2),
                                      blurRadius: 20,
                                      offset: const Offset(0, 8),
                                    ),
                                    BoxShadow(
                                      color: Colors.white.withOpacity(0.8),
                                      blurRadius: 20,
                                      offset: const Offset(0, -2),
                                    ),
                                  ],
                                ),
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(35),
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => const IsDiseaseRightPage(),
                                        ),
                                      );
                                    },
                                    child: Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: isSmallScreen ? 20 : 30, 
                                        vertical: isSmallScreen ? 14 : 18,
                                      ),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Container(
                                            padding: EdgeInsets.all(isSmallScreen ? 6 : 8),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF0F4C75),
                                              borderRadius: BorderRadius.circular(20),
                                            ),
                                            child: Icon(
                                              Icons.play_arrow_rounded,
                                              size: isSmallScreen ? 20 : 24,
                                              color: Colors.white,
                                            ),
                                          ),
                                          SizedBox(width: isSmallScreen ? 12 : 16),
                                          Text(
                                            '진단 시작하기',
                                            style: TextStyle(
                                              fontSize: isSmallScreen ? 16 : 18,
                                              fontWeight: FontWeight.w600,
                                              color: const Color(0xFF0F4C75),
                                              letterSpacing: 0.5,
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
                        ),
                        
                        SizedBox(height: isVerySmallScreen ? 20 : (isSmallScreen ? 30 : 40)),
                        
                        // 하단 설명 텍스트
                        FadeTransition(
                          opacity: _fadeAnimation,
                          child: Center(
                            child: Container(
                              padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.1),
                              child: Text(
                                'AI 기반 의료 진단으로\n정확하고 신속한 건강 관리',
                                style: TextStyle(
                                  fontSize: isSmallScreen ? 12 : 14,
                                  color: Colors.white.withOpacity(0.8),
                                  height: 1.5,
                                  fontWeight: FontWeight.w400,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        ),
                        
                        SizedBox(height: isVerySmallScreen ? 30 : (isSmallScreen ? 40 : 60)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ConsentPage extends StatefulWidget {
  const ConsentPage({super.key});

  @override
  State<ConsentPage> createState() => _ConsentPageState();
}

class _ConsentPageState extends State<ConsentPage>
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

  void _showDiagnosisFlowDialog(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenHeight < 700;
    final isVerySmallScreen = screenHeight < 600;
    
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
          elevation: 20,
          child: Container(
            constraints: BoxConstraints(
              maxHeight: screenHeight * 0.8,
              maxWidth: screenWidth * 0.9,
            ),
            padding: EdgeInsets.all(isSmallScreen ? 20 : 30),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(25),
              gradient: LinearGradient(
                colors: [Colors.white, const Color(0xFFF8F9FA)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 아이콘
                  Container(
                    width: isSmallScreen ? 60 : 80,
                    height: isSmallScreen ? 60 : 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [const Color(0xFF0F4C75), const Color(0xFF3282B8)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF0F4C75).withOpacity(0.3),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.health_and_safety_rounded,
                      size: isSmallScreen ? 30 : 40,
                      color: Colors.white,
                    ),
                  ),
                  
                  SizedBox(height: isSmallScreen ? 15 : 20),
                  
                  Text(
                    "진단 절차 안내",
                    style: TextStyle(
                      fontSize: isVerySmallScreen ? 20 : (isSmallScreen ? 22 : 24),
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF0F4C75),
                    ),
                  ),
                  
                  SizedBox(height: isSmallScreen ? 15 : 20),
                  
                  Container(
                    padding: EdgeInsets.all(isSmallScreen ? 15 : 20),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0F8FF),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(
                        color: const Color(0xFF0F4C75).withOpacity(0.1),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildStepItem("1", "개인 정보", "나이, 성별, 음주, 흡연, 직업, 운동 여부 등을 입력합니다", isSmallScreen),
                        _buildStepItem("2", "과거 질환 이력", "과거에 앓았던 질병을 선택하거나 입력합니다", isSmallScreen),
                        _buildStepItem("3", "증상 선택", "현재 느끼는 증상과 관련된 통증 양상을 선택합니다", isSmallScreen),
                        _buildStepItem("4", "악화 요인 분석", "증상이 악화되는 상황이나 요인을 확인합니다", isSmallScreen),
                        _buildStepItem("5", "위험 요인 평가", "현재 앓고 있는 질병을 확인합니다.", isSmallScreen),
                      ],
                    ),
                  ),
                  
                  SizedBox(height: isSmallScreen ? 15 : 20),
                  
                  SizedBox(height: isSmallScreen ? 20 : 25),
                  
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            padding: EdgeInsets.symmetric(vertical: isSmallScreen ? 12 : 15),
                            side: BorderSide(color: Colors.grey[400]!),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            "취소",
                            style: TextStyle(
                              fontSize: isSmallScreen ? 14 : 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: isSmallScreen ? 12 : 15),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const PersonalInfoPage())
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0F4C75),
                            padding: EdgeInsets.symmetric(vertical: isSmallScreen ? 12 : 15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 4,
                          ),
                          child: Text(
                            "진단 시작",
                            style: TextStyle(
                              fontSize: isSmallScreen ? 14 : 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStepItem(String number, String title, String description, bool isSmallScreen) {
    return Padding(
      padding: EdgeInsets.only(bottom: isSmallScreen ? 10 : 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: isSmallScreen ? 20 : 24,
            height: isSmallScreen ? 20 : 24,
            decoration: BoxDecoration(
              color: const Color(0xFF0F4C75),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: isSmallScreen ? 10 : 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          SizedBox(width: isSmallScreen ? 10 : 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: isSmallScreen ? 12 : 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF0F4C75),
                  ),
                ),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: isSmallScreen ? 10 : 12,
                    color: Colors.grey[600],
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenHeight < 700;
    final isVerySmallScreen = screenHeight < 600;
    
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFF0F4C75),
              const Color(0xFF3282B8),
              const Color(0xFFBBE1FA),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            stops: const [0.0, 0.6, 1.0],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
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
                        child: Text(
                          "동의 및 안내",
                          style: TextStyle(
                            fontSize: isSmallScreen ? 18 : 20,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(width: 48), // 뒤로가기 버튼과 균형 맞추기
                    ],
                  ),
                  
                  SizedBox(height: isVerySmallScreen ? 20 : (isSmallScreen ? 30 : 40)),
                  
                  // 메인 카드
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(isSmallScreen ? 20 : 30),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(25),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            // 경고 아이콘
                            Container(
                              width: isSmallScreen ? 60 : 80,
                              height: isSmallScreen ? 60 : 80,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  colors: [Colors.red[400]!, Colors.red[600]!],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.red.withOpacity(0.3),
                                    blurRadius: 15,
                                    offset: const Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: Icon(
                                Icons.warning_amber_rounded,
                                size: isSmallScreen ? 30 : 40,
                                color: Colors.white,
                              ),
                            ),
                            
                            SizedBox(height: isSmallScreen ? 20 : 25),
                            
                            Text(
                              "비의료 진단 고지",
                              style: TextStyle(
                                fontSize: isVerySmallScreen ? 20 : (isSmallScreen ? 22 : 24),
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF0F4C75),
                              ),
                            ),
                            
                            SizedBox(height: isSmallScreen ? 15 : 20),
                            
                            Container(
                              padding: EdgeInsets.all(isSmallScreen ? 15 : 20),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF0F8FF),
                                borderRadius: BorderRadius.circular(15),
                                border: Border.all(
                                  color: Colors.red.withOpacity(0.2),
                                  width: 1,
                                ),
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    "이 앱은 결과가 정확하지 않을 수 있습니다.",
                                    style: TextStyle(
                                      fontSize: isSmallScreen ? 14 : 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.red[700],
                                      height: 1.4,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  SizedBox(height: isSmallScreen ? 8 : 10),
                                  Text(
                                    "정확한 진단과 치료를 위해\n반드시 의사와 상담하세요.",
                                    style: TextStyle(
                                      fontSize: isSmallScreen ? 13 : 15,
                                      color: Colors.grey[700],
                                      height: 1.5,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  
                  SizedBox(height: isVerySmallScreen ? 30 : (isSmallScreen ? 40 : 60)),
                  
                  // 하단 버튼들
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: isSmallScreen ? 50 : 55,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(15),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(15),
                                onTap: () => Navigator.pop(context),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.close_rounded, 
                                      color: Colors.white, 
                                      size: isSmallScreen ? 18 : 20,
                                    ),
                                    SizedBox(width: isSmallScreen ? 6 : 8),
                                    Text(
                                      "거부",
                                      style: TextStyle(
                                        fontSize: isSmallScreen ? 14 : 16,
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
                        
                        SizedBox(width: isSmallScreen ? 15 : 20),
                        
                        Expanded(
                          child: Container(
                            height: isSmallScreen ? 50 : 55,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Colors.white, Color(0xFFF8F9FA)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(15),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 10,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(15),
                                onTap: () => _showDiagnosisFlowDialog(context),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      padding: EdgeInsets.all(isSmallScreen ? 4 : 6),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF0F4C75),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Icon(
                                        Icons.check_circle_outline,
                                        color: Colors.white,
                                        size: isSmallScreen ? 14 : 16,
                                      ),
                                    ),
                                    SizedBox(width: isSmallScreen ? 6 : 8),
                                    Text(
                                      "동의",
                                      style: TextStyle(
                                        fontSize: isSmallScreen ? 14 : 16,
                                        fontWeight: FontWeight.w600,
                                        color: const Color(0xFF0F4C75),
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
                  
                  SizedBox(height: isVerySmallScreen ? 20 : (isSmallScreen ? 25 : 30)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

