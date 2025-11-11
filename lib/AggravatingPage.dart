import 'package:flutter/material.dart';
import 'RiskFactorPage.dart';
import 'DiseaseDataManager.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AggravatingPage extends StatefulWidget {
  final Map<String, dynamic>? personalInfo;
  const AggravatingPage({super.key, this.personalInfo});

  @override
  State<AggravatingPage> createState() => _AggravatingPageState();
}

class _AggravatingPageState extends State<AggravatingPage> {
  final TextEditingController _controller = TextEditingController();
  bool _isLoading = false;
  final Set<String> _matchedKeywords = {};
  List<Map<String, dynamic>> _pendingDiseases = [];
  bool _canProceedNext = false;

  Future<void> _analyzeInput(String input) async {
    if (input.trim().isEmpty) return;
    setState(() => _isLoading = true);

    try {
      // ✅ Node.js 서버 호출
      final response = await http.post(
        Uri.parse("http://localhost:8080/api/analyze/aggravation"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"aggravateDiseaseInput": input}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        final matched = List<String>.from(data["matchedKeywords"] ?? []);
        final diseases = List<Map<String, dynamic>>.from(data["diseases"] ?? []);

        if (matched.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("악화 요인을 추출하지 못했습니다.")),
          );
        }

        setState(() {
          _matchedKeywords
            ..clear()
            ..addAll(matched);
          _pendingDiseases = diseases;
          _canProceedNext = true;
        });

        setState(() => _isLoading = false);
      } else {
        print("⚠️ 서버 오류: ${response.statusCode}");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("서버 오류가 발생했습니다 (${response.statusCode})"),
            backgroundColor: Colors.redAccent,
          ),
        );
        setState(() => _isLoading = false);
      }
    } catch (e) {
      print("❌ 악화 요인 분석 중 오류: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("서버 연결 오류: $e"),
          backgroundColor: Colors.redAccent,
        ),
      );
      setState(() => _isLoading = false);
    }
  }

  Future<void> _goToNextStep() async {
    if (!_canProceedNext) return;

    if (_pendingDiseases.isNotEmpty) {
      final manager = DiseaseDataManager();
      manager.addDiseaseScores(_pendingDiseases);
    }

    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RiskFactorPage(personalInfo: widget.personalInfo),
      ),
    );

    if (!mounted) return;
    setState(() {
      _canProceedNext = false;
    });
  }


  @override
  Widget build(BuildContext context) {
    final primaryColor = const Color(0xFF0F4C75);
    final secondaryColor = const Color(0xFF3282B8);
    final accentColor = const Color(0xFFBBE1FA);

    return Scaffold(
      appBar: AppBar(
        title: const Text("흉통 악화 요인"),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Container
      (
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [primaryColor, secondaryColor, accentColor],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            stops: const [0.0, 0.55, 1.0],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
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
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [primaryColor, secondaryColor],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.troubleshoot, color: Colors.white),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              "어떤 상황에서 증상이 더 심해지나요?",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF1A202C),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      Text(
                        "예: 계단 오를 때, 깊게 숨쉴 때, 기침할 때, 식후, 스트레스 등",
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                        ),
                      ),

                      const SizedBox(height: 12),

                      Container(
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: primaryColor.withOpacity(0.15)),
                        ),
                        child: TextField(
                          controller: _controller,
                          maxLines: 3,
                          decoration: InputDecoration(
                            hintText: "예: 계단 오를 때 더 아파요, 깊게 숨쉬면 심해져요",
                            hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                            prefixIcon: Icon(Icons.trending_up, color: primaryColor),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide.none,
                            ),
                            filled: true,
                            fillColor: Colors.transparent,
                            contentPadding: const EdgeInsets.all(16),
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            foregroundColor: Colors.white,
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          onPressed: _isLoading
                              ? null
                              : () => _analyzeInput(_controller.text),
                          icon: _isLoading
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.auto_awesome),
                          label: Text(
                            _isLoading ? "분석 중..." : "AI로 분석",
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      if (_matchedKeywords.isNotEmpty)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "추출된 악화 요인",
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: primaryColor,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: _matchedKeywords.map((keyword) {
                                return Chip(
                                  label: Text(
                                    keyword,
                                    style: TextStyle(
                                      color: primaryColor,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  backgroundColor: primaryColor.withOpacity(0.12),
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      if (_matchedKeywords.isEmpty && !_isLoading)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 20,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: primaryColor.withOpacity(0.15),
                            ),
                          ),
                          child: Text(
                            "AI 분석 결과가 여기에 표시됩니다.",
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 12,
                offset: const Offset(0, -3),
              ),
            ],
          ),
          child: SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _canProceedNext ? _goToNextStep : null,
              style: ElevatedButton.styleFrom(
                elevation: _canProceedNext ? 4 : 0,
                backgroundColor:
                    _canProceedNext ? Colors.transparent : Colors.grey[300],
                shadowColor:
                    _canProceedNext ? Colors.black26 : Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: EdgeInsets.zero,
              ),
              child: _canProceedNext
                  ? Ink(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [primaryColor, secondaryColor],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Container(
                        alignment: Alignment.center,
                        child: Text(
                          "다음 단계로 (${_matchedKeywords.length}개 악화 요인)",
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    )
                  : Container(
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Text(
                        "AI 분석을 완료하면 다음 단계로 이동할 수 있어요",
                        style: TextStyle(
                          color: Colors.black54,
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
