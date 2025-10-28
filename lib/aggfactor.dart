import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'pasthistory.dart';

class AggfactorPage extends StatefulWidget {
  final List<String> selectedSymptoms;
  final String userInput;
  final Map<String, String>? personalInfo;

  const AggfactorPage({
    super.key,
    required this.selectedSymptoms,
    required this.userInput,
    this.personalInfo,
  });

  @override
  State<AggfactorPage> createState() => _AggfactorPageState();
}

class _AggfactorPageState extends State<AggfactorPage> {
  final ScrollController _scrollController = ScrollController();
  bool isLoading = true; // Firebase에서 데이터 로드 중인지 표시
  int currentPage = 0; // 현재 진행 중인 질문 페이지 인덱스

  List<String> allAggravatingFactors = []; // 모든 악화 요인 리스트
  Map<String, String> predefinedQuestions = {}; // 악화 요인별 질문 매핑
  Map<String, int?> userAnswers = {}; // 사용자의 각 악화 요인별 답변 저장

  Map<String, double> diseaseProbabilities = {}; // 각 질병의 점수/확률 저장
  List<Map<String, dynamic>> candidateDiseases = []; // 현재 증상과 연관된 질병 후보들

  // 전체 파트 정보 (진행 상황 표시용)
  final List<Map<String, dynamic>> allParts = [
    {
      'name': '악화요인 분석',
      'icon': Icons.psychology,
      'description': '증상을 악화시키는 요인들을 분석합니다',
      'color': Color(0xFF2E7D8A),
      'completed': false,
    },
    {
      'name': '과거질환 이력',
      'icon': Icons.history,
      'description': '과거 질환 이력을 확인합니다',
      'color': Color(0xFF4A90A4),
      'completed': false,
    },
    {
      'name': '위험요인',
      'icon': Icons.warning,
      'description': '질병 위험요인을 평가합니다',
      'color': Color(0xFF7FB3D3),
      'completed': false,
    },
    {
      'name': '사회적 이력',
      'icon': Icons.people,
      'description': '사회적 환경과 생활습관을 확인합니다',
      'color': Color(0xFF9BB5C8),
      'completed': false,
    },
  ];

  @override
  void initState() {
    super.initState();
    _setPredefinedQuestions();
    _initializeDiagnosis();
  }

