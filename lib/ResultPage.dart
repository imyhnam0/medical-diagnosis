// import 'package:flutter/material.dart';
// import 'dart:convert';
// import 'package:http/http.dart' as http;
// import 'DiseaseDataManager.dart';
// import 'main.dart';

// class DiseaseInfo {
//   final String description;
//   final String prognosis;
  

//   DiseaseInfo({
//     required this.description,
//     required this.prognosis,
    
//   });
// }

// class ResultPage extends StatefulWidget {
//   const ResultPage({super.key});

//   @override
//   State<ResultPage> createState() => _ResultPageState();
// }

// class _ResultPageState extends State<ResultPage> {
//   final DiseaseDataManager _diseaseManager = DiseaseDataManager();
//   final Map<String, double> _diseaseScores = {};
//   List<MapEntry<String, double>> _topDiseases = [];
//   final Map<String, DiseaseInfo> _diseaseInfo = {};
//   bool _isLoadingInfo = false;

//   @override
//   void initState() {
//     super.initState();
//     _calculateDiseaseScores();
//     _loadDiseaseInfo();
//   }

//   /// AI로 질병 정보 가져오기
//   Future<void> _loadDiseaseInfo() async {
//     if (_topDiseases.isEmpty) return;
    
//     setState(() => _isLoadingInfo = true);
    
//     for (var disease in _topDiseases) {
//       if (!_diseaseInfo.containsKey(disease.key)) {
//         try {
//           final info = await _getDiseaseInfoFromAI(disease.key);
//           _diseaseInfo[disease.key] = info;
//         } catch (e) {
//           print("❌ 질병 정보 로딩 실패: ${disease.key} - $e");
//         }
//       }
//     }
    
//     setState(() => _isLoadingInfo = false);
//   }

//   Future<DiseaseInfo> _getDiseaseInfoFromAI(String diseaseName) async {
//     try {
//       final response = await http.post(
//         Uri.parse("http://localhost:8080/api/analyze/disease-info"),
//         headers: {"Content-Type": "application/json"},
//         body: jsonEncode({"diseaseName": diseaseName}),
//       );

//       if (response.statusCode == 200) {
//         final data = jsonDecode(response.body);

//         return DiseaseInfo(
//           description: data["description"] ?? "정보를 가져올 수 없습니다.",
//           prognosis: data["prognosis"] ?? "예후 정보를 가져올 수 없습니다.",
//         );
//       } else {
//         print("⚠️ 서버 오류: ${response.statusCode}");
//         return DiseaseInfo(
//           description: "정보를 가져올 수 없습니다.",
//           prognosis: "예후 정보를 가져올 수 없습니다.",
//         );
//       }
//     } catch (e) {
//       print("❌ 서버 연결 실패: $e");
//       return DiseaseInfo(
//         description: "정보를 가져올 수 없습니다.",
//         prognosis: "예후 정보를 가져올 수 없습니다.",
//       );
//     }
//   }

//   /// 🔹 카테고리별 질병 리스트 출력 함수
//   void _printDiseaseCategory(String category, List<Map<String, dynamic>> diseases) {
//     if (diseases.isEmpty) {
//       print("⚠️ [$category] 관련 질병 없음");
//       return;
//     }

//     final diseaseNames = diseases.map((d) => d['질환명'] ?? '알 수 없는 질병').toList();
//     print("🩺 [$category] (${diseaseNames.length}개): ${diseaseNames.join(', ')}");
//   }

//   void _calculateDiseaseScores() {
//     _diseaseScores.clear();
//     _diseaseScores.addAll(_diseaseManager.diseaseScoreTotals);
    
