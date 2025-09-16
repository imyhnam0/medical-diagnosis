import 'package:flutter/material.dart';
import 'diseaseresult.dart';

class YourDiseasePage extends StatefulWidget {
  const YourDiseasePage({super.key});

  @override
  State<YourDiseasePage> createState() => _YourDiseasePageState();
}

class _YourDiseasePageState extends State<YourDiseasePage> {
  final Map<String, List<String>> symptomCategories = {
    "흉부 관련 증상": [
      "흉통", "흉부 불편감", "흉부 압박감", "흉부 조임/답답함",
      "방사통", "국소 흉벽 통증", "흉벽 압통", "멍/타박상"
    ],
    "호흡기 증상": [
      "호흡곤란", "운동 시 호흡곤란", "야간 호흡곤란", "흉부 압박과 호흡곤란 동반",
      "기침", "가래", "객혈", "발열", "오한/밤에 식은땀", "호흡 시 악화되는 통증"
    ],
    "심혈관/전신 증상": [
      "발한", "두근거림", "가슴 두근거림과 어지럼증 동반", "실신",
      "어지럼증", "피로", "전신 쇠약감", "하지 부종", "전신 쇠약과 피로"
    ],
    "소화기 증상": [
      "구역/구토", "상복부 통증", "상복부 불편감", "소화불량/더부룩함",
      "위산 역류/속쓰림", "트림/역류", "상복부 덩어리감", "복부 팽만감",
      "설사", "변비"
    ],
    "신경/근골격계 증상": [
      "근육통", "뻣뻣함", "국소 근육 운동 제한", "전신 통증",
      "팔 저림/무감각", "등 통증", "목 통증", "관절통",
      "운동 시 악화되는 통증", "신경병성 통증"
    ],
    "피부/감각 증상": [
      "피부 발진", "화끈거림/작열감", "가려움/따가움"
    ],
    "신경/인지 기능 증상": [
      "두통", "시야 이상", "청력 이상", "기억력 저하/집중력 저하"
    ],
    "정신/심리 증상": [
      "불면", "수면 장애", "불안/걱정", "우울감",
      "공황 발작", "플래시백"
    ],
    "여성 생식 관련 증상": [
      "여성 생리 관련 증상"
    ],
  };

  final Set<String> selectedSymptoms = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("증상 선택"),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF1E3C72), Color(0xFF2A5298)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: symptomCategories.entries.map((entry) {
          return Card(
            elevation: 3,
            margin: const EdgeInsets.symmetric(vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: ExpansionTile(
              title: Text(
                entry.key,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              children: entry.value.map((symptom) {
                return CheckboxListTile(
                  title: Text(
                    symptom,
                    style: const TextStyle(fontSize: 16),
                  ),
                  activeColor: Colors.blueAccent,
                  value: selectedSymptoms.contains(symptom),
                  onChanged: (checked) {
                    setState(() {
                      if (checked!) {
                        selectedSymptoms.add(symptom);
                      } else {
                        selectedSymptoms.remove(symptom);
                      }
                    });
                  },
                );
              }).toList(),
            ),
          );
        }).toList(),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton.icon(
            onPressed: selectedSymptoms.isEmpty
                ? null
                : () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => DiseaseResultPage(
                    selectedSymptoms: selectedSymptoms.toList(),
                  ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueAccent,
              disabledBackgroundColor: Colors.grey[300],
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              elevation: 4,
            ),
            icon: const Icon(Icons.check, color: Colors.white),
            label: const Text(
              "확인",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ),
        ),
      ),
    );
  }
}