  void _setPredefinedQuestions() {
    predefinedQuestions = {
      "5-FU 주입": "5-FU 주입 후 증상이 심해지나요?",
      "고용량 투여": "고용량 약물 투여 후 증상이 악화되나요?",
      "간담도 감염": "간담도 감염 시 증상이 악화되나요?",
      "면역저하": "면역이 저하될 때 증상이 심해지나요?",
      "종양 성장": "종양이 성장할수록 증상이 악화되나요?",
      "피막 팽창": "피막이 팽창할 때 통증이 증가하나요?",
      "염분 섭취": "염분 섭취 후 증상이 심해지나요?",
      "체액 저류": "체액이 저류될 때 증상이 악화되나요?",
      "추위": "추운 환경에서 증상이 심해지나요?",
      "고혈압": "혈압이 높을 때 증상이 악화되나요?",
      "염증": "염증이 있을 때 증상이 심해지나요?",
      "건강 관련 미디어": "건강 관련 미디어를 접할 때 불안이나 증상이 심해지나요?",
      "질병 신호": "질병 신호를 느낄 때 증상이 악화되나요?",
      "목 움직임": "목을 움직일 때 증상이 심해지나요?",
      "자세": "자세를 바꿀 때 증상이 악화되나요?",
      "스트레스": "스트레스를 받을 때 증상이 심해지나요?",
      "군중": "군중 속에서 증상이 악화되나요?",
      "특정 상황": "특정 상황에서 증상이 심해지나요?",
      "특정 음식": "특정 음식을 섭취하면 증상이 심해지나요?",
      "밀폐 공간": "밀폐된 공간에서 증상이 악화되나요?",
      "활동": "활동 후 증상이 심해지나요?",
      "압통점 압박": "압통점을 누를 때 통증이 심해지나요?",
      "과사용": "과사용 후 증상이 심해지나요?",
      "긴장": "긴장할 때 증상이 악화되나요?",
      "차가운 공기": "차가운 공기를 마실 때 증상이 심해지나요?",
      "대기오염": "대기오염이 심할 때 증상이 악화되나요?",
      "흡연": "흡연 시 증상이 악화되나요?",
      "감염": "감염 시 증상이 심해지나요?",
      "찬 공기": "찬 공기에 노출되면 증상이 악화되나요?",
      "유충 이동": "유충이 이동할 때 증상이 심해지나요?",
      "면역 반응": "면역 반응으로 인해 증상이 악화되나요?",
      "운동": "운동 후 증상이 심해지나요?",
      "양압환기": "양압환기를 할 때 증상이 악화되나요?",
      "외상": "외상 후 증상이 심해지나요?",
      "호흡": "호흡할 때 증상이 악화되나요?",
      "몸 비틀기": "몸을 비틀면 통증이 심해지나요?",
      "압박": "압박 시 증상이 심해지나요?",
      "움직임": "움직일 때 증상이 악화되나요?",
      "깊은 흡기": "깊게 숨을 들이쉴 때 증상이 심해지나요?",
      "기름진 음식": "기름진 음식을 먹으면 증상이 악화되나요?",
      "고지방 식사": "고지방 식사 후 증상이 심해지나요?",
      "음주": "음주 후 증상이 악화되나요?",
      "무거운 물건 들기": "무거운 물건을 들면 증상이 심해지나요?",
      "탈수": "탈수 시 증상이 악화되나요?",
      "빈맥성 부정맥": "빈맥성 부정맥 시 증상이 심해지나요?",
      "접촉": "접촉 시 통증이 생기나요?",
      "약물 중단": "약물을 중단하면 증상이 악화되나요?",
      "반복적 색전": "반복적인 색전이 발생하면 증상이 심해지나요?",
      "고지대": "고지대에서 증상이 악화되나요?",
      "최근 방사선 치료": "최근 방사선 치료 후 증상이 심해지나요?",
      "눕기": "눕거나 자세를 낮추면 증상이 심해지나요?",
      "구토": "구토 후 증상이 악화되나요?",
      "내시경": "내시경 후 증상이 심해지나요?",
      "성과 압박": "성과 압박감을 받을 때 증상이 악화되나요?",
      "대인 갈등": "대인 갈등 시 증상이 심해지나요?",
      "정서적 스트레스": "정서적 스트레스가 있을 때 증상이 심해지나요?",
      "혈관확장제": "혈관확장제 복용 후 증상이 악화되나요?",
      "햇빛 부족": "햇빛이 부족할 때 증상이 심해지나요?",
      "영양 불량": "영양 불량 시 증상이 심해지나요?",
      "팔 들어올리기": "팔을 들어올릴 때 증상이 심해지나요?",
      "과로": "과로 후 증상이 악화되나요?",
      "NSAIDs": "NSAIDs(소염진통제) 복용 후 증상이 심해지나요?",
      "공복": "공복일 때 증상이 악화되나요?",
      "찬 음료": "찬 음료를 마시면 증상이 심해지나요?",
      "음식 삼킴": "음식을 삼킬 때 통증이나 증상이 생기나요?",
      "고형식 섭취": "고형식을 섭취하면 증상이 악화되나요?",
      "과식": "과식 후 증상이 심해지나요?",
      "심리적 스트레스": "심리적 스트레스 시 증상이 악화되나요?",
      "바이러스 감염": "바이러스 감염 시 증상이 심해지나요?",
      "자가면역질환": "자가면역질환 시 증상이 심해지나요?",
      "바로 누움": "바로 누우면 증상이 심해지나요?",
      "깊은 호흡": "깊게 호흡할 때 증상이 악화되나요?",
      "기침": "기침할 때 통증이 생기나요?",
      "체위 변화": "체위를 바꿀 때 증상이 악화되나요?",
      "과도한 수분 섭취": "과도한 수분 섭취 후 증상이 심해지나요?",
      "약물 불순응": "약물을 규칙적으로 복용하지 않으면 증상이 악화되나요?",
      "부정맥": "부정맥이 있을 때 증상이 심해지나요?",
      "심낭삼출": "심낭삼출 시 증상이 악화되나요?",
      "항응고제 사용": "항응고제 사용 후 증상이 심해지나요?",
      "고온 환경": "고온 환경에서 증상이 심해지나요?",
      "격렬한 활동": "격렬한 활동 후 증상이 심해지나요?",
      "외상 기억": "외상 기억이 떠오를 때 증상이 심해지나요?",
      "큰 소음": "큰 소음을 들으면 증상이 심해지나요?",
      "부정적 생활 사건": "부정적인 생활 사건이 있을 때 증상이 악화되나요?",
      "고립": "고립되면 증상이 심해지나요?",
      "카페인": "카페인을 섭취하면 증상이 악화되나요?",
      "고령": "고령에서 증상이 더 자주 발생하나요?",
      "직접적 종양 침범": "종양이 직접 침범할 때 증상이 심해지나요?",
      "휴식": "휴식 중에도 증상이 나타나나요?",
      "새벽": "새벽에 증상이 심해지나요?",
      "생리": "생리 중 증상이 악화되나요?",
      "호르몬 변화": "호르몬 변화 시 증상이 심해지나요?",
      "한랭 노출": "한랭 노출 시 증상이 악화되나요?",
      "바람": "바람을 쐴 때 증상이 심해지나요?",
      "움직임 제한": "움직임이 제한되면 증상이 심해지나요?",
      "햇빛": "햇빛에 노출될 때 증상이 악화되나요?",
      "골 전이": "골 전이가 있을 때 증상이 심해지나요?",
      "외상 신호": "외상 신호가 있을 때 증상이 심해지나요?",
      "정서적 갈등": "정서적 갈등 시 증상이 심해지나요?",
      "허리 하중": "허리에 하중이 가해질 때 통증이 심해지나요?",
      "알레르겐": "알레르겐에 노출되면 증상이 악화되나요?",
      "코카인 사용": "코카인을 사용하면 증상이 악화되나요?",
      "기계적 하중": "기계적 하중 시 증상이 심해지나요?",
      "밀집된 환경": "밀집된 환경에서 증상이 심해지나요?",
      "흡인": "흡인 후 증상이 악화되나요?",
      "임신": "임신 중 증상이 심해지나요?",
      "추운 날씨": "추운 날씨에 증상이 악화되나요?",
      "장기 침상": "장기간 침상 생활 시 증상이 심해지나요?",
      "수술": "수술 후 증상이 심해지나요?",
      "암": "암 진행 시 증상이 악화되나요?",
      "종양 진행": "종양 진행 시 증상이 악화되나요?",
      "체액 과부하": "체액 과부하 시 증상이 심해지나요?",
      "누운 자세": "누운 자세에서 증상이 심해지나요?",
      "허리 신전": "허리를 신전할 때 증상이 심해지나요?",
      "회전": "회전할 때 통증이 생기나요?",
      "보행": "보행 시 증상이 심해지나요?",
      "기립": "기립 시 증상이 악화되나요?"
    };
  }

