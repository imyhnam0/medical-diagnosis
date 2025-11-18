import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'main.dart';

class DiseaseInfo {
  final String description;
  final String prognosis;
  

  DiseaseInfo({
    required this.description,
    required this.prognosis,
    
  });
}

class ResultPage extends StatefulWidget {
  const ResultPage({super.key});

  @override
  State<ResultPage> createState() => _ResultPageState();
}

class _ResultPageState extends State<ResultPage> {
 
  final Map<String, double> _diseaseScores = {};
  List<MapEntry<String, double>> _topDiseases = [];
  final Map<String, DiseaseInfo> _diseaseInfo = {};
  bool _isLoadingInfo = false;

  @override
  void initState() {
    super.initState();
    _calculateDiseaseScores();
  }

  /// 백엔드에서 상위 질병 2개를 받아오고, 각 질병 정보 로드
  Future<void> _calculateDiseaseScores() async {
    try {
      // 상위 2개
      final respTop = await http.get(Uri.parse('http://98.91.66.27:8080/api/analyze/top-diseases'));
      // 전체 질병 점수
      final respAll = await http.get(Uri.parse('http://98.91.66.27:8080/api/analyze/all-diseases'));

      if (respTop.statusCode == 200) {
        final dataTop = jsonDecode(respTop.body);
        final List<dynamic> top = dataTop['top'] ?? [];
        final List<MapEntry<String, double>> topEntries = top
            .map((e) => MapEntry<String, double>(
                  (e['diseaseName'] ?? '').toString(),
                  (e['score'] is num) ? (e['score'] as num).toDouble() : 0.0,
                ))
            .where((e) => e.key.isNotEmpty)
            .toList();
        setState(() {
          _topDiseases = topEntries;
        });
      } else {
        print('⚠️ top-diseases 호출 실패: ${respTop.statusCode} ${respTop.body}');
        setState(() {
          _topDiseases = [];
        });
      }

      if (respAll.statusCode == 200) {
        final dataAll = jsonDecode(respAll.body);
        final List<dynamic> all = dataAll['all'] ?? [];
        final Map<String, double> allScores = {};
        for (final item in all) {
          final name = (item['diseaseName'] ?? '').toString();
          final score = (item['score'] is num) ? (item['score'] as num).toDouble() : 0.0;
          if (name.isNotEmpty) {
            allScores[name] = score;
          }
        }
        setState(() {
          _diseaseScores
            ..clear()
            ..addAll(allScores);
        });
      } else {
        print('⚠️ all-diseases 호출 실패: ${respAll.statusCode} ${respAll.body}');
      }

      await _loadDiseaseInfo();
    } catch (e) {
      print('❌ top-diseases 호출 오류: $e');
      setState(() {
        _topDiseases = [];
      });
    }
  }

  /// AI로 질병 정보 가져오기
  Future<void> _loadDiseaseInfo() async {
    if (_topDiseases.isEmpty) return;
    setState(() => _isLoadingInfo = true);
    try {
      for (var disease in _topDiseases) {
        if (!_diseaseInfo.containsKey(disease.key)) {
          try {
            final info = await _getDiseaseInfoFromAI(disease.key);
            _diseaseInfo[disease.key] = info;
          } catch (e) {
            print("❌ 질병 정보 로딩 실패: ${disease.key} - $e");
          }
        }
      }
    } finally {
      setState(() => _isLoadingInfo = false);
    }
  }

