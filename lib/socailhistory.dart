import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'refineddiseasepage.dart';

class SocialHistoryPage extends StatefulWidget {
  final List<String> topDiseases;
  final List<String> selectedSymptoms;
  final String userInput;
  final Map<String, String?> questionHistory;
  final Map<String, double> diseaseProbabilities;


  const SocialHistoryPage({
    super.key,
    required this.topDiseases,
    required this.selectedSymptoms,
    required this.userInput,
    required this.questionHistory,
    required this.diseaseProbabilities,
  });

  @override
  State<SocialHistoryPage> createState() => _SocialHistoryPageState();
}

class _SocialHistoryPageState extends State<SocialHistoryPage> {
  final ScrollController _scrollController = ScrollController();
  bool isLoading = true;
  int currentPage = 0;

  List<String> allSocialFactors = [];
  Map<String, String> predefinedQuestions = {}; // ✅ 사회적 이력 → 질문 매핑
  Map<String, int?> userAnswers = {};


  Map<String, double> diseaseProbabilities = {};
  List<Map<String, dynamic>> candidateDiseases = [];

  // 전체 파트 정보 (진행 상황 표시용)
  final List<Map<String, dynamic>> allParts = [
    {
      'name': '악화요인 분석',
      'icon': Icons.psychology,
      'description': '증상을 악화시키는 요인들을 분석합니다',
      'color': Color(0xFF2E7D8A),
      'completed': true, // 이미 완료됨
    },
    {
      'name': '과거질환 이력',
      'icon': Icons.history,
      'description': '과거 질환 이력을 확인합니다',
      'color': Color(0xFF4A90A4),
      'completed': true, // 이미 완료됨
    },
    {
      'name': '위험요인',
      'icon': Icons.warning,
      'description': '질병 위험요인을 평가합니다',
      'color': Color(0xFF7FB3D3),
      'completed': true, // 이미 완료됨
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
    _initializeSocialHistory();
  }

  /// ✅ 질문이 예/아니요 타입인지 확인
  bool _isYesNoQuestion(String questionKey) {
    return questionKey.startsWith('@');
  }

  /// ✅ 사회적 이력 → 질문 매핑
  void _setPredefinedQuestions() {
    predefinedQuestions = {
      "@항암 치료 경험": "항암 치료를 받은 적이 있나요?",
      "여행력": "최근 여행한 적이 있나요?",
      "@음주": "음주를 하시나요?",
      "@흡연": "흡연을 하시나요?",
      "@곰팡이 독소 노출": "곰팡이 독소에 노출된 적이 있나요?",
      "@간염 위험 인자": "간염에 걸릴 위험 인자(예: 주사기, 혈액 접촉 등)가 있었나요?",
      "@50세 이상": "연령이 50세 이상이신가요?",
      "@여성": "여성이신가요?",
      "잦은 병원 방문": "병원 방문을 자주 하시나요?",
      "안심 추구 행동": "걱정될 때 안심하려는 행동을 자주 하나요?",
      "사무직": "사무직에 종사하시나요?",
      "육체 노동": "육체 노동을 하시나요?",
      "불안 성향": "불안한 성향이 있으신가요?",
      "생활 스트레스": "생활 속 스트레스를 자주 받으시나요?",
      "스트레스": "스트레스를 자주 받으시나요?",
      "불안": "불안을 자주 느끼시나요?",
      "회피 행동": "불안을 느낄 때 회피하는 행동을 하시나요?",
      "직장 스트레스": "직장에서 스트레스를 자주 받으시나요?",
      "잘못된 자세": "잘못된 자세를 자주 취하시나요?",
      "무거운 물건 들기": "무거운 물건을 드는 일을 자주 하시나요?",
      "직업적 노출": "직업상 유해 물질에 노출되는 환경에 있나요?",
      "열악한 주거환경": "열악한 주거환경에서 생활하시나요?",
      "위생 불량": "위생 상태가 좋지 않은 환경에서 생활한 적이 있나요?",
      "여행": "여행을 자주 하시나요?",
      "키 크고 마른 체형 남성": "키가 크고 마른 체형의 남성이신가요?",
      "@최근 질환": "최근에 질병을 앓은 적이 있나요?",
      "격한 운동": "격한 운동을 자주 하시나요?",
      "@사고": "사고를 당한 적이 있나요?",
      "운동 습관": "운동 습관이 규칙적인가요?",
      "불량한 식습관": "불규칙하거나 불량한 식습관이 있으신가요?",
      "운동 부족": "운동량이 부족한 편인가요?",
      "고지방 식이": "고지방 음식을 자주 섭취하시나요?",
      "고지방 식습관": "고지방 식습관을 유지하고 있나요?",
      "@코카인 사용": "코카인을 사용한 적이 있나요?",
      "좌식 생활": "주로 앉아서 생활하시나요?",
      "고령": "고령에 해당하시나요?",
      "면역저하": "면역이 약한 상태이신가요?",
      "@바이오매스 노출": "바이오매스(나무 연기 등)에 노출된 적이 있나요?",
      "@장기간 부동": "오랜 기간 움직이지 못한 적이 있나요?",
      "@호르몬 요법": "호르몬 요법을 받은 적이 있나요?",
      "@암 치료": "암 치료를 받은 적이 있나요?",
      "@신경성 폭식증": "신경성 폭식증을 경험한 적이 있나요?",
      "회복 탄력성 부족": "스트레스 상황에서 회복이 잘 되지 않으신가요?",
      "가족 스트레스": "가족 문제로 스트레스를 받은 적이 있나요?",
      "신체활동 부족": "신체활동이 부족한 편인가요?",
      "@운동선수 활동": "운동선수로 활동한 경험이 있나요?",
      "@건강검진 미흡": "정기 건강검진을 받지 않고 계신가요?",
      "햇빛 노출 부족": "햇빛 노출이 부족한 생활을 하시나요?",
      "팔을 많이 쓰는 직업": "팔을 많이 사용하는 직업에 종사하시나요?",
      "수면 부족": "수면이 부족하신가요?",
      "정서적 스트레스": "정서적 스트레스를 자주 받으시나요?",
      "식습관": "식습관이 불규칙한 편인가요?",
      "찬 환경 노출": "찬 환경에 자주 노출되시나요?",
      "뜨거운 음료 섭취": "뜨거운 음료를 자주 섭취하시나요?",
      "비만": "비만에 해당하시나요?",
      "야식": "야식을 자주 드시나요?",
      "가족 갈등": "가족 간 갈등이 있으신가요?",
      "낮은 대처 능력": "스트레스 상황에 대처하기 어렵다고 느끼시나요?",
      "@감염자 접촉": "감염자와 접촉한 적이 있나요?",
      "@감염 노출": "감염 위험 환경에 노출된 적이 있나요?",
      //"특별한 요인 없음": "특별한 사회적 요인은 없으신가요?",
      "야외 노동": "야외에서 일하시는 편인가요?",
      "수분 부족": "평소 수분 섭취가 부족한가요?",
      "@전쟁 경험": "전쟁이나 유사한 극단적 상황을 경험하셨나요?",
      "@학대": "학대를 경험한 적이 있나요?",
      "@실직": "실직 경험이 있으신가요?",
      "@사회적 고립": "사회적으로 고립된 상태이신가요?",
      "@영양 불량": "영양 상태가 불량했던 적이 있나요?",
      "@늦은 출산": "늦은 나이에 출산한 적이 있나요?",
      "@심혈관 검진 부족": "심혈관 검진을 정기적으로 받지 않으시나요?",
      "@부인과 병력": "부인과 질환 병력이 있으신가요?",
      "@호르몬 치료": "호르몬 치료를 받은 적이 있나요?",
      "@노숙": "노숙 경험이 있나요?",
      "@알코올 중독": "알코올 중독 병력이 있나요?",
      "@학대 경험": "학대를 경험한 적이 있나요?",
      "@이차적 이득": "질병을 통해 이익을 얻은 적이 있나요?",
      "무거운 물건을 드는 직업": "무거운 물건을 자주 드는 직업에 종사하시나요?",
      "@알레르겐 노출": "알레르겐(알레르기 유발 물질)에 노출된 적이 있나요?",
      "간접흡연": "간접흡연에 자주 노출되시나요?",
      "@불법 약물 사용": "불법 약물을 사용한 적이 있나요?",
      "@55세 이상": "연령이 55세 이상이신가요?",
      //"가족력": "가족 중 유사한 질환을 가진 분이 있나요?",
      "@풍토지역 거주": "풍토병이 있는 지역에 거주하신 적이 있나요?",
      "@과밀한 생활": "과밀한 환경에서 생활하시나요?",
      "허약 상태": "허약하거나 체력이 약한 편인가요?",
      "@식욕억제제": "식욕억제제를 복용한 적이 있나요?",
      "@메탐페타민 사용": "메탐페타민을 사용한 적이 있나요?",
      "@최근 여행": "최근 여행을 다녀오셨나요?",
      "@장거리 여행": "장거리 여행을 다녀오신 적이 있나요?",
      //"특별한 위험 요인 없음": "특별한 위험 요인은 없으신가요?",
      "@앉아 있는 직업": "앉아서 일하는 직업이신가요?"
    };
  }

  /// ✅ Firestore에서 사회적 이력 로드
  Future<void> _initializeSocialHistory() async {
    final snapshot = await FirebaseFirestore.instance.collection("diseases_ko").get();

    candidateDiseases = snapshot.docs
        .map((doc) {
      final data = doc.data();
      final social =
          (data["사회적 이력"] as List?)?.map((e) => e.toString()).toList() ?? [];
      return {"질환명": data["질환명"], "사회적 이력": social};
    })
        .where((d) => widget.topDiseases.contains(d["질환명"]))
        .toList();

    print("🧬 선택된 상위 질병 (${candidateDiseases.length}개):");
    for (var d in candidateDiseases) {
      print("- ${d["질환명"]}");
    }

    for (var d in candidateDiseases) {
      final name = d["질환명"];
      diseaseProbabilities[name] = widget.diseaseProbabilities[name] ?? 1.0;
    }


    // ✅ 모든 사회적 이력 중복 제거
    final Set<String> allSocialSet = {};
    for (var d in candidateDiseases) {
      final list = d["사회적 이력"] as List<String>;
      allSocialSet.addAll(list);
    }

    print("✅ 중복 제거된 사회적 이력 개수: ${allSocialSet.length}");


    // ✅ 미리 정의된 질문이 있는 항목만 사용
    allSocialFactors =
        allSocialSet.where((s) => predefinedQuestions.containsKey(s)).toList();
    print("🎯 실제 질문으로 사용할 항목 수: ${allSocialFactors.length}");

    setState(() => isLoading = false);
  }

  void _updateScores(Map<String, int?> batchAnswers) {
    // 리커트 척도 기반 가중치
    final responseScale = {
      1: 0.7,   // 전혀 아니다
      2: 0.85,  // 아니다
      3: 1.0,   // 모르겠다
      4: 1.15,  // 그렇다
      5: 1.3,   // 매우 그렇다
    };

    print("\n🧩 [사회적 이력 반영 결과]");
    for (var d in candidateDiseases) {
      final name = d["질환명"];
      double prev = diseaseProbabilities[name]!;
      double score = prev;
      final social = d["사회적 이력"] as List<String>;

      for (var entry in batchAnswers.entries) {
        final factor = entry.key;
        final answer = entry.value;
        if (answer == null) continue;

        final hasFactor = social.contains(factor);
        double weight;

        if (_isYesNoQuestion(factor)) {
          // 예/아니요/모르겠어요 질문 처리 (1: 예, 0: 아니요, -1: 모르겠어요)
          if (answer == 1) {
            // 예라고 답한 경우
            if (hasFactor) {
              weight = 1.25; // 포함하는 것에 1.25
            } else {
              weight = 0.9;  // 포함하지 않는 것에 0.9
            }
          } else if (answer == 0) {
            // 아니요라고 답한 경우
            if (hasFactor) {
              weight = 0.9;  // 포함하는 것에 0.9
            } else {
              weight = 1.25; // 포함하지 않는 것에 1.25
            }
          } else if (answer == -1) {
            // 모르겠어요라고 답한 경우
            weight = 1.0; // 변화 없음
          } else {
            weight = 1.0; // 기본값
          }
        } else {
          // 5단계 척도 질문 처리
          if (hasFactor) {
            weight = responseScale[answer]!;
          } else {
            // 반대 요인일 경우 가중치 반전 (1↔5, 2↔4)
            weight = responseScale[6 - answer]!;
          }
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

    // ✅ 현재 배치의 답변만 업데이트 (최종 단계에서 모든 답변을 누적)

    if ((currentPage + 1) * 5 >= allSocialFactors.length) {
      final sorted = diseaseProbabilities.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      // ✅ 상위 1개 (Top1) 질병만 추출
      final topDisease = sorted.first.key;

      print("\n🏁 모든 질문 완료! 최종 선택된 질병:");
      print("- $topDisease (${diseaseProbabilities[topDisease]!.toStringAsFixed(4)})");

      // ✅ 모든 사회적 이력 질문과 답변을 누적
      final allSocialHistoryAnswers = <String, String?>{};
      for (var social in allSocialFactors) {
        final question = predefinedQuestions[social];
        final answer = userAnswers[social];
        if (question != null && answer != null) {
          allSocialHistoryAnswers[question] = answer.toString();
        }
      }

      // ✅ 이전 단계의 questionHistory + 현재 단계의 모든 답변 병합
      final finalHistory = Map<String, String?>.from(widget.questionHistory)
        ..addAll(allSocialHistoryAnswers);

      print("📋 사회적 이력 단계에서 총 ${allSocialHistoryAnswers.length}개 질문 완료");
      print("📋 누적된 총 질문 수: ${finalHistory.length}개");

      // ✅ RefinedDiseasePage로 단일 질병 전달
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => RefinedDiseasePage(
            predictedDisease: topDisease, // ✅ String 하나만 전달
            userInput: widget.userInput,
            selectedSymptoms: widget.selectedSymptoms,
            // ✅ 모든 질문이 누적된 최종 히스토리 전달
            questionHistory: finalHistory,
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
    final end = (start + 5).clamp(0, allSocialFactors.length);
    return allSocialFactors.sublist(start, end);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  String _getAnswerText(int answer) {
    switch (answer) {
      case 1:
        return "예";
      case 0:
        return "아니요";
      case -1:
        return "모르겠어요";
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
  int _getCurrentQuestionNumber() {
    return (currentPage * 5) + 1;
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = const Color(0xFF9BB5C8);   // 사회적 이력 색상
    final secondaryColor = const Color(0xFFB5C7D3);
    final accentColor = const Color(0xFFC7D3E0);

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
            "사회적 이력",
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
                "사회적 이력을 분석하고 있습니다...",
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
    final progress = allSocialFactors.length > 0 ? (currentPage * 5) / allSocialFactors.length : 0.0;


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
          "사회적 이력",
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
                          color: allParts[3]['color'].withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          allParts[3]['icon'],
                          color: allParts[3]['color'],
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            allParts[3]['name'],
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: allParts[3]['color'],
                            ),
                          ),
                          Text(
                            allParts[3]['description'],
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
                        "질문 $currentQuestionNumber / ${allSocialFactors.length}",
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
                                colors: [allParts[3]['color'], secondaryColor],
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: allParts[3]['color'].withOpacity(0.3),
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
                      final isCurrentPart = index == 3; // 사회적 이력 파트가 현재 파트
                      final isCompleted = part['completed'] as bool;

                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: isCurrentPart
                              ? part['color'].withOpacity(0.1)
                              : isCompleted
                              ? Colors.green.withOpacity(0.1)
                              : Colors.grey.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isCurrentPart
                                ? part['color']
                                : isCompleted
                                ? Colors.green
                                : Colors.grey,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isCompleted ? Icons.check : part['icon'],
                              size: 12,
                              color: isCurrentPart
                                  ? part['color']
                                  : isCompleted
                                  ? Colors.green
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
                                    : isCompleted
                                    ? Colors.green
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
              final risk = entry.value;
              final question = predefinedQuestions[risk] ?? "$risk 관련 사회적 이력이 있으신가요?";
              final isAnswered = userAnswers[risk] != null;
              final questionNumber = currentQuestionNumber + index;

              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: isAnswered
                          ? (_isYesNoQuestion(risk)
                              ? (userAnswers[risk] == 1
                                  ? Colors.green.withOpacity(0.15)
                                  : userAnswers[risk] == 0
                                      ? Colors.red.withOpacity(0.15)
                                      : Colors.orange.withOpacity(0.15))
                              : allParts[3]['color'].withOpacity(0.15))
                          : Colors.grey.withOpacity(0.1),
                      blurRadius: isAnswered ? 12 : 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                  border: isAnswered
                      ? Border.all(
                          color: _isYesNoQuestion(risk)
                              ? (userAnswers[risk] == 1
                                  ? Colors.green.withOpacity(0.3)
                                  : userAnswers[risk] == 0
                                      ? Colors.red.withOpacity(0.3)
                                      : Colors.orange.withOpacity(0.3))
                              : allParts[3]['color'].withOpacity(0.3), 
                          width: 1.5
                        )
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
                              color: allParts[3]['color'].withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              "Q$questionNumber",
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: allParts[3]['color'],
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

                      // 질문 타입에 따른 선택 UI
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey[200]!),
                        ),
                        child: Column(
                          children: [
                            if (_isYesNoQuestion(risk)) ...[
                              // 예/아니요/모르겠어요 버튼들
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [
                                  // 예 버튼
                                  GestureDetector(
                                    onTap: () => setState(() => userAnswers[risk] = 1),
                                    child: Container(
                                      width: 70,
                                      height: 50,
                                      decoration: BoxDecoration(
                                        color: userAnswers[risk] == 1
                                            ? Colors.green
                                            : Colors.green.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(25),
                                        border: Border.all(
                                          color: userAnswers[risk] == 1
                                              ? Colors.green
                                              : Colors.green.withOpacity(0.3),
                                          width: 2,
                                        ),
                                      ),
                                      child: Center(
                                        child: Text(
                                          "예",
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: userAnswers[risk] == 1
                                                ? Colors.white
                                                : Colors.green,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  
                                  // 아니요 버튼
                                  GestureDetector(
                                    onTap: () => setState(() => userAnswers[risk] = 0),
                                    child: Container(
                                      width: 70,
                                      height: 50,
                                      decoration: BoxDecoration(
                                        color: userAnswers[risk] == 0
                                            ? Colors.red
                                            : Colors.red.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(25),
                                        border: Border.all(
                                          color: userAnswers[risk] == 0
                                              ? Colors.red
                                              : Colors.red.withOpacity(0.3),
                                          width: 2,
                                        ),
                                      ),
                                      child: Center(
                                        child: Text(
                                          "아니요",
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: userAnswers[risk] == 0
                                                ? Colors.white
                                                : Colors.red,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  
                                  // 모르겠어요 버튼
                                  GestureDetector(
                                    onTap: () => setState(() => userAnswers[risk] = -1),
                                    child: Container(
                                      width: 70,
                                      height: 50,
                                      decoration: BoxDecoration(
                                        color: userAnswers[risk] == -1
                                            ? Colors.orange
                                            : Colors.orange.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(25),
                                        border: Border.all(
                                          color: userAnswers[risk] == -1
                                              ? Colors.orange
                                              : Colors.orange.withOpacity(0.3),
                                          width: 2,
                                        ),
                                      ),
                                      child: Center(
                                        child: Text(
                                          "모르겠어요",
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: userAnswers[risk] == -1
                                                ? Colors.white
                                                : Colors.orange,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ] else ...[
                              // 5점 척도 라벨
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
                                      color: allParts[3]['color'],
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              
                              // 5단계 척도 선택 버튼들
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [
                                  for (int i = 1; i <= 5; i++)
                                    GestureDetector(
                                      onTap: () => setState(() => userAnswers[risk] = i),
                                      child: Container(
                                        width: 40,
                                        height: 40,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: userAnswers[risk] == i
                                                ? allParts[3]['color']
                                                : Colors.grey[300]!,
                                            width: userAnswers[risk] == i ? 3 : 2,
                                          ),
                                          color: userAnswers[risk] == i
                                              ? allParts[3]['color'].withOpacity(0.1)
                                              : Colors.transparent,
                                        ),
                                        child: Center(
                                          child: Text(
                                            i.toString(),
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                              color: userAnswers[risk] == i
                                                  ? allParts[3]['color']
                                                  : Colors.grey[600],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ],

                            const SizedBox(height: 8),

                            // 선택된 값 표시
                            if (userAnswers[risk] != null)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: _isYesNoQuestion(risk)
                                      ? (userAnswers[risk] == 1
                                          ? Colors.green.withOpacity(0.1)
                                          : userAnswers[risk] == 0
                                              ? Colors.red.withOpacity(0.1)
                                              : Colors.orange.withOpacity(0.1))
                                      : allParts[3]['color'].withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  _getAnswerText(userAnswers[risk]!),
                                  style: TextStyle(
                                    color: _isYesNoQuestion(risk)
                                        ? (userAnswers[risk] == 1
                                            ? Colors.green
                                            : userAnswers[risk] == 0
                                                ? Colors.red
                                                : Colors.orange)
                                        : allParts[3]['color'],
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
                      colors: [allParts[3]['color'], secondaryColor],
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
                          (currentPage + 1) * 5 >= allSocialFactors.length
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