  Future<void> _initializeDiagnosis() async {
    final snapshot = await FirebaseFirestore.instance.collection("diseases_ko").get();

    candidateDiseases = snapshot.docs.map((doc) {
      final data = doc.data();
      final symptoms = (data["증상"] as List?)?.map((e) => e.toString()).toList() ?? [];
      final factors = (data["악화 요인"] as List?)?.map((e) => e.toString()).toList() ?? [];
      return {"질환명": data["질환명"], "증상": symptoms, "악화 요인": factors};
    }).where((d) {
      return widget.selectedSymptoms.any((s) => (d["증상"] as List).contains(s));
    }).toList();

    // ✅ 선택된 질병 출력
    print("🧬 선택된 증상과 일치하는 질병 개수: ${candidateDiseases.length}개");
    print("🧬 선택된 증상과 일치하는 질병 목록:");
    for (var d in candidateDiseases) {
      print("- ${d["질환명"]}");
    }

    for (var d in candidateDiseases) {
      diseaseProbabilities[d["질환명"]] = 1.0;
    }

    final Set<String> allFactors = {};
    for (var d in candidateDiseases) {
      final factors = d["악화 요인"] as List<String>;
      allFactors.addAll(factors);
    }
    print("✅ 중복 제거된 악화 요인 개수: ${allFactors.length}");

    allAggravatingFactors =
        allFactors.where((f) => predefinedQuestions.containsKey(f)).toList();

    setState(() => isLoading = false);
  }

