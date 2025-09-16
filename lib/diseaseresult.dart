import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'RefinedDiseasePage.dart';

//주요 임상 특징 선택 페이지

class DiseaseResultPage extends StatefulWidget {
  final List<String> selectedSymptoms;

  const DiseaseResultPage({super.key, required this.selectedSymptoms});

  @override
  State<DiseaseResultPage> createState() => _DiseaseResultPageState();
}

class _DiseaseResultPageState extends State<DiseaseResultPage> {
  List<Map<String, dynamic>> diseases = [];
  final Set<String> selectedFeatures = {};

  // ✅ 카테고리 맵
  final Map<String, List<String>> featureCategories = {
    "심혈관 관련": [
      "흉통", "흉골 뒤 압박감", "방사통", "두근거림", "부정맥", "ST 분절 상승",
      "트로포닌 상승", "운동 시 흉통", "휴식 시 호전", "니트로글리세린 반응", "저혈압",
      "경정맥 팽창", "심음 감소", "빈맥", "수축기 심잡음", "BNP 상승"
    ],
    "호흡기 관련": [
      "호흡곤란", "기좌호흡", "체위성 호흡곤란", "저산소증", "객혈", "폐부종",
      "우심실 비대", "과공명음", "호흡음 감소", "기관 편위", "흉막성 흉통",
      "수포음", "천명음", "만성 기침"
    ],
    "소화기 관련": [
      "명치 통증", "오심", "구토", "흑색변", "식후 포만감", "조기 만복감",
      "속쓰림", "역류", "연하곤란", "연하통"
    ],
    "신경/근골격계": [
      "실신", "감각 이상", "근력 약화", "목 통증", "등 경직", "전신 통증",
      "국소 근육통", "압통점", "연관통", "운동 범위 제한", "작열감"
    ],
    "정신/심리": [
      "정서적 스트레스 관련 통증", "만성 걱정", "불면", "우울감", "무쾌감",
      "플래시백", "과각성"
    ],
    "피부/면역": [
      "발진", "나비 모양 발진", "일측성 작열통", "피부 분절 발진", "수포", "가려움"
    ],
    "여성 생식": [
      "연관 흉통 (부인과적)", "월경 불규칙", "성교통", "호르몬 관련 증상"
    ],
    "전신/기타": [
      "피로", "발열", "체중 감소", "전신 증상", "백혈구 증가", "간비대", "복부 팽만",
      "암 병력", "쇼크", "혼란", "고체온", "차가운 피부"
    ],
  };

  Map<String, List<String>> categorizedFeatures = {};

  @override
  void initState() {
    super.initState();
    fetchMatchingFeatures();
  }

  Future<void> fetchMatchingFeatures() async {
    final firestore = FirebaseFirestore.instance;
    final snapshot = await firestore.collection("diseases_ko").get();

    // ✅ 선택된 증상이 포함된 질환만 가져오기
    final matches = snapshot.docs.where((doc) {
      final data = doc.data();
      final diseaseSymptoms = List<String>.from(data["증상"] ?? []);
      return widget.selectedSymptoms.any((symptom) => diseaseSymptoms.contains(symptom));
    }).map((doc) => doc.data()).toList();


    // ✅ 그 질환들의 주요 임상 특징 모으기
    final features = matches
        .expand((d) => List<String>.from(d["주요 임상 특징"] ?? []))
        .toSet()
        .toList();

    // ✅ 카테고리별로 분류
    final categorized = <String, List<String>>{};
    for (var entry in featureCategories.entries) {
      categorized[entry.key] =
          features.where((f) => entry.value.contains(f)).toList();
    }

    setState(() {
      diseases = matches;
      categorizedFeatures = categorized;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (categorizedFeatures.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text("주요 임상 특징 선택")),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text("주요 임상 특징 선택")),
      body: ListView(
        children: categorizedFeatures.entries.map((entry) {
          if (entry.value.isEmpty) return const SizedBox.shrink();
          return ExpansionTile(
            title: Text(entry.key, style: const TextStyle(fontWeight: FontWeight.bold)),
            children: entry.value.map((feature) {
              return CheckboxListTile(
                title: Text(feature),
                value: selectedFeatures.contains(feature),
                onChanged: (checked) {
                  setState(() {
                    if (checked!) {
                      selectedFeatures.add(feature);
                    } else {
                      selectedFeatures.remove(feature);
                    }
                  });
                },
              );
            }).toList(),
          );
        }).toList(),
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.check),
        label: const Text("확인"),
        onPressed: () {
          // ✅ 선택된 특징을 포함하는 질환만 다시 필터링
          final refined = diseases.where((d) {
            final features = List<String>.from(d["주요 임상 특징"] ?? []);
            return selectedFeatures.any((f) => features.contains(f));
          }).toList();

          // ✅ "남은 질환"만 RefinedDiseasePage로 전달
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => RefinedDiseasePage(diseases: refined),
            ),
          );
        },
      ),

    );
  }
}
