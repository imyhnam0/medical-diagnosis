import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'symptom_select.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'yourdisease.dart';



void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

//전체 질병 데이터를 가져오는 함수
Future<void> fetchAllDiseases() async {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final CollectionReference diseasesCollection = firestore.collection('diseases_ko');

  try {
    QuerySnapshot snapshot = await diseasesCollection.get();

    for (var doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;

      String diseaseName = data['질환명'] ?? '이름 없음';
      List symptoms = data['증상'] ?? [];
      List pastHistory = data['과거 질환 이력'] ?? [];
      List socialHistory = data['사회적 이력'] ?? [];
      List aggravatingFactors = data['악화 요인'] ?? [];
      List riskFactors = data['위험 요인'] ?? [];
      List clinicalFeatures = data['주요 임상 특징'] ?? [];

      print('🩺 질환명: $diseaseName');
      print('   증상: ${symptoms.join(', ')}');
      print('   과거 질환 이력: ${pastHistory.join(', ')}');
      print('   사회적 이력: ${socialHistory.join(', ')}');
      print('   악화 요인: ${aggravatingFactors.join(', ')}');
      print('   위험 요인: ${riskFactors.join(', ')}');
      print('   주요 임상 특징: ${clinicalFeatures.join(', ')}');
      print('---------------------------------------');
    }
  } catch (e) {
    print('❌ Firestore 데이터 불러오기 오류: $e');
  }
}

//악화요인만 가져오는 함수
Future<void> fetchUniqueAggravatingFactors() async {
  final firestore = FirebaseFirestore.instance;
  final snapshot = await firestore.collection('diseases_ko').get();

  Set<String> uniqueFactors = {}; // 중복 제거용 Set

  for (var doc in snapshot.docs) {
    final data = doc.data() as Map<String, dynamic>;
    List<dynamic> aggravatingFactors = data['사회적 이력'] ?? [];

    // 리스트 안의 요소들을 Set에 추가 (자동으로 중복 제거)
    for (var factor in aggravatingFactors) {
      if (factor is String) uniqueFactors.add(factor.trim());
    }
  }

  print('🧩 중복 제거된 목록:');
  for (var factor in uniqueFactors) {
    print('- $factor');
  }

  print('총 ${uniqueFactors.length}개 항목');
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Medical Diagnosis App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Pretendard',
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueAccent),
        useMaterial3: true,
      ),
      home: const HomeBackground(),
    );
  }
}

class HomeBackground extends StatelessWidget {
  const HomeBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1E3C72), Color(0xFF2A5298)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 앱 아이콘
            CircleAvatar(
              radius: 60,
              backgroundColor: Colors.white.withOpacity(0.1),
              child: const Icon(
                Icons.health_and_safety,
                size: 80,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 30),

            // 앱 제목
            const Text(
              '의료 데이터 기반 진단 시스템',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 1.2,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),

            const Text(
              'Graduation Project',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white70,
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 60),

            // 시작 버튼
            ElevatedButton.icon(
              onPressed: () {
                //fetchAllDiseases(); // Firestore 데이터 불러오기 테스트
                //fetchUniqueAggravatingFactors();
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ConsentPage()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.blueAccent,
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(40),
                ),
                elevation: 6,
              ),
              icon: const Icon(Icons.play_arrow_rounded, size: 28),
              label: const Text(
                '시작하기',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ConsentPage extends StatelessWidget {
  const ConsentPage({super.key});

  void _showDiagnosisFlowDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text(
            "🩺 진단 절차 안내",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: const Text(
            "이 앱의 진단 과정은 다음과 같은 단계로 이루어집니다.\n\n"
                "1️⃣ 느끼는 통증을 입력합니다.\n"
                "2️⃣ 해당되는 증상을 선택합니다.\n"
                "3️⃣ 악화 요인에 대한 질문이 제시됩니다.\n"
                "4️⃣ 과거 질환 이력에 대한 질문이 제시됩니다.\n"
                "5️⃣ 위험 요인에 대한 질문이 제시됩니다.\n"
                "6️⃣ 마지막으로 사회적 이력에 대한 질문이 제시됩니다.\n\n"
                "⚠️ 이 결과는 참고용이며, 반드시 전문의와 상담을 병행하세요.",
            style: TextStyle(fontSize: 15, height: 1.5),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // 다이얼로그 닫기
              },
              child: const Text("취소"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E3C72),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () {
                Navigator.pop(context); // 다이얼로그 닫기
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SymptomSelectPage()),
                );
              },
              child: const Text("확인", style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text("동의 및 안내"),
        centerTitle: true,
        backgroundColor: const Color(0xFF1E3C72),
        foregroundColor: Colors.white,
        elevation: 4,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: const [
                    Icon(Icons.warning_amber_rounded, size: 60, color: Colors.redAccent),
                    SizedBox(height: 15),
                    Text(
                      "⚠️ 비의료 진단 고지",
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 15),
                    Text(
                      "이 앱은 결과가 정확하지 않을 수 있습니다.\n"
                          "정확한 진단과 치료를 위해 반드시 의사와 상담하세요.",
                      style: TextStyle(fontSize: 16, color: Colors.black87),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                    side: const BorderSide(color: Colors.grey),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  icon: const Icon(Icons.close, color: Colors.grey),
                  label: const Text("거부",
                      style: TextStyle(fontSize: 16, color: Colors.grey)),
                ),
                const SizedBox(width: 20),
                ElevatedButton.icon(
                  onPressed: () => _showDiagnosisFlowDialog(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: 4,
                  ),
                  icon: const Icon(Icons.check_circle_outline, color: Colors.white),
                  label: const Text(
                    "동의",
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