  void _updateScores(Map<String, int?> batchAnswers) {
    // 가중치 테이블
    final responseScale = {
      1: 0.7,   // 전혀 아니다
      2: 0.85,  // 아니다
      3: 1.0,   // 모르겠다
      4: 1.15,  // 그렇다
      5: 1.3,   // 매우 그렇다
    };

    for (var d in candidateDiseases) {
      final name = d["질환명"];
      double prev = diseaseProbabilities[name]!;
      double score = prev;
      final factors = d["악화 요인"] as List<String>;

      for (var entry in batchAnswers.entries) {
        final factor = entry.key;
        final answer = entry.value;
        if (answer == null) continue;

        final hasFactor = factors.contains(factor);
        double weight;

        if (hasFactor) {
          weight = responseScale[answer]!;
        } else {
          // 실제 요인과 반대일 경우 반전 (5 → 1, 4 → 2 ...)
          weight = responseScale[6 - answer]!;
        }

        score *= weight;
      }

      diseaseProbabilities[name] = score;
      print("➡️ $name: ${prev.toStringAsFixed(3)} → ${score.toStringAsFixed(3)}");
    }

    print("\n📊 현재 전체 질병 확률 상태:");
    diseaseProbabilities.forEach((key, value) {
      print("- $key: ${value.toStringAsFixed(4)}");
    });
  }