//     // 각 카테고리별로 질병에 점수 부여
//     _printDiseaseCategory("증상", _diseaseManager.symptomDiseases);
//     _addDiseasesToScore(_diseaseManager.symptomDiseases, '증상');
//     _printDiseaseCategory("과거 질환 이력", _diseaseManager.pastDiseases);
//     _addDiseasesToScore(_diseaseManager.pastDiseases, "과거 질환 이력");
//     _printDiseaseCategory("사회적 이력", _diseaseManager.socialDiseases);
//     _addDiseasesToScore(_diseaseManager.socialDiseases, "사회적 이력");
//     _printDiseaseCategory("악화 요인", _diseaseManager.aggravatingDiseases);
//     _addDiseasesToScore(_diseaseManager.aggravatingDiseases, "악화 요인");
//     _printDiseaseCategory("위험 요인", _diseaseManager.riskFactorDiseases);
//     _addDiseasesToScore(_diseaseManager.riskFactorDiseases, "위험 요인");
    
//     // 상위 2개 질병 찾기
//     if (_diseaseScores.isNotEmpty) {
//       var sortedEntries = _diseaseScores.entries.toList()
//         ..sort((a, b) => b.value.compareTo(a.value));
      
//       _topDiseases = sortedEntries.take(2).toList();
//       print("🏆 상위 질병 TOP 2:");
//       for (var i = 0; i < _topDiseases.length; i++) {
//         print("  ${i + 1}위 ${_topDiseases[i].key} - ${_topDiseases[i].value}점");
//       }
//     }
    
//     setState(() {});
//   }

//   void _addDiseasesToScore(List<Map<String, dynamic>> diseases, String category) {
//     // 카테고리별 가중치 설정
//     double weight;
//     switch (category) {
//       case '증상':
//         weight = 1.0;
//         break;
//       case '악화 요인':
//         weight = 0.6;
//         break;
//       case '과거 질환 이력':
//         weight = 0.5;
//         break;
//       case '위험 요인':
//         weight = 0.4;
//         break;
//       case '사회적 이력':
//         weight = 0.2;
//         break;
//       default:
//         weight = 1.0;
//     }

//     // 각 질병에 가중치 점수를 더함
//     for (var disease in diseases) {
//       String diseaseName = disease['질환명'] ?? '알 수 없는 질병';
//       _diseaseScores[diseaseName] =
//           (_diseaseScores[diseaseName] ?? 0) + weight;
//     }
//   }


//   void _goToMain() {
//     // 전역변수 초기화
//     _diseaseManager.initializeNewDiagnosis();
    
