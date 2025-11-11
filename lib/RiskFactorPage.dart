// import 'package:flutter/material.dart';
// import 'DiseaseDataManager.dart';
// import 'ResultPage.dart';
// import 'package:http/http.dart' as http;
// import 'dart:convert';

// class RiskFactorPage extends StatefulWidget {
//   final Map<String, dynamic>? personalInfo;
//   const RiskFactorPage({super.key, this.personalInfo});

//   @override
//   State<RiskFactorPage> createState() => _RiskFactorPageState();
// }

// class _RiskFactorPageState extends State<RiskFactorPage> {
//   final TextEditingController _controller = TextEditingController();
//   bool _isLoading = false;



//   Future<void> _analyzeAndNext(String input) async {
//     if (input.trim().isEmpty) return;
//     setState(() => _isLoading = true);

//     try {
//       // ✅ Node.js 서버 호출
//       final response = await http.post(
//         Uri.parse("http://localhost:8080/api/analyze/riskfactor"),
//         headers: {"Content-Type": "application/json"},
//         body: jsonEncode({"riskFactorInput": input}),
//       );

//       if (response.statusCode == 200) {
//         final data = jsonDecode(response.body);

//         // 🔹 서버 응답 구조: { matchedKeywords: [...], diseases: [...] }
//         final matched = List<String>.from(data["matchedKeywords"] ?? []);
//         final diseases = List<Map<String, dynamic>>.from(data["diseases"] ?? []);


//         // ✅ DiseaseDataManager에 저장
//         final manager = DiseaseDataManager();
//         manager.setRiskFactorKeywords(matched);
//         manager.setRiskFactorDiseases(diseases);
//         manager.printAllData(
//           includeSymptoms: false,
//           includePastHistory: false,
//           includeSocialHistory: false,
//           includeAggravatingFactors: false,
//           includeRiskFactors: true,
//         );

//         setState(() => _isLoading = false);

//         // ✅ 결과 페이지로 이동
//         if (context.mounted) {
//           Navigator.push(
//             context,
//             MaterialPageRoute(builder: (context) => const ResultPage()),
//           );
//         }
//       } else {
//         print("⚠️ 서버 오류: ${response.statusCode}");
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text("서버 오류가 발생했습니다 (${response.statusCode})"),
//             backgroundColor: Colors.redAccent,
//           ),
//         );
//         setState(() => _isLoading = false);
//       }
//     } catch (e) {
//       print("❌ 위험 요인 분석 중 오류: $e");
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text("서버 연결 오류: $e"),
//           backgroundColor: Colors.redAccent,
//         ),
//       );
//       setState(() => _isLoading = false);
//     }
//   }


//   @override
//   Widget build(BuildContext context) {
//     final primaryColor = const Color(0xFF0F4C75);
//     final secondaryColor = const Color(0xFF3282B8);
//     final accentColor = const Color(0xFFBBE1FA);

//     return Scaffold(
//       appBar: AppBar(
//         title: const Text("현재 질병 및 위험 요인"),
//         backgroundColor: primaryColor,
//         foregroundColor: Colors.white,
//         elevation: 0,
//       ),
//       body: Container(
//         width: double.infinity,
//         height: double.infinity,
//         decoration: BoxDecoration(
//           gradient: LinearGradient(
//             colors: [primaryColor, secondaryColor, accentColor],
//             begin: Alignment.topLeft,
//             end: Alignment.bottomRight,
//             stops: const [0.0, 0.55, 1.0],
//           ),
//         ),
//         child: SafeArea(
//           child: SingleChildScrollView(
//             padding: const EdgeInsets.all(16),
//             physics: const BouncingScrollPhysics(),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Container(
//                   width: double.infinity,
//                   padding: const EdgeInsets.all(20),
//                   decoration: BoxDecoration(
//                     color: Colors.white,
//                     borderRadius: BorderRadius.circular(20),
//                     boxShadow: [
//                       BoxShadow(
//                         color: Colors.black.withOpacity(0.12),
//                         blurRadius: 18,
//                         offset: const Offset(0, 8),
//                       ),
//                     ],
//                   ),
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Row(
//                         children: [
//                           Container(
//                             width: 44,
//                             height: 44,
//                             decoration: BoxDecoration(
//                               gradient: LinearGradient(
//                                 colors: [primaryColor, secondaryColor],
//                                 begin: Alignment.topLeft,
//                                 end: Alignment.bottomRight,
//                               ),
//                               borderRadius: BorderRadius.circular(12),
//                             ),
//                             child: const Icon(Icons.health_and_safety, color: Colors.white),
//                           ),
//                           const SizedBox(width: 12),
//                           const Expanded(
//                             child: Text(
//                               "현재 어떤 병을 앓고 있나요?",
//                               style: TextStyle(
//                                 fontSize: 18,
//                                 fontWeight: FontWeight.w700,
//                                 color: Color(0xFF1A202C),
//                               ),
//                             ),
//                           ),
//                         ],
//                       ),

//                       const SizedBox(height: 16),

//                       Text(
//                         "예: 당뇨, 고혈압, 천식, 우울증, 흡연, 음주, 비만, 가족력 등",
//                         style: TextStyle(
//                           fontSize: 13,
//                           color: Colors.grey[600],
//                         ),
//                       ),

//                       const SizedBox(height: 12),

//                       Container(
//                         decoration: BoxDecoration(
//                           color: Colors.grey[50],
//                           borderRadius: BorderRadius.circular(16),
//                           border: Border.all(color: primaryColor.withOpacity(0.15)),
//                         ),
//                         child: TextField(
//                           controller: _controller,
//                           maxLines: 3,
//                           decoration: InputDecoration(
//                             hintText: "예: 당뇨, 고혈압, 천식, 우울증 등 현재 앓고 있는 질병을 입력하세요",
//                             hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
//                             prefixIcon: Icon(Icons.medical_services, color: primaryColor),
//                             border: OutlineInputBorder(
//                               borderRadius: BorderRadius.circular(16),
//                               borderSide: BorderSide.none,
//                             ),
//                             filled: true,
//                             fillColor: Colors.transparent,
//                             contentPadding: const EdgeInsets.all(16),
//                           ),
//                         ),
//                       ),

                      

//                       const SizedBox(height: 20),

//                       SizedBox(
//                         width: double.infinity,
//                         height: 52,
//                         child: ElevatedButton.icon(
//                           style: ElevatedButton.styleFrom(
//                             backgroundColor: primaryColor,
//                             foregroundColor: Colors.white,
//                             elevation: 2,
//                             shape: RoundedRectangleBorder(
//                               borderRadius: BorderRadius.circular(14),
//                             ),
//                           ),
//                           onPressed: _isLoading
//                               ? null
//                               : () => _analyzeAndNext(_controller.text),
//                           icon: _isLoading
//                               ? const SizedBox(
//                                   width: 22,
//                                   height: 22,
//                                   child: CircularProgressIndicator(
//                                     strokeWidth: 2.5,
//                                     color: Colors.white,
//                                   ),
//                                 )
//                               : const Icon(Icons.analytics),
//                           label: Text(
//                             _isLoading ? "분석 중..." : "AI로 분석 후 결과 보기",
//                             style: const TextStyle(
//                               fontSize: 16,
//                               fontWeight: FontWeight.w700,
//                             ),
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }
