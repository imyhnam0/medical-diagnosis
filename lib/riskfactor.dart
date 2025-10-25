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


  const RiskFactorPage({
    super.key,
    required this.topDiseases,
    required this.selectedSymptoms,
    required this.userInput,
    required this.questionHistory,
    required this.diseaseProbabilities,
  });

  @override
  State<RiskFactorPage> createState() => _RiskFactorPageState();
}

class _RiskFactorPageState extends State<RiskFactorPage> {
  bool isLoading = true;
  int currentPage = 0;

  List<String> allRiskFactors = [];
  Map<String, String> predefinedQuestions = {};
  Map<String, String?> userAnswers = {};

  Map<String, double> diseaseProbabilities = {};
  List<Map<String, dynamic>> candidateDiseases = [];

  @override
  void initState() {
    super.initState();
    _setPredefinedQuestions();
    _initializeRiskFactors();
  }

  /// ✅ 위험 요인 → 질문 매핑
  void _setPredefinedQuestions() {
    predefinedQuestions = {
      "고용량 5-FU": "고용량 5-FU 항암제를 사용한 적이 있나요?",
      "심독성 항암제": "심장에 독성을 줄 수 있는 항암제를 사용한 적이 있나요?",
      "당뇨": "당뇨병 진단을 받은 적이 있나요?",
      "담도 폐쇄": "담도 폐쇄 진단을 받은 적이 있나요?",
      "B형/C형 간염": "B형 또는 C형 간염 병력이 있나요?",
      "간경변": "간경변 진단을 받은 적이 있나요?",
      "가족력": "가족 중 동일한 질환을 가진 사람이 있나요?",
      "알코올": "알코올을 자주 섭취하시나요?",
      "비알코올성 지방간질환": "비알코올성 지방간질환 진단을 받은 적이 있나요?",
      "고령": "고령에 해당하시나요?",
      "PMR": "다발성 근육통(PMR) 진단을 받은 적이 있나요?",
      "여성": "여성입니까?",
      "건강 공포": "건강에 대한 과도한 불안을 느낀 적이 있나요?",
      "과거 질환": "이전에 다른 질환을 앓은 적이 있나요?",
      "경추증": "경추증(목뼈 퇴행성 질환) 진단을 받은 적이 있나요?",
      "추간판 탈출": "추간판 탈출(디스크) 병력이 있나요?",
      "젊은 연령": "젊은 연령대에 속하시나요?",
      "민감한 성격": "평소 예민하거나 민감한 성격이신가요?",
      "스트레스": "스트레스를 자주 받으시나요?",
      "불안": "불안을 자주 느끼시나요?",
      "공황 발작": "공황 발작을 경험한 적이 있나요?",
      "잘못된 인체공학": "자세나 근무환경 등 인체공학적 요인이 좋지 않나요?",
      "반복 동작": "같은 동작을 반복적으로 수행하나요?",
      "과사용": "신체를 과도하게 사용하는 활동을 자주 하나요?",
      "컨디션 저하": "컨디션이 자주 저하되나요?",
      "흡연": "흡연을 하시나요?",
      "공기오염": "대기오염이 심한 환경에 노출되시나요?",
      "바이러스 감염": "바이러스 감염을 자주 겪으시나요?",
      "면역결핍": "면역결핍 상태이거나 면역억제 치료를 받으셨나요?",
      "과거 감염": "이전에 감염 질환을 앓은 적이 있나요?",
      "풍토지역": "풍토병이 있는 지역에 거주하거나 방문한 적이 있나요?",
      "덜 익힌 고기": "덜 익힌 고기를 섭취한 적이 있나요?",
      "폐질환": "폐질환 병력이 있나요?",
      "기계환기": "기계 환기를 받은 적이 있나요?",
      "대상포진": "대상포진을 앓은 적이 있나요?",
      "격투기": "격투기나 충격이 큰 운동을 하시나요?",
      "낙상": "낙상(넘어짐) 사고를 당한 적이 있나요?",
      "육체 노동": "육체 노동을 자주 하시나요?",
      "나쁜 자세": "나쁜 자세를 자주 취하시나요?",
      "담석": "담석이 있었던 적이 있나요?",
      "감염": "감염을 앓은 적이 있나요?",
      "비만": "비만 진단을 받은 적이 있나요?",
      "급격한 체중 감소": "최근 체중이 급격히 감소한 적이 있나요?",
      "임신": "현재 임신 중이거나 임신 경험이 있나요?",
      "고혈압": "고혈압을 앓고 있나요?",
      "마판증후군": "마판증후군 진단을 받은 적이 있나요?",
      "엘러스-단로스증후군": "엘러스-단로스증후군 병력이 있나요?",
      "남성": "남성이신가요?",
      "고지혈증": "고지혈증 진단을 받은 적이 있나요?",
      "50세 이상": "연령이 50세 이상인가요?",
      "면역저하": "면역저하 상태이거나 관련 약을 복용 중인가요?",
      "유전적 소인": "유전적으로 해당 질환 소인이 있다고 들은 적이 있나요?",
      "환경적 요인": "유해한 환경 요인에 자주 노출되시나요?",
      "폐색전증 병력": "폐색전증 병력이 있나요?",
      "혈액응고장애": "혈액응고 장애 진단을 받은 적이 있나요?",
      "암": "암 진단을 받은 적이 있나요?",
      "카테터 삽입": "중심정맥 카테터를 삽입한 적이 있나요?",
      "방사선 치료": "방사선 치료를 받은 적이 있나요?",
      "심낭 손상": "심낭 손상 진단을 받은 적이 있나요?",
      "구토": "구토를 자주 하시나요?",
      "알코올 중독": "알코올 중독 진단을 받은 적이 있나요?",
      "이상지질혈증": "이상지질혈증 진단을 받은 적이 있나요?",
      "나이": "연령이 해당 질환의 위험군에 속하나요?",
      "유전자 돌연변이": "유전자 돌연변이가 있다고 들은 적이 있나요?",
      "젊은 나이": "젊은 나이에 해당하시나요?",
      "햇빛 부족": "햇빛을 충분히 받지 못하는 생활을 하시나요?",
      "신경총 외상": "신경총(신경 묶음)에 외상을 입은 적이 있나요?",
      "수술": "수술을 받은 적이 있나요?",
      "외상": "외상을 입은 적이 있나요?",
      "기능성 장애": "기능성 장애(기능 이상) 진단을 받은 적이 있나요?",
      "NSAID 사용": "NSAID(소염진통제)를 자주 사용하시나요?",
      "헬리코박터 감염": "헬리코박터균 감염을 앓은 적이 있나요?",
      "식도 운동장애": "식도 운동장애 진단을 받은 적이 있나요?",
      "GERD": "역류성 식도염(GERD)을 앓은 적이 있나요?",
      "바렛 식도": "바렛 식도 진단을 받은 적이 있나요?",
      "학대 경험": "학대나 외상을 경험한 적이 있나요?",
      "연령": "연령이 위험군에 해당되나요?",
      "바이러스": "바이러스 감염을 경험한 적이 있나요?",
      "자가면역질환": "자가면역질환 병력이 있나요?",
      "심근경색 후": "심근경색 이후 합병증이 있었나요?",
      "카니 증후군": "카니 증후군 진단을 받은 적이 있나요?",
      "관상동맥질환": "관상동맥질환 병력이 있나요?",
      "결합조직질환": "결합조직 질환 진단을 받은 적이 있나요?",
      "항응고제 치료": "항응고제 치료를 받고 있나요?",
      "고온 환경": "고온 환경에서 자주 일하거나 생활하나요?",
      "냉각 부족": "체온 조절이 어려운 환경에 있나요?",
      "PTSD": "외상 후 스트레스 장애(PTSD)를 겪은 적이 있나요?",
      "전쟁": "전쟁이나 유사한 극심한 사건을 겪은 적이 있나요?",
      "폭력": "폭력을 경험한 적이 있나요?",
      "정신질환": "정신질환 병력이 있나요?",
      "만성질환": "만성질환을 앓고 있나요?",
      "염분 많은 식단": "염분이 많은 식단을 자주 섭취하시나요?",
      "BRCA 유전자": "BRCA 유전자 변이가 있다고 들은 적이 있나요?",
      "에스트로겐 노출": "에스트로겐에 노출된 적이 있나요?",
      "선천성 기형": "선천성 기형이 있었나요?",
      "관상동맥 이상 가족력": "가족 중 관상동맥 이상 병력이 있나요?",
      "혈관 과민성": "혈관 과민성 진단을 받은 적이 있나요?",
      "자궁근종": "자궁근종을 앓은 적이 있나요?",
      "다낭성 난소증후군": "다낭성 난소증후군 진단을 받은 적이 있나요?",
      "저혈당": "저혈당을 경험한 적이 있나요?",
      "허약": "허약하거나 체력이 약한 편인가요?",
      "HLA 유전자": "HLA 유전자 관련 이상이 있다고 들은 적이 있나요?",
      "자외선": "자외선에 자주 노출되시나요?",
      "암 병력": "암 병력이 있나요?",
      "전환 성향": "신체 증상을 심리적으로 전환하는 경향이 있나요?",
      "아동기 외상": "어린 시절 외상을 경험한 적이 있나요?",
      "퇴행성 디스크 질환": "퇴행성 디스크 질환 진단을 받은 적이 있나요?",
      "알레르기": "알레르기 병력이 있나요?",
      "도시 생활": "도시 환경에서 생활하시나요?",
      "코카인": "코카인을 사용한 적이 있나요?",
      "젊은 남성": "젊은 남성에 해당하시나요?",
      "유전": "유전적 요인이 있나요?",
      "HIV": "HIV 감염 병력이 있나요?",
      "영양실조": "영양실조를 경험한 적이 있나요?",
      "흡인": "흡인(이물질을 들이마심) 경험이 있나요?",
      "문맥고혈압": "문맥고혈압 진단을 받은 적이 있나요?",
      "HIV 감염": "HIV 감염 진단을 받은 적이 있나요?",
      "고령/소아": "고령이거나 소아에 해당하시나요?",
      "혈전성향": "혈전이 잘 생기는 체질이라는 말을 들은 적이 있나요?",
      "정맥혈전증 과거력": "정맥혈전증 병력이 있나요?",
      "부동": "오랜 기간 움직이지 못한 적이 있나요?",
      "방사선": "방사선에 노출된 적이 있나요?",
      "석면": "석면에 노출된 적이 있나요?",
      "절제술 후": "절제술을 받은 적이 있나요?",
      "선천성 이상": "선천성 이상이 있었나요?",
      "심장 수술 병력": "심장 수술을 받은 적이 있나요?",
      "흉부 수술": "흉부 수술을 받은 적이 있나요?",
      "척추 퇴행성 변화": "척추 퇴행성 변화를 진단받은 적이 있나요?",
      "잘못된 자세": "잘못된 자세를 자주 취하시나요?",
      "노화": "노화로 인한 증상이 있나요?",
      "척추측만증": "척추측만증 진단을 받은 적이 있나요?"
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


    allRiskFactors = allRiskSet.where((r) => predefinedQuestions.containsKey(r)).toList();
    print("🎯 실제 질문으로 사용할 위험 요인: ${allRiskFactors.length}");

    setState(() => isLoading = false);
  }

  /// ✅ 점수 업데이트
  void _updateScores(Map<String, String?> batchAnswers) {
    const double alpha = 1.25;
    const double decay = 0.9;

    print("\n🧩 [위험 요인 응답 반영 결과]");
    for (var d in candidateDiseases) {
      final name = d["질환명"];
      double prev = diseaseProbabilities[name]!;
      double score = prev;
      final risks = d["위험 요인"] as List<String>;

      for (var entry in batchAnswers.entries) {
        final risk = entry.key;
        final answer = entry.value;
        if (answer == null) continue;

        final hasRisk = risks.contains(risk);
        if (answer == "예" && hasRisk) {
          score *= alpha;

        } else if (answer == "아니오" && !hasRisk) {
          score *= alpha;

        } else if (answer == "모르겠어요") {

        } else {
          score *= decay;

        }
      }

      diseaseProbabilities[name] = score;
      print("➡️ ${name}: ${prev.toStringAsFixed(3)} → ${score.toStringAsFixed(3)}");
    }

    print("\n📊 현재 전체 질병 확률 상태:");
    diseaseProbabilities.forEach((key, value) {
      print("- $key: ${value.toStringAsFixed(4)}");
    });
  }

  /// ✅ 다음 단계로 이동
  void _onConfirmBatch() {
    final currentBatch = _getCurrentBatch();
    final batchAnswers = {
      for (var f in currentBatch)
        predefinedQuestions[f]!: userAnswers[f]
    };

    _updateScores(batchAnswers);

    // 누적 질문 기록
    final updatedHistory = Map<String, String?>.from(widget.questionHistory)
      ..addAll(batchAnswers);

    if ((currentPage + 1) * 5 >= allRiskFactors.length) {
      final sorted = diseaseProbabilities.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      final cutoff = (sorted.length * 0.3).ceil();
      final topDiseases = sorted.take(cutoff).map((e) => e.key).toList();

      print("\n🏁 모든 위험 요인 질문 완료! 상위 질병 목록:");
      for (var dis in topDiseases) {
        print("- $dis (${diseaseProbabilities[dis]!.toStringAsFixed(4)})");
      }

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => SocialHistoryPage(
            topDiseases: topDiseases,
            userInput: widget.userInput,
            selectedSymptoms: widget.selectedSymptoms,
            questionHistory: updatedHistory,
            diseaseProbabilities: Map<String, double>.from(diseaseProbabilities),
          ),
        ),
      );
    } else {
      setState(() => currentPage++);
    }
  }

  List<String> _getCurrentBatch() {
    final start = currentPage * 5;
    final end = (start + 5).clamp(0, allRiskFactors.length);
    return allRiskFactors.sublist(start, end);
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final currentBatch = _getCurrentBatch();
    final progress = ((currentPage * 5) + currentBatch.length) / allRiskFactors.length;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Risk factors", style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF283593),
        centerTitle: true,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFE8EAF6), Color(0xFFC5CAE9)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Lottie.asset("assets/medical_loading.json", width: 100),
              Text("질문 ${(currentPage + 1)} / ${(allRiskFactors.length / 5).ceil()}",
                  style: const TextStyle(fontSize: 18)),
              const SizedBox(height: 10),
              ...currentBatch.map((risk) {
                final question = predefinedQuestions[risk] ?? "$risk 관련 위험 요인이 있으신가요?";
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(question, style: const TextStyle(fontSize: 16)),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: ["예", "아니오", "모르겠어요"].map((ans) {
                            return ChoiceChip(
                              label: Text(ans),
                              selected: userAnswers[risk] == ans,
                              onSelected: (_) {
                                setState(() => userAnswers[risk] = ans);
                              },
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _onConfirmBatch,
                child: const Text("확인", style: TextStyle(fontSize: 18, color: Colors.black)),
              ),
              const SizedBox(height: 10),
              LinearProgressIndicator(
                value: progress,
                color: Colors.deepPurple,
                backgroundColor: Colors.white,
                minHeight: 6,
              ),
              Text("진행도 ${(progress * 100).toStringAsFixed(1)}%"),
            ],
          ),
        ),
      ),
    );
  }
}