//     // main 페이지로 이동 (모든 페이지를 스택에서 제거)
//     Navigator.pushAndRemoveUntil(
//       context,
//       MaterialPageRoute(builder: (context) => const MyApp()),
//       (route) => false,
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     final primaryColor = const Color(0xFF0F4C75);
//     final secondaryColor = const Color(0xFF3282B8);
//     final accentColor = const Color(0xFFBBE1FA);
    
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text(
//           '진단 결과',
//           style: TextStyle(
//             fontWeight: FontWeight.bold,
//             color: Colors.white,
//           ),
//         ),
//         backgroundColor: primaryColor,
//         elevation: 0,
//         centerTitle: true,
//       ),
//       body: Container(
//         decoration: BoxDecoration(
//           gradient: LinearGradient(
//             begin: Alignment.topLeft,
//             end: Alignment.bottomRight,
//             colors: [primaryColor, secondaryColor, accentColor],
//             stops: const [0.0, 0.55, 1.0],
//           ),
//         ),
//         child: SafeArea(
//           child: _diseaseScores.isEmpty
//               ? _buildEmptyState()
//               : _buildResultContent(),
//         ),
//       ),
//       floatingActionButton: FloatingActionButton.extended(
//         onPressed: _goToMain,
//         backgroundColor: primaryColor,
//         foregroundColor: Colors.white,
//         icon: const Icon(Icons.home),
//         label: const Text(
//           '처음으로',
//           style: TextStyle(fontWeight: FontWeight.w600),
//         ),
//       ),
//     );
//   }

//   Widget _buildEmptyState() {
//     return Center(
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           Icon(
//             Icons.medical_information_outlined,
//             size: 100,
//             color: Colors.grey[400],
//           ),
//           const SizedBox(height: 20),
//           Text(
//             '진단 데이터가 없습니다',
//             style: TextStyle(
//               fontSize: 24,
//               fontWeight: FontWeight.bold,
//               color: Colors.grey[600],
//             ),
//           ),
//           const SizedBox(height: 10),
//           Text(
//             '다른 페이지에서 질병 정보를 입력해주세요',
//             style: TextStyle(
//               fontSize: 16,
//               color: Colors.grey[500],
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildResultContent() {
//     return SingleChildScrollView(
//       padding: const EdgeInsets.all(20),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           _buildTopDiseaseCard(),

//           const SizedBox(height: 30),
//           _buildAllDiseasesList(),
//         ],
//       ),
//     );
//   }

//   Widget _buildTopDiseaseCard() {
//     final primaryColor = const Color(0xFF0F4C75);
//     final secondaryColor = const Color(0xFF3282B8);
    
//     return Container(
//       width: double.infinity,
//       padding: const EdgeInsets.all(24),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(20),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.12),
//             blurRadius: 18,
//             offset: const Offset(0, 8),
//           ),
//         ],
//       ),
//       child: Column(
//         children: [
//           Row(
//             children: [
//               Container(
//                 width: 50,
//                 height: 50,
//                 decoration: BoxDecoration(
//                   gradient: LinearGradient(
//                     colors: [primaryColor, secondaryColor],
//                     begin: Alignment.topLeft,
//                     end: Alignment.bottomRight,
//                   ),
//                   borderRadius: BorderRadius.circular(12),
//                 ),
//                 child: const Icon(
//                   Icons.emoji_events,
//                   color: Colors.white,
//                   size: 28,
//                 ),
//               ),
//               const SizedBox(width: 16),
//               Expanded(
//                 child: Text(
//                   '진단 결과 TOP 2',
//                   style: TextStyle(
//                     fontSize: 20,
//                     fontWeight: FontWeight.bold,
//                     color: primaryColor,
//                   ),
//                 ),
//               ),
//             ],
//           ),
//           const SizedBox(height: 24),
          
//           // 1위 질병
//           if (_topDiseases.isNotEmpty) _buildDiseaseRankCard(_topDiseases[0], 1),
          
//           if (_topDiseases.length > 1) ...[
//             const SizedBox(height: 16),
//             _buildDiseaseRankCard(_topDiseases[1], 2),
//           ],
//         ],
//       ),
//     );
//   }

//   Widget _buildDiseaseRankCard(MapEntry<String, double> disease, int rank) {
//     final isFirst = rank == 1;
//     final primaryColor = const Color(0xFF0F4C75);
//     final secondaryColor = const Color(0xFF3282B8);
//     final rankColor = isFirst ? primaryColor : secondaryColor;
//     final rankIcon = isFirst ? Icons.emoji_events : Icons.star;
//     final diseaseInfo = _diseaseInfo[disease.key];
    
//     return LayoutBuilder(
//       builder: (context, constraints) {
//         final isCompact = constraints.maxWidth < 360;

//         Widget buildCompactHeader() {
//           return Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Row(
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   Container(
//                     width: 36,
//                     height: 36,
//                     decoration: BoxDecoration(
//                       color: rankColor,
//                       shape: BoxShape.circle,
//                     ),
//                     child: Center(
//                       child: Text(
//                         '$rank',
//                         style: const TextStyle(
//                           color: Colors.white,
//                           fontSize: 16,
//                           fontWeight: FontWeight.bold,
//                         ),
//                       ),
//                     ),
//                   ),
//                   const SizedBox(width: 12),
//                   Icon(
//                     rankIcon,
//                     color: rankColor,
//                     size: 24,
//                   ),
//                 ],
//               ),
//               const SizedBox(height: 12),
//               Text(
//                 disease.key,
//                 style: TextStyle(
//                   fontSize: isFirst ? 19 : 17,
//                   fontWeight: FontWeight.bold,
//                   color: isFirst ? rankColor : Colors.black87,
//                 ),
//               ),
//               const SizedBox(height: 6),
//               Text(
//                 '${disease.value.toStringAsFixed(1)}점',
//                 style: TextStyle(
//                   fontSize: 13,
//                   fontWeight: FontWeight.w600,
//                   color: Colors.grey[600],
//                 ),
//               ),
//             ],
//           );
//         }

//         Widget buildWideHeader() {
//           return Row(
//             children: [
//               Container(
//                 width: 40,
//                 height: 40,
//                 decoration: BoxDecoration(
//                   color: rankColor,
//                   shape: BoxShape.circle,
//                 ),
//                 child: Center(
//                   child: Text(
//                     '$rank',
//                     style: const TextStyle(
//                       color: Colors.white,
//                       fontSize: 18,
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                 ),
//               ),
//               const SizedBox(width: 16),
//               Expanded(
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(
//                       disease.key,
//                       style: TextStyle(
//                         fontSize: isFirst ? 20 : 18,
//                         fontWeight: FontWeight.bold,
//                         color: isFirst ? rankColor : Colors.black87,
//                       ),
//                     ),
//                     const SizedBox(height: 4),
//                     Text(
//                       '${disease.value.toStringAsFixed(1)}점',
//                       style: TextStyle(
//                         fontSize: 14,
//                         fontWeight: FontWeight.w600,
//                         color: Colors.grey[600],
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//               Icon(
//                 rankIcon,
//                 color: rankColor,
//                 size: 28,
//               ),
//             ],
//           );
//         }

//         return Container(
//           margin: const EdgeInsets.only(bottom: 16),
//           padding: const EdgeInsets.all(20),
//           decoration: BoxDecoration(
//             color: isFirst 
//                 ? rankColor.withOpacity(0.05)
//                 : Colors.grey[50],
//             borderRadius: BorderRadius.circular(16),
//             border: Border.all(
//               color: isFirst 
//                   ? rankColor.withOpacity(0.3)
//                   : Colors.grey[300]!,
//               width: isFirst ? 2 : 1,
//             ),
//           ),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               isCompact ? buildCompactHeader() : buildWideHeader(),
              
//               if (diseaseInfo != null) ...[
//                 const SizedBox(height: 16),
//                 _buildDiseaseInfoSection(diseaseInfo, rankColor),
//               ] else if (_isLoadingInfo) ...[
//                 const SizedBox(height: 16),
//                 _buildLoadingInfo(),
//               ],
//             ],
//           ),
//         );
//       },
//     );
//   }

//   Widget _buildDiseaseInfoSection(DiseaseInfo info, Color accentColor) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         // 질병 설명
//         _buildInfoCard(
//           icon: Icons.info_outline,
//           title: "질병 설명",
//           content: info.description,
//           color: accentColor,
//         ),
        
//         const SizedBox(height: 12),
        
//         // 예후
//         _buildInfoCard(
//           icon: Icons.trending_up,
//           title: "예후 및 주의사항",
//           content: info.prognosis,
//           color: accentColor,
//         ),
        
      
//       ],
//     );
//   }

//   Widget _buildInfoCard({
//     required IconData icon,
//     required String title,
//     required String content,
//     required Color color,
//   }) {
//     return Container(
//       padding: const EdgeInsets.all(12),
//       decoration: BoxDecoration(
//         color: color.withOpacity(0.05),
//         borderRadius: BorderRadius.circular(12),
//         border: Border.all(
//           color: color.withOpacity(0.2),
//           width: 1,
//         ),
//       ),
//       child: Row(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Icon(
//             icon,
//             color: color,
//             size: 18,
//           ),
//           const SizedBox(width: 8),
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   title,
//                   style: TextStyle(
//                     fontSize: 14,
//                     fontWeight: FontWeight.w600,
//                     color: color,
//                   ),
//                 ),
//                 const SizedBox(height: 4),
//                 Text(
//                   content,
//                   style: const TextStyle(
//                     fontSize: 13,
//                     color: Colors.black87,
//                     height: 1.4,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildLoadingInfo() {
//     return Container(
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: Colors.grey[100],
//         borderRadius: BorderRadius.circular(12),
//       ),
//       child: Row(
//         children: [
//           SizedBox(
//             width: 16,
//             height: 16,
//             child: CircularProgressIndicator(
//               strokeWidth: 2,
//               color: Colors.grey[600],
//             ),
//           ),
//           const SizedBox(width: 12),
//           Text(
//             "AI가 질병 정보를 분석하고 있습니다...",
//             style: TextStyle(
//               fontSize: 13,
//               color: Colors.grey[600],
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildAllDiseasesList() {
//     final primaryColor = const Color(0xFF0F4C75);
//     var sortedDiseases = _diseaseScores.entries.toList()
//       ..sort((a, b) => b.value.compareTo(a.value));

//     // 상위 2개를 제외한 나머지 질병들
//     var otherDiseases = sortedDiseases.skip(2).take(5).toList();


//     if (otherDiseases.isEmpty) {
//       return const SizedBox.shrink();
//     }

//     return Container(
//       padding: const EdgeInsets.all(20),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(20),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.12),
//             blurRadius: 18,
//             offset: const Offset(0, 8),
//           ),
//         ],
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(
//             children: [
//               Container(
//                 width: 40,
//                 height: 40,
//                 decoration: BoxDecoration(
//                   color: primaryColor,
//                   borderRadius: BorderRadius.circular(10),
//                 ),
//                 child: const Icon(
//                   Icons.list_alt,
//                   color: Colors.white,
//                   size: 20,
//                 ),
//               ),
//               const SizedBox(width: 12),
//               Text(
//                 '기타 질병',
//                 style: TextStyle(
//                   fontSize: 20,
//                   fontWeight: FontWeight.bold,
//                   color: primaryColor,
//                 ),
//               ),
//             ],
//           ),
//           const SizedBox(height: 16),
//           ...otherDiseases.map((entry) => _buildDiseaseItem(entry.key, entry.value)),
//         ],
//       ),
//     );
//   }

//   Widget _buildDiseaseItem(String diseaseName, double score) {
//     final primaryColor = const Color(0xFF0F4C75);
    
//     return LayoutBuilder(
//       builder: (context, constraints) {
//         final isCompact = constraints.maxWidth < 340;

//         return Container(
//           margin: const EdgeInsets.only(bottom: 8),
//           padding: const EdgeInsets.all(16),
//           decoration: BoxDecoration(
//             color: const Color(0xFFF0F8FF),
//             borderRadius: BorderRadius.circular(12),
//             border: Border.all(color: primaryColor.withOpacity(0.1), width: 1),
//           ),
//           child: isCompact
//               ? Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(
//                       diseaseName,
//                       style: const TextStyle(
//                         fontSize: 15,
//                         fontWeight: FontWeight.w500,
//                         color: Colors.black87,
//                       ),
//                     ),
//                     const SizedBox(height: 10),
//                     Align(
//                       alignment: Alignment.centerLeft,
//                       child: Container(
//                         padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
//                         decoration: BoxDecoration(
//                           color: primaryColor.withOpacity(0.12),
//                           borderRadius: BorderRadius.circular(14),
//                         ),
//                         child: Text(
//                           '${score.toStringAsFixed(1)}점',
//                           style: TextStyle(
//                             fontSize: 13,
//                             fontWeight: FontWeight.bold,
//                             color: primaryColor,
//                           ),
//                         ),
//                       ),
//                     ),
//                   ],
//                 )
//               : Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                   children: [
//                     Expanded(
//                       child: Text(
//                         diseaseName,
//                         style: const TextStyle(
//                           fontSize: 16,
//                           fontWeight: FontWeight.w500,
//                           color: Colors.black87,
//                         ),
//                       ),
//                     ),
//                     Container(
//                       padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
//                       decoration: BoxDecoration(
//                         color: primaryColor.withOpacity(0.1),
//                         borderRadius: BorderRadius.circular(16),
//                       ),
//                       child: Text(
//                         '${score.toStringAsFixed(1)}점',
//                         style: TextStyle(
//                           fontSize: 14,
//                           fontWeight: FontWeight.bold,
//                           color: primaryColor,
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//         );
//       },
//     );
//   }
// }
