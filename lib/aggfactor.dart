import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'pasthistory.dart';

class AggfactorPage extends StatefulWidget {
  final List<String> selectedSymptoms;
  final String userInput;

  const AggfactorPage({
    super.key,
    required this.selectedSymptoms,
    required this.userInput,
  });

  @override
  State<AggfactorPage> createState() => _AggfactorPageState();
}

class _AggfactorPageState extends State<AggfactorPage> {
  bool isLoading = true;
  int currentPage = 0;

  List<String> allAggravatingFactors = [];
  Map<String, String> predefinedQuestions = {};
  Map<String, String?> userAnswers = {};

  Map<String, double> diseaseProbabilities = {};
  List<Map<String, dynamic>> candidateDiseases = [];

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

  void _updateScores(Map<String, String?> batchAnswers) {
    const double alpha = 1.25;
    const double decay = 0.9;


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

    if ((currentPage + 1) * 5 >= allAggravatingFactors.length) {
      final sorted = diseaseProbabilities.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      final cutoff = (sorted.length * 0.5).ceil();
      final topDiseases = sorted.take(cutoff).map((e) => e.key).toList();

      print("\n🏁 모든 질문 완료! 상위 질병 목록:");
      for (var dis in topDiseases) {
        print("- $dis (${diseaseProbabilities[dis]!.toStringAsFixed(4)})");
      }

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
            //사용자가 답한 질문들
            questionHistory: Map<String, String?>.from(userAnswers),
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
    final end = (start + 5).clamp(0, allAggravatingFactors.length);
    return allAggravatingFactors.sublist(start, end);
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final currentBatch = _getCurrentBatch();
    final progress = ((currentPage * 5) + currentBatch.length) / allAggravatingFactors.length;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Aggravating factor", style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF1E3C72),
        centerTitle: true,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFE3F2FD), Color(0xFFBBDEFB)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Lottie.asset("assets/medical_loading.json", width: 100),
              Text("질문 ${(currentPage + 1)} / ${(allAggravatingFactors.length / 5).ceil()}",
                  style: const TextStyle(fontSize: 18)),
              const SizedBox(height: 10),
              ...currentBatch.map((factor) {
                final question = predefinedQuestions[factor] ?? "$factor 시 증상이 악화되나요?";
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
                color: Colors.blue,
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
