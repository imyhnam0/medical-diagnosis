import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'refineddiseasepage.dart';
import 'finalthink.dart';

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
  bool isLoading = true;
  int currentPage = 0;

  List<String> allSocialFactors = [];
  Map<String, String> predefinedQuestions = {}; // ✅ 사회적 이력 → 질문 매핑
  Map<String, String?> userAnswers = {};

  Map<String, double> diseaseProbabilities = {};
  List<Map<String, dynamic>> candidateDiseases = [];

  @override
  void initState() {
    super.initState();
    _setPredefinedQuestions();
    _initializeSocialHistory();
  }

  /// ✅ 사회적 이력 → 질문 매핑
  void _setPredefinedQuestions() {
    predefinedQuestions = {
      "항암 치료 경험": "항암 치료를 받은 적이 있나요?",
      "여행력": "최근 여행한 적이 있나요?",
      "음주": "음주를 하시나요?",
      "흡연": "흡연을 하시나요?",
      "곰팡이 독소 노출": "곰팡이 독소에 노출된 적이 있나요?",
      "간염 위험 인자": "간염에 걸릴 위험 인자(예: 주사기, 혈액 접촉 등)가 있었나요?",
      "50세 이상": "연령이 50세 이상이신가요?",
      "여성": "여성이신가요?",
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
      "최근 질환": "최근에 질병을 앓은 적이 있나요?",
      "격한 운동": "격한 운동을 자주 하시나요?",
      "사고": "사고를 당한 적이 있나요?",
      "운동 습관": "운동 습관이 규칙적인가요?",
      "불량한 식습관": "불규칙하거나 불량한 식습관이 있으신가요?",
      "운동 부족": "운동량이 부족한 편인가요?",
      "고지방 식이": "고지방 음식을 자주 섭취하시나요?",
      "고지방 식습관": "고지방 식습관을 유지하고 있나요?",
      "코카인 사용": "코카인을 사용한 적이 있나요?",
      "좌식 생활": "주로 앉아서 생활하시나요?",
      "고령": "고령에 해당하시나요?",
      "면역저하": "면역이 약한 상태이신가요?",
      "바이오매스 노출": "바이오매스(나무 연기 등)에 노출된 적이 있나요?",
      "장기간 부동": "오랜 기간 움직이지 못한 적이 있나요?",
      "호르몬 요법": "호르몬 요법을 받은 적이 있나요?",
      "암 치료": "암 치료를 받은 적이 있나요?",
      "신경성 폭식증": "신경성 폭식증을 경험한 적이 있나요?",
      "회복 탄력성 부족": "스트레스 상황에서 회복이 잘 되지 않으신가요?",
      "가족 스트레스": "가족 문제로 스트레스를 받은 적이 있나요?",
      "신체활동 부족": "신체활동이 부족한 편인가요?",
      "운동선수 활동": "운동선수로 활동한 경험이 있나요?",
      "건강검진 미흡": "정기 건강검진을 받지 않고 계신가요?",
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
      "감염자 접촉": "감염자와 접촉한 적이 있나요?",
      "감염 노출": "감염 위험 환경에 노출된 적이 있나요?",
      "특별한 요인 없음": "특별한 사회적 요인은 없으신가요?",
      "야외 노동": "야외에서 일하시는 편인가요?",
      "수분 부족": "평소 수분 섭취가 부족한가요?",
      "전쟁 경험": "전쟁이나 유사한 극단적 상황을 경험하셨나요?",
      "학대": "학대를 경험한 적이 있나요?",
      "실직": "실직 경험이 있으신가요?",
      "사회적 고립": "사회적으로 고립된 상태이신가요?",
      "영양 불량": "영양 상태가 불량했던 적이 있나요?",
      "늦은 출산": "늦은 나이에 출산한 적이 있나요?",
      "심혈관 검진 부족": "심혈관 검진을 정기적으로 받지 않으시나요?",
      "부인과 병력": "부인과 질환 병력이 있으신가요?",
      "호르몬 치료": "호르몬 치료를 받은 적이 있나요?",
      "노숙": "노숙 경험이 있나요?",
      "알코올 중독": "알코올 중독 병력이 있나요?",
      "학대 경험": "학대를 경험한 적이 있나요?",
      "이차적 이득": "질병을 통해 이익을 얻은 적이 있나요?",
      "무거운 물건을 드는 직업": "무거운 물건을 자주 드는 직업에 종사하시나요?",
      "알레르겐 노출": "알레르겐(알레르기 유발 물질)에 노출된 적이 있나요?",
      "간접흡연": "간접흡연에 자주 노출되시나요?",
      "불법 약물 사용": "불법 약물을 사용한 적이 있나요?",
      "55세 이상": "연령이 55세 이상이신가요?",
      "가족력": "가족 중 유사한 질환을 가진 분이 있나요?",
      "풍토지역 거주": "풍토병이 있는 지역에 거주하신 적이 있나요?",
      "과밀한 생활": "과밀한 환경에서 생활하시나요?",
      "허약 상태": "허약하거나 체력이 약한 편인가요?",
      "식욕억제제": "식욕억제제를 복용한 적이 있나요?",
      "메탐페타민 사용": "메탐페타민을 사용한 적이 있나요?",
      "최근 여행": "최근 여행을 다녀오셨나요?",
      "장거리 여행": "장거리 여행을 다녀오신 적이 있나요?",
      "특별한 위험 요인 없음": "특별한 위험 요인은 없으신가요?",
      "앉아 있는 직업": "앉아서 일하는 직업이신가요?"
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

  /// ✅ 점수 업데이트
  void _updateScores(Map<String, String?> batchAnswers) {
    const double alpha = 1.25;
    const double decay = 0.9;

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
        if (answer == "예" && hasFactor) {
          score *= alpha;

        } else if (answer == "아니오" && !hasFactor) {
          score *= alpha;

        } else if (answer == "모르겠어요") {

          score *= 1.0;
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

  void _onConfirmBatch() {
    final currentBatch = _getCurrentBatch();
    final batchAnswers = {for (var f in currentBatch) f: userAnswers[f]};
    _updateScores(batchAnswers);

    // ✅ 이전 단계의 questionHistory + 현재 단계의 userAnswers 병합
    final updatedHistory = Map<String, String?>.from(widget.questionHistory)
      ..addAll(userAnswers);

    if ((currentPage + 1) * 5 >= allSocialFactors.length) {
      final sorted = diseaseProbabilities.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      // ✅ 상위 1개 (Top1) 질병만 추출
      final topDisease = sorted.first.key;

      print("\n🏁 모든 질문 완료! 최종 선택된 질병:");
      print("- $topDisease (${diseaseProbabilities[topDisease]!.toStringAsFixed(4)})");

      // ✅ RefinedDiseasePage로 단일 질병 전달
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => RefinedDiseasePage(
            predictedDisease: topDisease, // ✅ String 하나만 전달
            userInput: widget.userInput,
            selectedSymptoms: widget.selectedSymptoms,
            // ✅ questionHistory는 Map<String, String?> → List<Map<String, String>>로 변환
            questionHistory: updatedHistory.entries
                .map((e) => {"question": e.key, "answer": e.value ?? "응답 없음"})
                .toList(),
          ),
        ),
      );
    } else {
      setState(() => currentPage++);
    }
  }


  List<String> _getCurrentBatch() {
    final start = currentPage * 5;
    final end = (start + 5).clamp(0, allSocialFactors.length);
    return allSocialFactors.sublist(start, end);
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final currentBatch = _getCurrentBatch();
    final progress = ((currentPage * 5) + currentBatch.length) / allSocialFactors.length;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Social history", style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF1E3C72),
        centerTitle: true,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFFFF3E0), Color(0xFFFFE0B2)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Lottie.asset("assets/medical_loading.json", width: 100),
              Text("질문 ${(currentPage + 1)} / ${(allSocialFactors.length / 5).ceil()}",
                  style: const TextStyle(fontSize: 18)),
              const SizedBox(height: 10),
              ...currentBatch.map((factor) {
                final question = predefinedQuestions[factor] ?? "$factor 관련 생활습관이 있으신가요?";
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
                              selected: userAnswers[factor] == ans,
                              onSelected: (_) {
                                setState(() => userAnswers[factor] = ans);
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
                color: Colors.orange,
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
