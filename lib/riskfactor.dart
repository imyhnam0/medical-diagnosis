import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'socailhistory.dart'; // 다음 단계 페이지 (예: 사회적 이력 분석)

class RiskFactorPage extends StatefulWidget {
  final List<String> topDiseases;
  final List<String> selectedSymptoms;
  final String userInput;
  final Map<String, String?> questionHistory;
  final Map<String, double> diseaseProbabilities;
  final Map<String, String>? personalInfo;

  const RiskFactorPage({
    super.key,
    required this.topDiseases,
    required this.selectedSymptoms,
    required this.userInput,
    required this.questionHistory,
    required this.diseaseProbabilities,
    this.personalInfo,
  });

  @override
  State<RiskFactorPage> createState() => _RiskFactorPageState();
}

class _RiskFactorPageState extends State<RiskFactorPage> {
  final ScrollController _scrollController = ScrollController();
  bool isLoading = true;
  int currentPage = 0;

  List<String> allRiskFactors = [];
  Map<String, String> predefinedQuestions = {};
  Map<String, int?> userAnswers = {}; // int? (5단계 또는 예/아니요/모르겠어요: 1/0/-1)

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
      'completed': false, // 현재 진행 중
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
    _initializeRiskFactors();
  }

  /// ✅ 질문이 예/아니요 타입인지 확인
  bool _isYesNoQuestion(String questionKey) {
    return questionKey.startsWith('@');
  }

  /// ✅ 위험 요인 → 질문 매핑
  void _setPredefinedQuestions() {
    predefinedQuestions = {
      "@고용량 5-FU": "고용량 5-FU 항암제를 사용한 적이 있나요?",
      "@심독성 항암제": "심장에 독성을 줄 수 있는 항암제를 사용한 적이 있나요?",
      "@당뇨": "당뇨병 진단을 받은 적이 있나요?",
      "@담도 폐쇄": "담도 폐쇄 진단을 받은 적이 있나요?",
      "@B형/C형 간염": "B형 또는 C형 간염 병력이 있나요?",
      "@간경변": "간경변 진단을 받은 적이 있나요?",
      //"가족력": "가족 중 동일한 질환을 가진 사람이 있나요?",
      "알코올": "알코올을 자주 섭취하시나요?",
      "@비알코올성 지방간질환": "비알코올성 지방간질환 진단을 받은 적이 있나요?",
      "고령": "고령에 해당하시나요?",
      "@PMR": "다발성 근육통(PMR) 진단을 받은 적이 있나요?",
      "@여성": "여성입니까?",
      "건강 공포": "건강에 대한 과도한 불안을 느낀 적이 있나요?",
      "@과거 질환": "이전에 다른 질환을 앓은 적이 있나요?",
      "@경추증": "경추증(목뼈 퇴행성 질환) 진단을 받은 적이 있나요?",
      "@추간판 탈출": "추간판 탈출(디스크) 병력이 있나요?",
      "젊은 연령": "젊은 연령대에 속하시나요?",
      "민감한 성격": "평소 예민하거나 민감한 성격이신가요?",
      "스트레스": "스트레스를 자주 받으시나요?",
      "불안": "불안을 자주 느끼시나요?",
      "@공황 발작": "공황 발작을 경험한 적이 있나요?",
      "잘못된 인체공학": "자세나 근무환경 등 인체공학적 요인이 좋지 않나요?",
      "반복 동작": "같은 동작을 반복적으로 수행하나요?",
      "과사용": "신체를 과도하게 사용하는 활동을 자주 하나요?",
      "컨디션 저하": "컨디션이 자주 저하되나요?",
      "@흡연": "흡연을 하시나요?",
      "공기오염": "대기오염이 심한 환경에 노출되시나요?",
      "바이러스 감염": "바이러스 감염을 자주 겪으시나요?",
      "@면역결핍": "면역결핍 상태이거나 면역억제 치료를 받으셨나요?",
      "@과거 감염": "이전에 감염 질환을 앓은 적이 있나요?",
      "@풍토지역": "풍토병이 있는 지역에 거주하거나 방문한 적이 있나요?",
      "@덜 익힌 고기": "덜 익힌 고기를 섭취한 적이 있나요?",
      "@폐질환": "폐질환 병력이 있나요?",
      "@기계환기": "기계 환기를 받은 적이 있나요?",
      "@대상포진": "대상포진을 앓은 적이 있나요?",
      "@격투기": "격투기나 충격이 큰 운동을 하시나요?",
      "@낙상": "낙상(넘어짐) 사고를 당한 적이 있나요?",
      "육체 노동": "육체 노동을 자주 하시나요?",
      "나쁜 자세": "나쁜 자세를 자주 취하시나요?",
      "@담석": "담석이 있었던 적이 있나요?",
      "@감염": "감염을 앓은 적이 있나요?",
      "@비만": "비만 진단을 받은 적이 있나요?",
      "급격한 체중 감소": "최근 체중이 급격히 감소한 적이 있나요?",
      "@임신": "현재 임신 중이거나 임신 경험이 있나요?",
      "@고혈압": "고혈압을 앓고 있나요?",
      "@마판증후군": "마판증후군 진단을 받은 적이 있나요?",
      "@엘러스-단로스증후군": "엘러스-단로스증후군 병력이 있나요?",
      "@남성": "남성이신가요?",
      "@고지혈증": "고지혈증 진단을 받은 적이 있나요?",
      "@50세 이상": "연령이 50세 이상인가요?",
      "@면역저하": "면역저하 상태이거나 관련 약을 복용 중인가요?",
      //"유전적 소인": "유전적으로 해당 질환 소인이 있다고 들은 적이 있나요?",
      "환경적 요인": "유해한 환경 요인에 자주 노출되시나요?",
      "@폐색전증 병력": "폐색전증 병력이 있나요?",
      "@혈액응고장애": "혈액응고 장애 진단을 받은 적이 있나요?",
      "@암": "암 진단을 받은 적이 있나요?",
      "@카테터 삽입": "중심정맥 카테터를 삽입한 적이 있나요?",
      "@방사선 치료": "방사선 치료를 받은 적이 있나요?",
      "@심낭 손상": "심낭 손상 진단을 받은 적이 있나요?",
      "구토": "구토를 자주 하시나요?",
      "@알코올 중독": "알코올 중독 진단을 받은 적이 있나요?",
      "@이상지질혈증": "이상지질혈증 진단을 받은 적이 있나요?",
      //"나이": "연령이 해당 질환의 위험군에 속하나요?",
      "@유전자 돌연변이": "유전자 돌연변이가 있다고 들은 적이 있나요?",
      "젊은 나이": "젊은 나이에 해당하시나요?",
      "햇빛 부족": "햇빛을 충분히 받지 못하는 생활을 하시나요?",
      "@신경총 외상": "신경총(신경 묶음)에 외상을 입은 적이 있나요?",
      "@수술": "수술을 받은 적이 있나요?",
      "@외상": "외상을 입은 적이 있나요?",
      "@기능성 장애": "기능성 장애(기능 이상) 진단을 받은 적이 있나요?",
      "NSAID 사용": "NSAID(소염진통제)를 자주 사용하시나요?",
      "@헬리코박터 감염": "헬리코박터균 감염을 앓은 적이 있나요?",
      "@식도 운동장애": "식도 운동장애 진단을 받은 적이 있나요?",
      "@GERD": "역류성 식도염(GERD)을 앓은 적이 있나요?",
      "@바렛 식도": "바렛 식도 진단을 받은 적이 있나요?",
      "@학대 경험": "학대나 외상을 경험한 적이 있나요?",
      //"연령": "연령이 위험군에 해당되나요?",
      "@바이러스": "바이러스 감염을 경험한 적이 있나요?",
      "@자가면역질환": "자가면역질환 병력이 있나요?",
      "@심근경색 후": "심근경색 이후 합병증이 있었나요?",
      "@카니 증후군": "카니 증후군 진단을 받은 적이 있나요?",
      "@관상동맥질환": "관상동맥질환 병력이 있나요?",
      "@결합조직질환": "결합조직 질환 진단을 받은 적이 있나요?",
      "@항응고제 치료": "항응고제 치료를 받고 있나요?",
      "고온 환경": "고온 환경에서 자주 일하거나 생활하나요?",
      "냉각 부족": "체온 조절이 어려운 환경에 있나요?",
      "@PTSD": "외상 후 스트레스 장애(PTSD)를 겪은 적이 있나요?",
      "@전쟁": "전쟁이나 유사한 극심한 사건을 겪은 적이 있나요?",
      "폭력": "폭력을 경험한 적이 있나요?",
      "@정신질환": "정신질환 병력이 있나요?",
      "@만성질환": "만성질환을 앓고 있나요?",
      "염분 많은 식단": "염분이 많은 식단을 자주 섭취하시나요?",
      "@BRCA 유전자": "BRCA 유전자 변이가 있다고 들은 적이 있나요?",
      "@에스트로겐 노출": "에스트로겐에 노출된 적이 있나요?",
      "@선천성 기형": "선천성 기형이 있었나요?",
      "@관상동맥 이상 가족력": "가족 중 관상동맥 이상 병력이 있나요?",
      "@혈관 과민성": "혈관 과민성 진단을 받은 적이 있나요?",
      "@자궁근종": "자궁근종을 앓은 적이 있나요?",
      "@다낭성 난소증후군": "다낭성 난소증후군 진단을 받은 적이 있나요?",
      "@저혈당": "저혈당을 경험한 적이 있나요?",
      "허약": "허약하거나 체력이 약한 편인가요?",
      "@HLA 유전자": "HLA 유전자 관련 이상이 있다고 들은 적이 있나요?",
      "자외선": "자외선에 자주 노출되시나요?",
      "@암 병력": "암 병력이 있나요?",
      "전환 성향": "신체 증상을 심리적으로 전환하는 경향이 있나요?",
      "@아동기 외상": "어린 시절 외상을 경험한 적이 있나요?",
      "@퇴행성 디스크 질환": "퇴행성 디스크 질환 진단을 받은 적이 있나요?",
      "@알레르기": "알레르기 병력이 있나요?",
      "도시 생활": "도시 환경에서 생활하시나요?",
      "@코카인": "코카인을 사용한 적이 있나요?",
      "젊은 남성": "젊은 남성에 해당하시나요?",
      "@유전": "유전적 요인이 있나요?",
      "@HIV": "HIV 감염 병력이 있나요?",
      "@영양실조": "영양실조를 경험한 적이 있나요?",
      "@흡인": "흡인(이물질을 들이마심) 경험이 있나요?",
      "@문맥고혈압": "문맥고혈압 진단을 받은 적이 있나요?",
      "@HIV 감염": "HIV 감염 진단을 받은 적이 있나요?",
      "@고령/소아": "고령이거나 소아에 해당하시나요?",
      "@혈전성향": "혈전이 잘 생기는 체질이라는 말을 들은 적이 있나요?",
      "@정맥혈전증 과거력": "정맥혈전증 병력이 있나요?",
      "@부동": "오랜 기간 움직이지 못한 적이 있나요?",
      "@방사선": "방사선에 노출된 적이 있나요?",
      "@석면": "석면에 노출된 적이 있나요?",
      "@절제술 후": "절제술을 받은 적이 있나요?",
      "@선천성 이상": "선천성 이상이 있었나요?",
      "@심장 수술 병력": "심장 수술을 받은 적이 있나요?",
      "@흉부 수술": "흉부 수술을 받은 적이 있나요?",
      "@척추 퇴행성 변화": "척추 퇴행성 변화를 진단받은 적이 있나요?",
      "잘못된 자세": "잘못된 자세를 자주 취하시나요?",
      "@노화": "노화로 인한 증상이 있나요?",
      "@척추측만증": "척추측만증 진단을 받은 적이 있나요?"
    };
  }

  /// ✅ Firestore에서 위험 요인 로드
  Future<void> _initializeRiskFactors() async {
    final snapshot = await FirebaseFirestore.instance.collection("diseases_ko").get();

    candidateDiseases = snapshot.docs
        .map((doc) {
      final data = doc.data();
      final risks =
          (data["위험 요인"] as List?)?.map((e) => e.toString()).toList() ?? [];
      return {"질환명": data["질환명"], "위험 요인": risks};
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


    final Set<String> allRiskSet = {};
    for (var d in candidateDiseases) {
      final list = d["위험 요인"] as List<String>;
      allRiskSet.addAll(list);
    }

    print("✅ 중복 제거된 위험 요인 개수: ${allRiskSet.length}");


    // ✅ 미리 정의된 질문이 있는 항목만 사용 (@가 있는 키는 @를 제거한 값으로 비교)
    allRiskFactors = allRiskSet.where((r) {
      // 직접 키가 있는지 확인
      if (predefinedQuestions.containsKey(r)) {
        return true;
      }
      // @가 있는 키들 중에서 @를 제거한 값과 일치하는지 확인
      for (String key in predefinedQuestions.keys) {
        if (key.startsWith('@') && key.substring(1) == r) {
          return true;
        }
      }
      return false;
    }).toList();
    print("🎯 실제 질문으로 사용할 위험 요인: ${allRiskFactors.length}");

    setState(() => isLoading = false);
  }

  void _updateScores(Map<String, int?> batchAnswers) {
    // 리커트 척도 (1~5)에 따른 가중치
    final responseScale = {
      1: 0.7,   // 전혀 아니다
      2: 0.85,  // 아니다
      3: 1.0,   // 모르겠다
      4: 1.15,  // 그렇다
      5: 1.3,   // 매우 그렇다
    };

    print("\n🧩 [위험 요인 응답 반영 결과]");
    for (var d in candidateDiseases) {
      final name = d["질환명"];
      double prev = diseaseProbabilities[name]!;
      double score = prev;
      final risks = d["위험 요인"] as List<String>;

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

        // originalKey는 predefinedQuestions의 키(예: "@흡연"), risks는 Firestore의 값들(예: "흡연")
        // @가 있는 키는 @를 제거한 값으로 비교
        final riskToCheck = originalKey.startsWith('@') ? originalKey.substring(1) : originalKey;
        final hasRisk = risks.contains(riskToCheck);
        double weight;

        if (_isYesNoQuestion(originalKey)) {
          // 예/아니요/모르겠어요 질문 처리 (1: 예, 0: 아니요, -1: 모르겠어요)
          if (answer == 1) {
            // 예라고 답한 경우
            if (hasRisk) {
              weight = 1.25; // 포함하는 것에 1.25
            } else {
              weight = 0.9;  // 포함하지 않는 것에 0.9
            }
          } else if (answer == 0) {
            // 아니요라고 답한 경우
            if (hasRisk) {
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
          if (hasRisk) {
            weight = responseScale[answer]!;
          } else {
            // 반대 항목일 경우 반전 (1↔5, 2↔4)
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


  /// ✅ 다음 단계로 이동
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

    if ((currentPage + 1) * 5 >= allRiskFactors.length) {
      // 위험요인 파트 완료 - 사회적 이력 페이지로 이동
      final sorted = diseaseProbabilities.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      final cutoff = (sorted.length * 0.3).ceil();
      final topDiseases = sorted.take(cutoff).map((e) => e.key).toList();

      print("\n🏁 위험요인 분석 완료! 상위 ${topDiseases.length}개 질병:");
      for (var dis in topDiseases) {
        print("- $dis (${diseaseProbabilities[dis]!.toStringAsFixed(4)})");
      }

      // ✅ 모든 위험요인 질문과 답변을 누적
      final allRiskFactorAnswers = <String, String?>{};
      for (var risk in allRiskFactors) {
        // Firestore의 원본 값(risk)에 대응하는 predefinedQuestions 키를 찾기
        String? questionKey;
        if (predefinedQuestions.containsKey(risk)) {
          questionKey = risk;
        } else {
          // @가 있는 키들 중에서 @를 제거한 값과 일치하는지 확인
          for (String key in predefinedQuestions.keys) {
            if (key.startsWith('@') && key.substring(1) == risk) {
              questionKey = key;
              break;
            }
          }
        }
        
        if (questionKey != null) {
          final question = predefinedQuestions[questionKey];
          final answer = userAnswers[risk];
          if (question != null && answer != null) {
            allRiskFactorAnswers[question] = answer.toString();
          }
        }
      }

      // ✅ 이전 단계의 questionHistory + 현재 단계의 모든 답변 병합
      final finalHistory = Map<String, String?>.from(widget.questionHistory)
        ..addAll(allRiskFactorAnswers);

      print("📋 위험요인 단계에서 총 ${allRiskFactorAnswers.length}개 질문 완료");
      print("📋 누적된 총 질문 수: ${finalHistory.length}개");

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => SocialHistoryPage(
            topDiseases: topDiseases,
            userInput: widget.userInput,
            selectedSymptoms: widget.selectedSymptoms,
            questionHistory: finalHistory,
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
    final end = (start + 5).clamp(0, allRiskFactors.length);
    return allRiskFactors.sublist(start, end);
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
    final primaryColor = const Color(0xFF7FB3D3); // 위험요인 색상
    final secondaryColor = const Color(0xFF9BB5C8);
    final accentColor = const Color(0xFFB5C7D3);

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
            "위험요인", 
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
                "위험요인을 분석하고 있습니다...",
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
    final progress = allRiskFactors.length > 0 ? (currentPage * 5) / allRiskFactors.length : 0.0;

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
          "위험요인", 
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
                          color: allParts[2]['color'].withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          allParts[2]['icon'],
                          color: allParts[2]['color'],
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            allParts[2]['name'],
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: allParts[2]['color'],
                            ),
                          ),
                          Text(
                            allParts[2]['description'],
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
                        "질문 $currentQuestionNumber / ${allRiskFactors.length}",
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
                                colors: [allParts[2]['color'], secondaryColor],
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: allParts[2]['color'].withOpacity(0.3),
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
                      final isCurrentPart = index == 2; // 위험요인 파트가 현재 파트
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
              
              // Firestore의 원본 값(risk)에 대응하는 predefinedQuestions 키를 찾기
              String? questionKey;
              if (predefinedQuestions.containsKey(risk)) {
                questionKey = risk;
              } else {
                // @가 있는 키들 중에서 @를 제거한 값과 일치하는지 확인
                for (String key in predefinedQuestions.keys) {
                  if (key.startsWith('@') && key.substring(1) == risk) {
                    questionKey = key;
                    break;
                  }
                }
              }
              
              final question = questionKey != null 
                  ? predefinedQuestions[questionKey]! 
                  : "$risk 관련 위험 요인이 있으신가요?";
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
                        ? (_isYesNoQuestion(questionKey ?? "")
                            ? (userAnswers[risk] == 1
                                ? Colors.green.withOpacity(0.15)
                                : userAnswers[risk] == 0
                                    ? Colors.red.withOpacity(0.15)
                                    : Colors.orange.withOpacity(0.15))
                            : allParts[2]['color'].withOpacity(0.15))
                        : Colors.grey.withOpacity(0.1),
                      blurRadius: isAnswered ? 12 : 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                  border: isAnswered 
                    ? Border.all(
                        color: _isYesNoQuestion(questionKey ?? "")
                            ? (userAnswers[risk] == 1
                                ? Colors.green.withOpacity(0.3)
                                : userAnswers[risk] == 0
                                    ? Colors.red.withOpacity(0.3)
                                    : Colors.orange.withOpacity(0.3))
                            : allParts[2]['color'].withOpacity(0.3), 
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
                              color: allParts[2]['color'].withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              "Q$questionNumber",
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: allParts[2]['color'],
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
                            if (_isYesNoQuestion(questionKey ?? "")) ...[
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
                                      color: allParts[2]['color'],
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
                                                ? allParts[2]['color']
                                                : Colors.grey[300]!,
                                            width: userAnswers[risk] == i ? 3 : 2,
                                          ),
                                          color: userAnswers[risk] == i
                                              ? allParts[2]['color'].withOpacity(0.1)
                                              : Colors.transparent,
                                        ),
                                        child: Center(
                                          child: Text(
                                            i.toString(),
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                              color: userAnswers[risk] == i
                                                  ? allParts[2]['color']
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
                                  color: _isYesNoQuestion(questionKey ?? "")
                                      ? (userAnswers[risk] == 1
                                          ? Colors.green.withOpacity(0.1)
                                          : userAnswers[risk] == 0
                                              ? Colors.red.withOpacity(0.1)
                                              : Colors.orange.withOpacity(0.1))
                                      : allParts[2]['color'].withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  _getAnswerText(userAnswers[risk]!),
                                  style: TextStyle(
                                    color: _isYesNoQuestion(questionKey ?? "")
                                        ? (userAnswers[risk] == 1
                                            ? Colors.green
                                            : userAnswers[risk] == 0
                                                ? Colors.red
                                                : Colors.orange)
                                        : allParts[2]['color'],
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
                      colors: [allParts[2]['color'], secondaryColor],
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
                          (currentPage + 1) * 5 >= allRiskFactors.length
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
