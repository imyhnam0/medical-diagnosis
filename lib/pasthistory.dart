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



  const PastHistoryPage({
    super.key,
    required this.topDiseases,
    required this.selectedSymptoms,
    required this.userInput,
    required this.questionHistory,
    required this.diseaseProbabilities,
  });

  @override
  State<PastHistoryPage> createState() => _PastHistoryPageState();
}

class _PastHistoryPageState extends State<PastHistoryPage> {
  bool isLoading = true;
  int currentPage = 0;

  List<String> allHistories = [];
  Map<String, String> predefinedQuestions = {}; // ✅ 과거 이력 → 질문 매핑
  Map<String, String?> userAnswers = {};

  Map<String, double> diseaseProbabilities = {};
  List<Map<String, dynamic>> candidateDiseases = [];

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


    // ✅ 미리 정의된 질문이 있는 항목만 사용
    allHistories = allHistorySet.where((h) => predefinedQuestions.containsKey(h)).toList();
    print("🎯 실제 질문으로 사용할 항목 수: ${allHistories.length}");

    setState(() => isLoading = false);
  }

  /// ✅ 점수 업데이트
  void _updateScores(Map<String, String?> batchAnswers) {
    const double alpha = 1.25;
    const double decay = 0.9;

    print("\n🧩 [과거 질환 이력 반영 결과]");
    for (var d in candidateDiseases) {
      final name = d["질환명"];
      double prev = diseaseProbabilities[name]!;
      double score = prev;
      final histories = d["과거 질환 이력"] as List<String>;

      for (var entry in batchAnswers.entries) {
        final history = entry.key;
        final answer = entry.value;
        if (answer == null) continue;

        final hasHistory = histories.contains(history);
        if (answer == "예" && hasHistory) {
          score *= alpha;

        } else if (answer == "아니오" && !hasHistory) {
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
    final batchAnswers = {for (var h in currentBatch) h: userAnswers[h]};
    _updateScores(batchAnswers);

    // ✅ 이전 단계의 questionHistory + 현재 단계의 userAnswers 병합
    final updatedHistory = Map<String, String?>.from(widget.questionHistory)
      ..addAll(userAnswers);

    if ((currentPage + 1) * 5 >= allHistories.length) {
      final sorted = diseaseProbabilities.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      // ✅ 상위 50% 질병만 다음 단계로 전달
      final cutoff = (sorted.length * 0.4).ceil();
      final topDiseases = sorted.take(cutoff).map((e) => e.key).toList();

      print("\n🏁 모든 질문 완료! 상위 ${topDiseases.length}개 질병:");
      for (var dis in topDiseases) {
        print("- $dis (${diseaseProbabilities[dis]!.toStringAsFixed(4)})");
      }

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => RiskFactorPage(
            topDiseases: topDiseases, // ✅ 리스트 그대로 전달
            userInput: widget.userInput,
            selectedSymptoms: widget.selectedSymptoms,
            questionHistory: updatedHistory, // ✅ 병합된 질문기록 전달
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
    final end = (start + 5).clamp(0, allHistories.length);
    return allHistories.sublist(start, end);
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final currentBatch = _getCurrentBatch();
    final progress = ((currentPage * 5) + currentBatch.length) / allHistories.length;

    return Scaffold(
      appBar: AppBar(
        title: const Text("history of disorder", style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF1E3C72),
        centerTitle: true,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFE8F5E9), Color(0xFFC8E6C9)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Lottie.asset("assets/medical_loading.json", width: 100),
              Text("질문 ${(currentPage + 1)} / ${(allHistories.length / 5).ceil()}",
                  style: const TextStyle(fontSize: 18)),
              const SizedBox(height: 10),
              ...currentBatch.map((history) {
                final question = predefinedQuestions[history] ?? "$history 병력이 있으신가요?";
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
                              selected: userAnswers[history] == ans,
                              onSelected: (_) {
                                setState(() => userAnswers[history] = ans);
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
                color: Colors.green,
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
