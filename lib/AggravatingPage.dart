// import 'package:flutter/material.dart';
// import 'RiskFactorPage.dart';
// import 'DiseaseDataManager.dart';
// import 'package:http/http.dart' as http;
// import 'dart:convert';

// class AggravatingPage extends StatefulWidget {
//   final Map<String, dynamic>? personalInfo;
//   const AggravatingPage({super.key, this.personalInfo});

//   @override
//   State<AggravatingPage> createState() => _AggravatingPageState();
// }

// class _AggravatingPageState extends State<AggravatingPage> {
//   final TextEditingController _controller = TextEditingController();
//   bool _isLoading = false;


//   Future<void> _analyzeAndNext(String input) async {
//     if (input.trim().isEmpty) return;
//     setState(() => _isLoading = true);

//     try {
//       // ✅ Node.js 서버 호출
//       final response = await http.post(
//         Uri.parse("http://localhost:8080/api/analyze/aggravation"),
//         headers: {"Content-Type": "application/json"},
//         body: jsonEncode({"aggravateDiseaseInput": input}),
//       );

//       if (response.statusCode == 200) {
//         final data = jsonDecode(response.body);

//         final matched = List<String>.from(data["matchedKeywords"] ?? []);
//         final diseases = List<Map<String, dynamic>>.from(data["diseases"] ?? []);

//         // ✅ DiseaseDataManager에 저장
//         final manager = DiseaseDataManager();
      

//         setState(() => _isLoading = false);

//         // ✅ 다음 단계로 이동
//         if (context.mounted) {
//           Navigator.push(
//             context,
//             MaterialPageRoute(
//               builder: (_) => RiskFactorPage(personalInfo: widget.personalInfo),
//             ),
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
//       print("❌ 악화 요인 분석 중 오류: $e");
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
//         title: const Text("흉통 악화 요인"),
//         backgroundColor: primaryColor,
//         foregroundColor: Colors.white,
//         elevation: 0,
//       ),
//       body: Container
//       (
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
//                             child: const Icon(Icons.troubleshoot, color: Colors.white),
//                           ),
//                           const SizedBox(width: 12),
//                           const Expanded(
//                             child: Text(
//                               "어떤 상황에서 흉통이 더 심해지나요?",
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
//                         "예: 계단 오를 때, 깊게 숨쉴 때, 기침할 때, 식후, 스트레스 등",
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
//                             hintText: "예: 계단 오를 때 더 아파요, 깊게 숨쉬면 심해져요",
//                             hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
//                             prefixIcon: Icon(Icons.trending_up, color: primaryColor),
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

//                       const SizedBox(height: 12),





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
//                               : const Icon(Icons.auto_awesome),
//                           label: Text(
//                             _isLoading ? "분석 중..." : "AI로 분석 후 다음 단계",
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