  void _onConfirmBatch() {
    final currentBatch = _getCurrentBatch();
    final batchAnswers = {
      for (var f in currentBatch)
        predefinedQuestions[f]!: userAnswers[f]
    };

    _updateScores(batchAnswers);

    // 악화요인 파트의 모든 질문이 완료되었는지 확인
    if ((currentPage + 1) * 5 >= allAggravatingFactors.length) {
      // 악화요인 파트 완료 - 과거질환 이력 페이지로 이동
      final sorted = diseaseProbabilities.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      final cutoff = (sorted.length * 0.5).ceil();
      final topDiseases = sorted.take(cutoff).map((e) => e.key).toList();

      print("\n🏁 악화요인 분석 완료! 상위 질병 목록:");
      for (var dis in topDiseases) {
        print("- $dis (${diseaseProbabilities[dis]!.toStringAsFixed(4)})");
      }

      // ✅ 모든 악화요인 질문과 답변을 누적
      final allAggravatingAnswers = <String, String?>{};
      for (var factor in allAggravatingFactors) {
        final question = predefinedQuestions[factor];
        final answer = userAnswers[factor];
        if (question != null && answer != null) {
          allAggravatingAnswers[question] = answer.toString();
        }
      }

      print("📋 악화요인 단계에서 총 ${allAggravatingAnswers.length}개 질문 완료");

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => PastHistoryPage(
            //상위 50프로 질병
            topDiseases: topDiseases,
            //사용자가 처음에 입력한 증상
            userInput: widget.userInput,
            //사용자가 처음 단계에서 선택한 증상
            selectedSymptoms: widget.selectedSymptoms,
            //사용자가 답한 질문들 - 모든 악화요인 질문 포함
            questionHistory: allAggravatingAnswers,
            //개인정보
            personalInfo: widget.personalInfo,
            diseaseProbabilities: Map<String, double>.from(diseaseProbabilities),
          ),
        ),
      );
    } else {
      setState(() => currentPage++);
      
      // 다음 질문으로 넘어갈 때 상단으로 스크롤
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            0.0,
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOut,
          );
        }
      });
    }
  }

  List<String> _getCurrentBatch() {
    final start = currentPage * 5;
    final end = (start + 5).clamp(0, allAggravatingFactors.length);
    return allAggravatingFactors.sublist(start, end);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  int _getCurrentQuestionNumber() {
    return (currentPage * 5) + 1;
  }

  String _getAnswerText(int answer) {
    switch (answer) {
      case 1:
        return "전혀 그렇지 않다";
      case 2:
        return "그렇지 않다";
      case 3:
        return "보통이다";
      case 4:
        return "그렇다";
      case 5:
        return "매우 그렇다";
      default:
        return "";
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = const Color(0xFF2E7D8A);
    final secondaryColor = const Color(0xFF4A90A4);
    final accentColor = const Color(0xFF7FB3D3);

    if (isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
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
            "악화 요인 분석", 
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
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Lottie.asset("assets/medical_loading.json", width: 120),
              const SizedBox(height: 24),
              Text(
                "증상을 분석하고 있습니다...",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: primaryColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "잠시만 기다려주세요",
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      );
    }

    final currentBatch = _getCurrentBatch();
    final currentQuestionNumber = _getCurrentQuestionNumber();
    final progress = allAggravatingFactors.length > 0 ? (currentPage * 5) / allAggravatingFactors.length : 0.0;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
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
          "악화 요인 분석", 
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
        controller: _scrollController,
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // 상단 진행 상황 카드
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.white, const Color(0xFFF0F8FF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: primaryColor.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // 현재 파트 정보
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: allParts[0]['color'].withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          allParts[0]['icon'],
                          color: allParts[0]['color'],
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            allParts[0]['name'],
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: allParts[0]['color'],
                            ),
                          ),
                          Text(
                            allParts[0]['description'],
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // 전체 진행률 정보
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "질문 $currentQuestionNumber / ${allAggravatingFactors.length}",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[800],
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // 100% 게이지바
                  Container(
                    height: 16,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.grey[300], // 안 채워진 부분은 회색
                      border: Border.all(color: Colors.grey[400]!, width: 1),
                    ),
                    child: Stack(
                      children: [
                        // 전체 배경 (회색)
                        Container(
                          width: double.infinity,
                          height: double.infinity,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            color: Colors.grey[300],
                          ),
                        ),
                        // 채워진 부분 (그라데이션)
                        FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: progress,
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              gradient: LinearGradient(
                                colors: [allParts[0]['color'], secondaryColor],
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: allParts[0]['color'].withOpacity(0.3),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                          ),
                        ),
                        // 퍼센트 텍스트 (게이지바 위에 표시)
                        if (progress > 0.15) // 15% 이상일 때만 텍스트 표시
                          Positioned(
                            left: 4,
                            top: 0,
                            bottom: 0,
                            child: Center(
                              child: Text(
                                "${(progress * 100).toStringAsFixed(0)}%",
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                  shadows: [
                                    Shadow(
                                      color: Colors.black45,
                                      blurRadius: 3,
                                      offset: Offset(0, 1),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // 파트별 진행 상황
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: allParts.asMap().entries.map((entry) {
                      final index = entry.key;
                      final part = entry.value;
                      final isCurrentPart = index == 0; // 악화요인 파트가 현재 파트
                      
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: isCurrentPart 
                            ? part['color'].withOpacity(0.1)
                            : Colors.grey.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isCurrentPart 
                              ? part['color']
                              : Colors.grey,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              part['icon'],
                              size: 12,
                              color: isCurrentPart 
                                ? part['color']
                                : Colors.grey,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              part['name'].split(' ')[0], // 첫 번째 단어만 표시
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                                color: isCurrentPart 
                                  ? part['color']
                                  : Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            // 질문 카드들
            ...currentBatch.asMap().entries.map((entry) {
              final index = entry.key;
              final factor = entry.value;
              final question = predefinedQuestions[factor] ?? "$factor 시 증상이 악화되나요?";
              final isAnswered = userAnswers[factor] != null;
              final questionNumber = currentQuestionNumber + index;
              
              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: isAnswered 
                        ? primaryColor.withOpacity(0.15)
                        : Colors.grey.withOpacity(0.1),
                      blurRadius: isAnswered ? 12 : 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                  border: isAnswered 
                    ? Border.all(color: primaryColor.withOpacity(0.3), width: 1.5)
                    : null,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 질문 텍스트
                      Row(
                        children: [
                          // 질문 번호
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: allParts[0]['color'].withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              "Q$questionNumber",
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: allParts[0]['color'],
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              question,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[800],
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // 5점 척도 선택 UI
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey[200]!),
                        ),
                        child: Column(
                          children: [
                            // 라벨
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "전혀 그렇지 않다",
                                  style: TextStyle(
                                    color: accentColor,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Text(
                                  "매우 그렇다",
                                  style: TextStyle(
                                    color: primaryColor,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            
                            // 선택 버튼들
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                for (int i = 1; i <= 5; i++)
                                  GestureDetector(
                                    onTap: () => setState(() => userAnswers[factor] = i),
                                    child: Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: userAnswers[factor] == i
                                              ? primaryColor
                                              : Colors.grey[300]!,
                                          width: userAnswers[factor] == i ? 3 : 2,
                                        ),
                                        color: userAnswers[factor] == i
                                            ? primaryColor.withOpacity(0.1)
                                            : Colors.transparent,
                                      ),
                                      child: Center(
                                        child: Text(
                                          i.toString(),
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            color: userAnswers[factor] == i
                                                ? primaryColor
                                                : Colors.grey[600],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            
                            const SizedBox(height: 8),
                            
                            // 선택된 값 표시
                            if (userAnswers[factor] != null)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: primaryColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  _getAnswerText(userAnswers[factor]!),
                                  style: TextStyle(
                                    color: primaryColor,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
            
            const SizedBox(height: 32),
            
            // 하단 확인 버튼
            Container(
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
                onPressed: _onConfirmBatch,
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
                          (currentPage + 1) * 5 >= allAggravatingFactors.length
                            ? "다음 파트로"
                            : "다음 질문으로",
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
            
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