  Future<DiseaseInfo> _getDiseaseInfoFromAI(String diseaseName) async {
    try {
      final response = await http.post(
        Uri.parse("http://98.91.66.27:8080/api/analyze/disease-info"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"diseaseName": diseaseName}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        return DiseaseInfo(
          description: data["description"] ?? "정보를 가져올 수 없습니다.",
          prognosis: data["prognosis"] ?? "예후 정보를 가져올 수 없습니다.",
        );
      } else {
        print("⚠️ 서버 오류: ${response.statusCode}");
        return DiseaseInfo(
          description: "정보를 가져올 수 없습니다.",
          prognosis: "예후 정보를 가져올 수 없습니다.",
        );
      }
    } catch (e) {
      print("❌ 서버 연결 실패: $e");
      return DiseaseInfo(
        description: "정보를 가져올 수 없습니다.",
        prognosis: "예후 정보를 가져올 수 없습니다.",
      );
    }
  }

  void _goToMain() async {
    try {
      await http.post(Uri.parse('http://98.91.66.27:8080/api/analyze/reset-diagnosis'));
    } catch (_) {}
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const MyApp()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = const Color(0xFF0F4C75);
    final secondaryColor = const Color(0xFF3282B8);
    final accentColor = const Color(0xFFBBE1FA);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '진단 결과',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: primaryColor,
        elevation: 0,
        centerTitle: true,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [primaryColor, secondaryColor, accentColor],
            stops: const [0.0, 0.55, 1.0],
          ),
        ),
        child: SafeArea(
          child: _buildResultContent(),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _goToMain,
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.home),
        label: const Text(
          '처음으로',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _buildResultContent() {
    if (_topDiseases.isEmpty) {
      return _buildEmptyState();
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTopDiseaseCard(),
          const SizedBox(height: 30),
          _buildAllDiseasesList(),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.medical_information_outlined,
            size: 100,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 20),
          Text(
            '진단 데이터가 없습니다',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '다른 페이지에서 질병 정보를 입력해주세요',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopDiseaseCard() {
    final primaryColor = const Color(0xFF0F4C75);
    final secondaryColor = const Color(0xFF3282B8);
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [primaryColor, secondaryColor],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.emoji_events,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  '진단 결과 TOP 2',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // 각 질병 카드
          ..._topDiseases.map((entry) => _buildDiseaseRankCard(entry)).toList(),
        ],
      ),
    );
  }

  Widget _buildDiseaseRankCard(MapEntry<String, double> disease) {
    final primaryColor = const Color(0xFF0F4C75);
    final info = _diseaseInfo[disease.key];
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 6),
          )
        ],
        border: Border.all(color: primaryColor.withOpacity(0.15), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  disease.key,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: primaryColor,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${disease.value.toStringAsFixed(1)}점',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: primaryColor,
                  ),
                ),
              )
            ],
          ),
          const SizedBox(height: 12),
          if (_isLoadingInfo)
            const Text(
              "질병 정보를 불러오는 중...",
              style: TextStyle(fontSize: 13, color: Colors.grey),
            )
          else if (info != null) ...[
            Text(
              info.description,
              style: const TextStyle(fontSize: 14, color: Colors.black87, height: 1.4),
            ),
            const SizedBox(height: 8),
            Text(
              info.prognosis,
              style: const TextStyle(fontSize: 13, color: Colors.black54, height: 1.4),
            ),
          ] else ...[
            const Text(
              "정보를 가져올 수 없습니다.",
              style: TextStyle(fontSize: 13, color: Colors.grey),
            )
          ]
        ],
      ),
    );
  }

  Widget _buildAllDiseasesList() {
    final primaryColor = const Color(0xFF0F4C75);
    if (_diseaseScores.isEmpty) return const SizedBox.shrink();
    // 상위 2개 외 나머지 (현재는 2개만 있으므로 표시 생략 가능)
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: primaryColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.list_alt,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '기타 질병',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ..._diseaseScores.entries.skip(2).map((entry) => _buildDiseaseItem(entry.key, entry.value)),
        ],
      ),
    );
  }

  Widget _buildDiseaseItem(String diseaseName, double score) {
    final primaryColor = const Color(0xFF0F4C75);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F8FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: primaryColor.withOpacity(0.1), width: 1),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              diseaseName,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              '${score.toStringAsFixed(1)}점',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: primaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
