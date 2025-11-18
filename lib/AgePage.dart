import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'Drinking_smoking.dart';

class AgePage extends StatefulWidget {
  const AgePage({super.key});

  @override
  State<AgePage> createState() => _AgePageState();
}

class _AgePageState extends State<AgePage> {
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();
  
  String? _selectedGender;
  bool _isLoading = false;
  List<String> _matchedKeywords = [];
  double? _calculatedBmi;
  bool _canProceed = false;

  final primaryColor = const Color(0xFF0F4C75);
  final secondaryColor = const Color(0xFF3282B8);

  @override
  void initState() {
    super.initState();
    _weightController.addListener(_updateBmi);
    _heightController.addListener(_updateBmi);
  }

  @override
  void dispose() {
    _ageController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    super.dispose();
  }

  void _updateBmi() {
    final weight = double.tryParse(_weightController.text.replaceAll(',', '.'));
    final height = double.tryParse(_heightController.text.replaceAll(',', '.'));

    if (weight == null || height == null || height <= 0) {
      setState(() {
        _calculatedBmi = null;
      });
      return;
    }

    final heightInMeters = height / 100;
    if (heightInMeters <= 0) {
      setState(() {
        _calculatedBmi = null;
      });
      return;
    }

    final bmi = weight / (heightInMeters * heightInMeters);
    setState(() {
      _calculatedBmi = double.parse(bmi.toStringAsFixed(1));
    });
  }

  Future<void> _analyzeAgeBmiGender() async {
    // 입력 검증
    final age = int.tryParse(_ageController.text);
    if (age == null || age <= 0 || age > 150) {
      _showSnackBar("올바른 나이를 입력해주세요.");
      return;
    }

    if (_selectedGender == null || _selectedGender!.isEmpty) {
      _showSnackBar("성별을 선택해주세요.");
      return;
    }

    final height = double.tryParse(_heightController.text.replaceAll(',', '.'));
    if (height == null || height <= 0) {
      _showSnackBar("올바른 키를 입력해주세요.");
      return;
    }

    final weight = double.tryParse(_weightController.text.replaceAll(',', '.'));
    if (weight == null || weight <= 0) {
      _showSnackBar("올바른 체중을 입력해주세요.");
      return;
    }

    if (_calculatedBmi == null || _calculatedBmi! <= 0 || _calculatedBmi! > 100) {
      _showSnackBar("체중과 키를 입력하여 BMI를 계산해주세요.");
      return;
    }

    setState(() {
      _isLoading = true;
      _matchedKeywords = [];
    });

    try {
      final url = Uri.parse(
        "http://98.91.66.27:8080/api/analyze/age-bmi-gender"
      );

      final payload = {
        "age": age,
        "bmi": _calculatedBmi,
        "gender": _selectedGender,
        "height": height,
      };

      print("📤 요청 전송: $payload");

      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final keywords = List<String>.from(data["matchedKeywords"] ?? []);
        
        setState(() {
          _matchedKeywords = keywords;
          _canProceed = true;
        });

        if (keywords.isEmpty) {
          _showSnackBar("매칭된 키워드가 없습니다.");
        }
      } else {
        _showSnackBar("서버 오류가 발생했습니다. (${response.statusCode})");
        print("⚠️ 서버 오류: ${response.statusCode} - ${response.body}");
      }
    } catch (e) {
      _showSnackBar("분석 중 오류가 발생했습니다: $e");
      print("❌ 분석 오류: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: primaryColor,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [primaryColor, secondaryColor],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: const Text(
          "나이/BMI/성별 분석",
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.white,
            fontSize: 20,
            letterSpacing: 0.5,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 입력 섹션
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                  border: Border.all(
                    color: primaryColor.withOpacity(0.1),
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.person, color: primaryColor, size: 24),
                        const SizedBox(width: 8),
                        Text(
                          "개인 정보 입력",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: primaryColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    
                    // 나이 입력
                    TextFormField(
                      controller: _ageController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: "나이",
                        hintText: "나이를 입력하세요",
                        prefixIcon: Icon(Icons.calendar_today, color: primaryColor),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: primaryColor, width: 2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // 성별 선택
                    Text(
                      "성별",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: RadioListTile<String>(
                            title: const Text("남성"),
                            value: "남성",
                            groupValue: _selectedGender,
                            onChanged: (value) {
                              setState(() {
                                _selectedGender = value;
                              });
                            },
                            activeColor: primaryColor,
                          ),
                        ),
                        Expanded(
                          child: RadioListTile<String>(
                            title: const Text("여성"),
                            value: "여성",
                            groupValue: _selectedGender,
                            onChanged: (value) {
                              setState(() {
                                _selectedGender = value;
                              });
                            },
                            activeColor: primaryColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    // 키 입력
                    TextFormField(
                      controller: _heightController,
                      keyboardType: TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: "키 (cm)",
                        hintText: "키를 입력하세요 (예: 175)",
                        prefixIcon: Icon(Icons.height, color: primaryColor),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: primaryColor, width: 2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // 체중 입력 (BMI 자동 계산용)
                    TextFormField(
                      controller: _weightController,
                      keyboardType: TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: "체중 (kg)",
                        hintText: "체중을 입력하세요",
                        prefixIcon: Icon(Icons.monitor_weight, color: primaryColor),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: primaryColor, width: 2),
                        ),
                      ),
                    ),
                    if (_calculatedBmi != null) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.calculate, color: primaryColor, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              "계산된 BMI: ${_calculatedBmi!.toStringAsFixed(1)}",
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: primaryColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    
                    // 분석 버튼
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _analyzeAgeBmiGender,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : const Text(
                                "분석하기",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
              const SizedBox(height: 12),
              // 다음으로 버튼
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: _canProceed
                      ? () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const DrinkingSmokingPage()),
                          );
                        }
                      : null,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: BorderSide(color: _canProceed ? primaryColor : Colors.grey.shade400, width: 1.5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    foregroundColor: _canProceed ? primaryColor : Colors.grey,
                  ),
                  child: Text(
                    "다음으로",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: _canProceed ? primaryColor : Colors.grey,
                    ),
                  ),
                ),
              ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // 결과 섹션
              if (_matchedKeywords.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                    border: Border.all(
                      color: primaryColor.withOpacity(0.1),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.check_circle, color: primaryColor, size: 24),
                          const SizedBox(width: 8),
                          Text(
                            "추출된 키워드 (${_matchedKeywords.length}개)",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: primaryColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _matchedKeywords.map((keyword) {
                          return Chip(
                            label: Text(
                              keyword,
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            backgroundColor: primaryColor.withOpacity(0.1),
                            side: BorderSide(color: primaryColor.withOpacity(0.3)),
                            labelStyle: TextStyle(color: primaryColor),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

