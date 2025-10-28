import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'riskfactor.dart';

class PastHistoryPage extends StatefulWidget {
  final List<String> topDiseases;
  final List<String> selectedSymptoms;
  final String userInput;
  final Map<String, String?> questionHistory;
  final Map<String, double> diseaseProbabilities;
  final Map<String, String>? personalInfo;

  const PastHistoryPage({
    super.key,
    required this.topDiseases,
    required this.selectedSymptoms,
    required this.userInput,
    required this.questionHistory,
    required this.diseaseProbabilities,
    this.personalInfo,
  });

  @override
  State<PastHistoryPage> createState() => _PastHistoryPageState();
}

class _PastHistoryPageState extends State<PastHistoryPage> {
  final ScrollController _scrollController = ScrollController();
  bool isLoading = true;
  int currentPage = 0;

  List<String> allHistories = [];
  Map<String, String> predefinedQuestions = {}; // ✅ 과거 이력 → 질문 매핑
  Map<String, int?> userAnswers = {}; // int? (예/아니요/모르겠어요: 1/0/-1)

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
      'completed': false, // 현재 진행 중
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
    _initializePastHistory();
  }

  /// ✅ 과거 질환 이력 → 질문 매핑
  void _setPredefinedQuestions() {
    predefinedQuestions = {
      "암": "암 진단을 받은 적이 있나요?",
      "항암 치료": "항암 치료를 받은 적이 있나요?",
      "담도질환": "담도 질환 병력이 있나요?",
      "최근 위장관 감염": "최근 위장관 감염을 앓은 적이 있나요?",
      "B형/C형 간염": "B형 또는 C형 간염 진단을 받은 적이 있나요?",
      "알코올성 간질환": "알코올성 간질환 진단을 받은 적이 있나요?",
      "만성 간염": "만성 간염을 앓은 적이 있나요?",
      "알코올 중독": "알코올 중독으로 치료받은 적이 있나요?",
      "다발성 근육통": "다발성 근육통 진단을 받은 적이 있나요?",
      "정신과 병력": "정신과 진료를 받은 적이 있나요?",
      "과잉 진료 경험": "과잉 진료를 받은 경험이 있나요?",
      "경추 디스크 질환": "경추(목) 디스크 질환 병력이 있나요?",
      "이전 공황 발작": "공황 발작을 경험한 적이 있나요?",
      "기능성 위장관 증상": "기능성 위장관 증상을 겪은 적이 있나요?",
      "불안장애": "불안장애 진단을 받은 적이 있나요?",
      "반복적 긴장": "반복적으로 긴장하거나 불안한 상태가 있었나요?",
      "손상": "신체 손상을 입은 적이 있나요?",
      "최근 운동": "최근 격렬한 운동을 한 적이 있나요?",
      "바이러스 감염": "바이러스 감염을 앓은 적이 있나요?",
      "반복적인 호흡기 감염": "호흡기 감염이 자주 있었나요?",
      "COPD": "COPD(만성폐쇄성폐질환) 진단을 받은 적이 있나요?",
      "반복 감염": "감염이 자주 발생한 적이 있나요?",
      "소아 폐렴": "어릴 때 폐렴을 앓은 적이 있나요?",
      "날음식 섭취": "날음식을 자주 섭취한 적이 있나요?",
      "풍토지역 여행": "풍토병이 있는 지역으로 여행한 적이 있나요?",
      "천식": "천식 진단을 받은 적이 있나요?",
      "기흉 병력": "기흉을 앓은 적이 있나요?",
      "흉부 외상": "가슴 부위를 다친 적이 있나요?",
      "대상포진 후 신경통": "대상포진 후 신경통이 있었나요?",
      "최근 과격한 운동": "최근 과격한 운동을 한 적이 있나요?",
      "외상": "외상을 입은 적이 있나요?",
      "담석": "담석이 있었던 적이 있나요?",
      "이전 담도 산통": "담도 산통을 경험한 적이 있나요?",
      "담석증": "담석증 진단을 받은 적이 있나요?",
      "비만": "비만 진단을 받은 적이 있나요?",
      "만성 고혈압": "만성 고혈압을 앓고 있거나 앓은 적이 있나요?",
      "결합조직질환": "결합조직 질환 병력이 있나요?",
      "이엽성 대동맥판": "이엽성 대동맥판 이상이 있었나요?",
      "동맥류": "동맥류 진단을 받은 적이 있나요?",
      "선천성 이엽성 판막": "선천성 이엽성 판막 질환이 있었나요?",
      "류머티즘 열": "류머티즘 열을 앓은 적이 있나요?",
      "고지혈증": "고지혈증 진단을 받은 적이 있나요?",
      "고혈압": "고혈압 병력이 있나요?",
      "수두": "수두를 앓은 적이 있나요?",
      "면역저하": "면역저하 상태였던 적이 있나요?",
      "대상포진": "대상포진을 앓은 적이 있나요?",
      "RA": "류머티즘 관절염(RA) 병력이 있나요?",
      "가족력": "가족 중 유사한 질환을 가진 분이 있나요?",
      "만성 기관지염": "만성 기관지염을 앓은 적이 있나요?",
      "흡연": "흡연을 한 적이 있나요?",
      "폐색전증": "폐색전증 병력이 있나요?",
      "심부정맥혈전증": "심부정맥혈전증을 앓은 적이 있나요?",
      "혈전성향": "혈전이 생기기 쉬운 체질이라는 진단을 받은 적이 있나요?",
      "유방암/폐암/림프종 방사선 치료": "유방암, 폐암, 림프종 방사선 치료를 받은 적이 있나요?",
      "위장관 시술": "위장관 관련 시술을 받은 적이 있나요?",
      "범불안장애": "범불안장애 진단을 받은 적이 있나요?",
      "당뇨": "당뇨병을 앓은 적이 있나요?",
      "협심증": "협심증 병력이 있나요?",
      "가족력 (HCM, 급사, 부정맥)": "가족 중 HCM, 급사, 부정맥 병력이 있나요?",
      "골연화증": "골연화증 진단을 받은 적이 있나요?",
      "저칼슘혈증": "저칼슘혈증을 앓은 적이 있나요?",
      "방사선 치료": "방사선 치료를 받은 적이 있나요?",
      "우울증": "우울증 진단을 받은 적이 있나요?",
      "만성 피로 증후군": "만성 피로 증후군을 앓은 적이 있나요?",
      "기능성 위장장애": "기능성 위장장애 진단을 받은 적이 있나요?",
      "헬리코박터 감염": "헬리코박터균 감염을 앓은 적이 있나요?",
      "NSAID 사용": "NSAID(소염진통제)를 장기간 사용한 적이 있나요?",
      "GERD": "역류성 식도염(GERD)을 앓은 적이 있나요?",
      "불안": "불안을 자주 느낀 적이 있나요?",
      "바렛 식도": "바렛 식도 진단을 받은 적이 있나요?",
      "만성 불안": "만성적인 불안을 경험한 적이 있나요?",
      "가족 스트레스": "가족과 관련된 스트레스를 경험한 적이 있나요?",
      "최근 바이러스 감염": "최근 바이러스 감염을 앓은 적이 있나요?",
      "자가면역질환": "자가면역질환 병력이 있나요?",
      "심근경색 후 증후군": "심근경색 후 증후군을 앓은 적이 있나요?",
      "색전증 병력": "색전증 병력이 있나요?",
      "심장종양 가족력": "가족 중 심장 종양 병력이 있나요?",
      "관상동맥질환": "관상동맥질환 병력이 있나요?",
      "심근경색": "심근경색을 앓은 적이 있나요?",
      "판막질환": "심장 판막질환 병력이 있나요?",
      "심낭염": "심낭염을 앓은 적이 있나요?",
      "심장수술": "심장 수술을 받은 적이 있나요?",
      "열 노출": "열에 장시간 노출된 적이 있나요?",
      "탈수": "탈수 상태를 경험한 적이 있나요?",
      "심각한 외상 경험": "심각한 외상을 경험한 적이 있나요?",
      "주요 우울 삽화": "주요 우울 삽화를 겪은 적이 있나요?",
      "식도열공 탈장": "식도열공 탈장 진단을 받은 적이 있나요?",
      "위축성 위염": "위축성 위염을 앓은 적이 있나요?",
      "BRCA 유전자 변이": "BRCA 유전자 변이가 있다고 들은 적이 있나요?",
      "호르몬 노출": "호르몬 치료나 노출을 받은 적이 있나요?",
      "선천성 심장질환": "선천성 심장질환 진단을 받은 적이 있나요?",
      "급사 가족력": "급사 가족력이 있나요?",
      "혈관연축 성향": "혈관연축 성향이 있다는 진단을 받은 적이 있나요?",
      "자궁내막증": "자궁내막증을 앓은 적이 있나요?",
      "자궁근종": "자궁근종 진단을 받은 적이 있나요?",
      "야외 노출": "야외에서 장시간 활동한 적이 있나요?",
      "영양실조": "영양실조를 경험한 적이 있나요?",
      "악성 종양": "악성 종양 진단을 받은 적이 있나요?",
      "최근 암 치료": "최근 암 치료를 받은 적이 있나요?",
      "정신과 질환": "정신과 질환 진단을 받은 적이 있나요?",
      "선천성 척추 기형": "선천성 척추 기형이 있었나요?",
      "소아기 천식": "어릴 때 천식을 앓은 적이 있나요?",
      "아토피": "아토피를 앓은 적이 있나요?",
      "알레르기 비염": "알레르기 비염이 있었나요?",
      "약물중독": "약물 중독 병력이 있나요?",
      "다른 부위의 파제트병": "다른 부위의 파제트병 병력이 있나요?",
      "잠복결핵": "잠복결핵 진단을 받은 적이 있나요?",
      "HIV": "HIV 감염 진단을 받은 적이 있나요?",
      "밀접 접촉": "감염자와 밀접 접촉한 적이 있나요?",
      "장기간 흡연": "장기간 흡연한 적이 있나요?",
      "폐렴": "폐렴을 앓은 적이 있나요?",
      "흡인": "흡인(음식이나 이물질을 들이마심) 경험이 있나요?",
      "구강 위생 불량": "구강 위생이 좋지 않았던 적이 있나요?",
      "선천성 심질환": "선천성 심질환 병력이 있나요?",
      "최근 상기도 감염": "최근 상기도(감기 등) 감염을 앓은 적이 있나요?",
      "만성 폐질환": "만성 폐질환 진단을 받은 적이 있나요?",
      "최근 수술": "최근 수술을 받은 적이 있나요?",
      "폐 결절": "폐 결절이 발견된 적이 있나요?",
      "심방세동 고주파 절제술": "심방세동 고주파 절제술을 받은 적이 있나요?",
      "폐정맥 폐쇄": "폐정맥 폐쇄 진단을 받은 적이 있나요?",
      "호흡기 감염": "호흡기 감염을 앓은 적이 있나요?",
      "결핵": "결핵을 앓은 적이 있나요?",
      "추간판 질환": "추간판(디스크) 질환이 있었나요?",
      "척추 퇴행성 질환": "척추 퇴행성 질환 진단을 받은 적이 있나요?"
    };
  }

  /// ✅ Firestore에서 과거 이력 로드
  Future<void> _initializePastHistory() async {
    final snapshot = await FirebaseFirestore.instance.collection("diseases_ko").get();

    candidateDiseases = snapshot.docs
        .map((doc) {
      final data = doc.data();
      final histories =
          (data["과거 질환 이력"] as List?)?.map((e) => e.toString()).toList() ?? [];
      return {"질환명": data["질환명"], "과거 질환 이력": histories};
    })
        .where((d) => widget.topDiseases.contains(d["질환명"]))
        .toList();


    print("🧬 선택된 상위 질병 (${candidateDiseases.length}개):");
    for (var d in candidateDiseases) {
      print("- ${d["질환명"]}");
    }

    for (var d in candidateDiseases) {
      final name = d["질환명"];
      diseaseProbabilities[name] = widget.diseaseProbabilities[name]!;
    }


    // ✅ 모든 과거 질환 이력 중복 제거
    final Set<String> allHistorySet = {};
    for (var d in candidateDiseases) {
      final list = d["과거 질환 이력"] as List<String>;
      allHistorySet.addAll(list);
    }

    print("✅ 중복 제거된 과거 질환 이력 개수: ${allHistorySet.length}");


    // ✅ 미리 정의된 질문이 있는 항목만 사용 (@가 있는 키는 @를 제거한 값으로 비교)
    allHistories = allHistorySet.where((h) {
      // 직접 키가 있는지 확인
      if (predefinedQuestions.containsKey(h)) {
        return true;
      }
      // @가 있는 키들 중에서 @를 제거한 값과 일치하는지 확인
      for (String key in predefinedQuestions.keys) {
        if (key.startsWith('@') && key.substring(1) == h) {
          return true;
        }
      }
      return false;
    }).toList();
    print("🎯 실제 질문으로 사용할 항목 수: ${allHistories.length}");

    setState(() => isLoading = false);
  }

  void _updateScores(Map<String, int?> batchAnswers) {
    print("\n🧩 [과거 질환 이력 반영 결과]");
    for (var d in candidateDiseases) {
      final name = d["질환명"];
      double prev = diseaseProbabilities[name]!;
      double score = prev;
      final histories = d["과거 질환 이력"] as List<String>;

      for (var entry in batchAnswers.entries) {
        final questionText = entry.key; // 질문 텍스트
        final answer = entry.value;
        if (answer == null) continue;

        // 질문 텍스트에서 원본 키를 찾기
        String? originalKey;
        for (var key in predefinedQuestions.keys) {
          if (predefinedQuestions[key] == questionText) {
            originalKey = key;
            break;
          }
        }
        
        if (originalKey == null) continue;

        // originalKey는 predefinedQuestions의 키(예: "@암"), histories는 Firestore의 값들(예: "암")
        // @가 있는 키는 @를 제거한 값으로 비교
        final historyToCheck = originalKey.startsWith('@') ? originalKey.substring(1) : originalKey;
        final hasHistory = histories.contains(historyToCheck);
        double weight;

        if (answer == 1) {
          // 예라고 답한 경우
          if (hasHistory) {
            weight = 1.25; // 포함하는 것에 1.25
          } else {
            weight = 0.9;  // 포함하지 않는 것에 0.9
          }
        } else if (answer == 0) {
          // 아니요라고 답한 경우
          if (hasHistory) {
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
    final batchAnswers = <String, int?>{};
    
    for (var f in currentBatch) {
      // Firestore의 원본 값(f)에 대응하는 predefinedQuestions 키를 찾기
      String? questionKey;
      if (predefinedQuestions.containsKey(f)) {
        questionKey = f;
      } else {
        // @가 있는 키들 중에서 @를 제거한 값과 일치하는지 확인
        for (String key in predefinedQuestions.keys) {
          if (key.startsWith('@') && key.substring(1) == f) {
            questionKey = key;
            break;
          }
        }
      }
      
      if (questionKey != null) {
        batchAnswers[predefinedQuestions[questionKey]!] = userAnswers[f];
      }
    }

    _updateScores(batchAnswers);

    // ✅ 현재 배치의 답변만 업데이트 (최종 단계에서 모든 답변을 누적)


    if ((currentPage + 1) * 5 >= allHistories.length) {
      // 과거질환 이력 파트 완료 - 위험요인 페이지로 이동
      final sorted = diseaseProbabilities.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      // ✅ 상위 40% 질병만 다음 단계로 전달
      final cutoff = (sorted.length * 0.4).ceil();
      final topDiseases = sorted.take(cutoff).map((e) => e.key).toList();

      print("\n🏁 과거질환 이력 분석 완료! 상위 ${topDiseases.length}개 질병:");
      for (var dis in topDiseases) {
        print("- $dis (${diseaseProbabilities[dis]!.toStringAsFixed(4)})");
      }

      // ✅ 모든 과거질환 이력 질문과 답변을 누적
      final allPastHistoryAnswers = <String, String?>{};
      for (var history in allHistories) {
        // Firestore의 원본 값(history)에 대응하는 predefinedQuestions 키를 찾기
        String? questionKey;
        if (predefinedQuestions.containsKey(history)) {
          questionKey = history;
        } else {
          // @가 있는 키들 중에서 @를 제거한 값과 일치하는지 확인
          for (String key in predefinedQuestions.keys) {
            if (key.startsWith('@') && key.substring(1) == history) {
              questionKey = key;
              break;
            }
          }
        }
        
        if (questionKey != null) {
          final question = predefinedQuestions[questionKey];
          final answer = userAnswers[history];
          if (question != null && answer != null) {
            allPastHistoryAnswers[question] = answer.toString();
          }
        }
      }

      // ✅ 이전 단계의 questionHistory + 현재 단계의 모든 답변 병합
      final finalHistory = Map<String, String?>.from(widget.questionHistory)
        ..addAll(allPastHistoryAnswers);

      print("📋 과거질환 이력 단계에서 총 ${allPastHistoryAnswers.length}개 질문 완료");
      print("📋 누적된 총 질문 수: ${finalHistory.length}개");

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => RiskFactorPage(
            topDiseases: topDiseases, // ✅ 리스트 그대로 전달
            userInput: widget.userInput,
            selectedSymptoms: widget.selectedSymptoms,
            questionHistory: finalHistory, // ✅ 모든 질문 누적된 히스토리 전달
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
    final end = (start + 5).clamp(0, allHistories.length);
    return allHistories.sublist(start, end);
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
      default:
        return "";
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = const Color(0xFF4A90A4); // 과거질환 이력 색상
    final secondaryColor = const Color(0xFF7FB3D3);

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
            "과거질환 이력", 
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
                "과거 이력을 분석하고 있습니다...",
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
    final progress = ((currentPage * 5) + currentBatch.length) / allHistories.length;
    final currentQuestionNumber = (currentPage * 5) + 1;

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
          "과거질환 이력", 
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
                          color: allParts[1]['color'].withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          allParts[1]['icon'],
                          color: allParts[1]['color'],
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            allParts[1]['name'],
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: allParts[1]['color'],
                            ),
                          ),
                          Text(
                            allParts[1]['description'],
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
                        "질문 $currentQuestionNumber / ${allHistories.length}",
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
                                colors: [allParts[1]['color'], secondaryColor],
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: allParts[1]['color'].withOpacity(0.3),
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
                      final isCurrentPart = index == 1; // 과거질환 이력 파트가 현재 파트
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
              final history = entry.value;
              
              // Firestore의 원본 값(history)에 대응하는 predefinedQuestions 키를 찾기
              String? questionKey;
              if (predefinedQuestions.containsKey(history)) {
                questionKey = history;
              } else {
                // @가 있는 키들 중에서 @를 제거한 값과 일치하는지 확인
                for (String key in predefinedQuestions.keys) {
                  if (key.startsWith('@') && key.substring(1) == history) {
                    questionKey = key;
                    break;
                  }
                }
              }
              
              final question = questionKey != null 
                  ? predefinedQuestions[questionKey]! 
                  : "$history 병력이 있으신가요?";
              final isAnswered = userAnswers[history] != null;
              final questionNumber = currentQuestionNumber + index;
              
              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: isAnswered 
                        ? (userAnswers[history] == 1
                            ? Colors.green.withOpacity(0.15)
                            : userAnswers[history] == 0
                                ? Colors.red.withOpacity(0.15)
                                : Colors.orange.withOpacity(0.15))
                        : Colors.grey.withOpacity(0.1),
                      blurRadius: isAnswered ? 12 : 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                  border: isAnswered 
                    ? Border.all(
                        color: userAnswers[history] == 1
                            ? Colors.green.withOpacity(0.3)
                            : userAnswers[history] == 0
                                ? Colors.red.withOpacity(0.3)
                                : Colors.orange.withOpacity(0.3), 
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
                              color: allParts[1]['color'].withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              "Q$questionNumber",
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: allParts[1]['color'],
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
                            // 예/아니요/모르겠어요 버튼들
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                // 예 버튼
                                GestureDetector(
                                  onTap: () => setState(() => userAnswers[history] = 1),
                                  child: Container(
                                    width: 70,
                                    height: 50,
                                    decoration: BoxDecoration(
                                      color: userAnswers[history] == 1
                                          ? Colors.green
                                          : Colors.green.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(25),
                                      border: Border.all(
                                        color: userAnswers[history] == 1
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
                                          color: userAnswers[history] == 1
                                              ? Colors.white
                                              : Colors.green,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                
                                // 아니요 버튼
                                GestureDetector(
                                  onTap: () => setState(() => userAnswers[history] = 0),
                                  child: Container(
                                    width: 70,
                                    height: 50,
                                    decoration: BoxDecoration(
                                      color: userAnswers[history] == 0
                                          ? Colors.red
                                          : Colors.red.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(25),
                                      border: Border.all(
                                        color: userAnswers[history] == 0
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
                                          color: userAnswers[history] == 0
                                              ? Colors.white
                                              : Colors.red,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                
                                // 모르겠어요 버튼
                                GestureDetector(
                                  onTap: () => setState(() => userAnswers[history] = -1),
                                  child: Container(
                                    width: 70,
                                    height: 50,
                                    decoration: BoxDecoration(
                                      color: userAnswers[history] == -1
                                          ? Colors.orange
                                          : Colors.orange.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(25),
                                      border: Border.all(
                                        color: userAnswers[history] == -1
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
                                          color: userAnswers[history] == -1
                                              ? Colors.white
                                              : Colors.orange,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            
                            const SizedBox(height: 8),
                            
                            // 선택된 값 표시
                            if (userAnswers[history] != null)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: userAnswers[history] == 1
                                      ? Colors.green.withOpacity(0.1)
                                      : userAnswers[history] == 0
                                          ? Colors.red.withOpacity(0.1)
                                          : Colors.orange.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  _getAnswerText(userAnswers[history]!),
                                  style: TextStyle(
                                    color: userAnswers[history] == 1
                                        ? Colors.green
                                        : userAnswers[history] == 0
                                            ? Colors.red
                                            : Colors.orange,
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
                          (currentPage + 1) * 5 >= allHistories.length
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
