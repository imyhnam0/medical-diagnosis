import 'package:flutter/material.dart';
import 'DiseaseDataManager.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'isdiseaseright.dart';

enum _SocialField {
  age,
  bmi,
  gender,
  drinking,
  smoking,
  job,
  exercise,
}

class PersonalInfoPage extends StatefulWidget {
  const PersonalInfoPage({super.key});

  @override
  State<PersonalInfoPage> createState() => _PersonalInfoPageState();
}

class _PersonalInfoPageState extends State<PersonalInfoPage>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late PageController _pageController;

  // 개인정보 입력 필드들
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _jobController = TextEditingController();
  final TextEditingController _drinkingController = TextEditingController();
  final TextEditingController _smokingController = TextEditingController();
  final TextEditingController _exerciseController = TextEditingController();

  String? _selectedGender;

  int _currentPage = 0;
  bool _isAnalyzing = false;
  double? _calculatedBmi;

  final Map<_SocialField, GlobalKey<FormState>> _formKeys = {
    for (final field in _SocialField.values) field: GlobalKey<FormState>(),
  };

  final Map<_SocialField, List<String>> _keywordsByField = {};
  final Map<_SocialField, List<Map<String, dynamic>>> _diseasesByField = {};
  final Set<_SocialField> _completedFields = {};

  @override
  void initState() {
    super.initState();
    _pageController = PageController();

    _weightController.addListener(_updateBmi);
    _heightController.addListener(_updateBmi);
    
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic));

    _fadeController.forward();
    Future.delayed(const Duration(milliseconds: 200), () {
      _slideController.forward();
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    _ageController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    _jobController.dispose();
    _drinkingController.dispose();
    _smokingController.dispose();
    _exerciseController.dispose();
    super.dispose();
  }

  void _updateBmi() {
    final weight = double.tryParse(_weightController.text.replaceAll(',', '.'));
    final height =
        double.tryParse(_heightController.text.replaceAll(',', '.'));

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

  Future<void> _analyzeCurrentField() async {
    final field = _SocialField.values[_currentPage];
    final formKey = _formKeys[field];

    if (formKey != null && field != _SocialField.gender) {
      final isValid = formKey.currentState?.validate() ?? false;
      if (!isValid) {
        return;
      }
    }

    if (field == _SocialField.gender && _selectedGender == null) {
      _showSnackBar("성별을 선택해주세요.");
      return;
    }

    if (field == _SocialField.bmi && _calculatedBmi == null) {
      _showSnackBar("정확한 체중과 키를 입력해서 BMI를 계산해주세요.");
      return;
    }

    final payload = _buildCumulativePayload(field);
    if (payload == null) {
      _showSnackBar("입력값을 다시 확인해주세요.");
      return;
    }

    setState(() {
      _isAnalyzing = true;
    });

    try {
      final response = await http.post(
        Uri.parse("http://localhost:8080/api/analyze/social-history"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(payload),
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        final rawDiseases = body['socialDiseases'] ?? body['diseases'];
        final diseases = (rawDiseases as List<dynamic>? ?? [])
            .map((d) => (d as Map).cast<String, dynamic>())
            .toList();
        final keywordsRaw = body['socialKeywords'] ?? body['matchedKeywords'];
        final keywords = (keywordsRaw as List<dynamic>? ?? [])
            .map((keyword) => keyword.toString())
            .toList();

        final existingKeywords = _keywordsByField.values
            .expand((list) => list)
            .map((keyword) => keyword.trim())
            .where((keyword) => keyword.isNotEmpty)
            .toSet();
        final filteredKeywords = keywords
            .map((keyword) => keyword.trim())
            .where((keyword) =>
                keyword.isNotEmpty && !existingKeywords.contains(keyword))
            .toList();

        final filteredDiseases = filteredKeywords.isEmpty
            ? <Map<String, dynamic>>[]
            : diseases.where((disease) {
          final historyField = disease['사회적 이력'];
          if (historyField is List) {
            final historySet = historyField
                .map((item) => item.toString().trim())
                .where((value) => value.isNotEmpty)
                .toSet();
            return historySet
                .any((historyKeyword) => filteredKeywords.contains(historyKeyword));
          }
          return false;
        }).toList();

        final previousKeywords = _keywordsByField[field] ?? [];
        final previousDiseases = _diseasesByField[field] ?? [];

        final updatedKeywords = <String>{
          ...previousKeywords.map((keyword) => keyword.trim()).where((k) => k.isNotEmpty),
          ...filteredKeywords,
        }.toList();

        final updatedDiseasesMap = <String, Map<String, dynamic>>{
          for (final disease in previousDiseases)
            (disease['질환명']?.toString() ?? jsonEncode(disease)): disease,
        };
        for (final disease in filteredDiseases) {
          final key = disease['질환명']?.toString() ?? jsonEncode(disease);
          updatedDiseasesMap[key] = disease;
        }

        final updatedDiseases = updatedDiseasesMap.values.toList();

        setState(() {
          _keywordsByField[field] = updatedKeywords;
          _diseasesByField[field] = updatedDiseases;
          _completedFields.add(field);
        });

        if (filteredDiseases.isNotEmpty) {
          _mergeSocialResults(filteredDiseases, filteredKeywords);
        }
      } else {
        _showSnackBar("서버 오류가 발생했습니다. (${response.statusCode})");
      }
    } catch (e) {
      if (!mounted) return;
      _showSnackBar("분석 중 오류가 발생했습니다. 다시 시도해주세요.");
      print("❌ 사회 이력 분석 중 오류: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isAnalyzing = false;
        });
      }
    }
  }

  Map<String, dynamic>? _buildCumulativePayload(_SocialField currentField) {
    // ✅ 개별 유효성 검사 포함한 누적 데이터 생성
    final Map<String, dynamic> payload = {};

    // 🔹 나이
    final age = int.tryParse(_ageController.text);
    if (age != null && age >= 0 && age <= 150) {
      payload['age'] = age;
    }

    // 🔹 BMI
    if (_calculatedBmi != null && _calculatedBmi! > 0 && _calculatedBmi! < 100) {
      payload['bmi'] = _calculatedBmi;
    }

    // 🔹 성별
    if (_selectedGender != null && _selectedGender!.isNotEmpty) {
      payload['gender'] = _selectedGender;
    }

    // 🔹 음주
    final drinking = _drinkingController.text.trim();
    if (drinking.isNotEmpty) {
      payload['drinking'] = drinking;
    }

    // 🔹 흡연
    final smoking = _smokingController.text.trim();
    if (smoking.isNotEmpty) {
      payload['smoking'] = smoking;
    }

    // 🔹 직업
    final job = _jobController.text.trim();
    if (job.isNotEmpty) {
      payload['job'] = job;
    }

    // 🔹 운동
    final exercise = _exerciseController.text.trim();
    if (exercise.isNotEmpty) {
      payload['exercise'] = exercise;
    }

    // 🔹 디버깅용 로그
    print("📤 [${currentField.name}] 누적 payload: $payload");

    // 값이 하나도 없을 경우 null 반환
    return payload.isEmpty ? null : payload;
  }


  // DiseaseDataManager에 socialDiseases, socialKeywords가 없으므로, 아래처럼 manager에 내장된 리스트 따로 안 씀.
  // 단순히 new 값을 바로 처리하거나 Score만 누적하려면 아래처럼 간단히 작성 가능.

  void _mergeSocialResults(
    List<Map<String, dynamic>> newDiseases,
    List<String> newKeywords,
  ) {
    final manager = DiseaseDataManager();

    // ✅ 질병은 중복 여부 상관없이 모두 점수 누적 (누적형 구조)
    final dedupedDiseases = <String, Map<String, dynamic>>{};
    for (final disease in newDiseases) {
      final name = disease['질환명']?.toString() ?? jsonEncode(disease);
      dedupedDiseases[name] = disease;
    }

    // ✅ 질병 점수는 계속 누적 (중복 가능)
    if (dedupedDiseases.isNotEmpty) {
      manager.addDiseaseScores(dedupedDiseases.values);
    }

    manager.printScoreTotals();

    print("✨ 새 키워드 추가됨: ${newKeywords.map((e) => e.trim()).where((e) => e.isNotEmpty).toList()}");
    print("🧩 질병 점수 누적됨: ${dedupedDiseases.keys}");
  }


  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFF0F4C75),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  void _goToNextPage() {
    if (_currentPage >= _SocialField.values.length - 1) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => IsDiseaseRightPage(),
        ),
      );
      return;
    }

    setState(() {
      _currentPage += 1;
    });
    _pageController.animateToPage(
      _currentPage,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenHeight < 700;
    
    final primaryColor = const Color(0xFF0F4C75);
    final secondaryColor = const Color(0xFF3282B8);
    final accentColor = const Color(0xFFBBE1FA);

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              primaryColor,
              secondaryColor,
              accentColor,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            stops: const [0.0, 0.6, 1.0],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              Column(
                children: [
                  // 상단 앱바
                  Container(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                        ),
                        Expanded(
                          child: Column(
                            children: [
                              Text(
                                "개인정보 입력",
                                style: TextStyle(
                                  fontSize: isSmallScreen ? 20 : 24,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "항목별로 입력하고 분석 결과를 확인하세요",
                                style: TextStyle(
                                  fontSize: isSmallScreen ? 12 : 14,
                                  color: Colors.white.withOpacity(0.8),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 48), // 뒤로가기 버튼과 균형 맞추기
                      ],
                    ),
                  ),

                  // 단계 진행률 표시
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.08),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "단계 ${_currentPage + 1} / ${_SocialField.values.length}",
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          height: 6,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: FractionallySizedBox(
                            alignment: Alignment.centerLeft,
                            widthFactor:
                                (_currentPage + 1) / _SocialField.values.length,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // 페이지별 입력 영역
                  Expanded(
                    child: PageView(
                      controller: _pageController,
                      physics: const NeverScrollableScrollPhysics(),
                      children: _SocialField.values
                          .map(
                            (field) => _buildStepPage(
                              field: field,
                              screenWidth: screenWidth,
                            ),
                          )
                          .toList(),
                    ),
                  ),
                ],
              ),
              if (_isAnalyzing)
                Container(
                  color: Colors.black.withOpacity(0.3),
                  child: const Center(
                    child: CircularProgressIndicator(),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepPage({
    required _SocialField field,
    required double screenWidth,
  }) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
      child: Form(
        key: _formKeys[field],
        child: Column(
          children: [
            _buildInputCard(
              icon: _iconForField(field),
              title: _titleForField(field),
              child: _buildInputForField(field),
            ),
            const SizedBox(height: 24),
            _buildAnalyzeButton(),
            if (_completedFields.contains(field)) ...[
              const SizedBox(height: 16),
              _buildNextButton(field),
            ],
            const SizedBox(height: 24),
            _buildResultSection(field),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  IconData _iconForField(_SocialField field) {
    switch (field) {
      case _SocialField.age:
        return Icons.cake;
      case _SocialField.bmi:
        return Icons.monitor_weight;
      case _SocialField.gender:
        return Icons.person;
      case _SocialField.drinking:
        return Icons.local_drink;
      case _SocialField.smoking:
        return Icons.smoking_rooms;
      case _SocialField.job:
        return Icons.work;
      case _SocialField.exercise:
        return Icons.fitness_center;
    }
  }

  String _titleForField(_SocialField field) {
    switch (field) {
      case _SocialField.age:
        return "나이가 어떻게 되십니까?";
      case _SocialField.bmi:
        return "체중이랑 키가 어떻게 되십니까?";
      case _SocialField.gender:
        return "어떤 성병을 가지고 있습니까?";
      case _SocialField.drinking:
        return "음주는 주에 몇번 하시나요?";
      case _SocialField.smoking:
        return "흡연은 하시나요?";
      case _SocialField.job:
        return "어떤 직업을 가지고 계신가요";
      case _SocialField.exercise:
        return "운동을 하시나요?";
    }
  }

  Widget _buildInputForField(_SocialField field) {
    switch (field) {
      case _SocialField.age:
        return TextFormField(
          controller: _ageController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            hintText: "나이를 입력하세요",
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            filled: true,
            fillColor: Colors.grey[100],
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return "나이를 입력해주세요";
            }
            final age = int.tryParse(value);
            if (age == null || age < 0 || age > 150) {
              return "올바른 나이를 입력해주세요";
            }
            return null;
          },
        );
      case _SocialField.bmi:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _weightController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      hintText: "체중 (kg)",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.grey[100],
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return "체중을 입력해주세요";
                      }
                      final weight = double.tryParse(
                        value.replaceAll(',', '.'),
                      );
                      if (weight == null || weight <= 0 || weight > 500) {
                        return "올바른 체중을 입력해주세요";
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _heightController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      hintText: "키 (cm)",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.grey[100],
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return "키를 입력해주세요";
                      }
                      final height = double.tryParse(
                        value.replaceAll(',', '.'),
                      );
                      if (height == null || height <= 0 || height > 300) {
                        return "올바른 키를 입력해주세요";
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF0F4C75).withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _calculatedBmi == null
                    ? "BMI는 체중과 키를 입력하면 자동 계산됩니다."
                    : "계산된 BMI: ${_calculatedBmi!.toStringAsFixed(1)}",
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF0F4C75),
                ),
              ),
            ),
          ],
        );
      case _SocialField.gender:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: _buildSelectionButton(
                    "남성",
                    _selectedGender == "남성",
                    () => setState(() => _selectedGender = "남성"),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildSelectionButton(
                    "여성",
                    _selectedGender == "여성",
                    () => setState(() => _selectedGender = "여성"),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              "성별을 선택한 뒤 아래 분석하기 버튼을 눌러주세요.",
              style: TextStyle(
                color: Colors.grey[700],
                fontSize: 13,
              ),
            ),
          ],
        );
      case _SocialField.drinking:
        return TextFormField(
          controller: _drinkingController,
          decoration: const InputDecoration(
            hintText: "예: 주 2-3회, 소주 1-2병 정도 마심",
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.all(12),
          ),
          maxLines: 2,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return '음주 여부를 입력해주세요';
            }
            return null;
          },
        );
      case _SocialField.smoking:
        return TextFormField(
          controller: _smokingController,
          decoration: const InputDecoration(
            hintText: "예: 하루 1갑 정도, 금연 3년차, 전혀 안 함",
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.all(12),
          ),
          maxLines: 2,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return '흡연 여부를 입력해주세요';
            }
            return null;
          },
        );
      case _SocialField.job:
        return TextFormField(
          controller: _jobController,
          decoration: InputDecoration(
            hintText: "직업을 입력하세요",
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            filled: true,
            fillColor: Colors.grey[100],
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return "직업을 입력해주세요";
            }
            return null;
          },
        );
      case _SocialField.exercise:
        return TextFormField(
          controller: _exerciseController,
          decoration: const InputDecoration(
            hintText: "예: 주 3회 헬스장, 매일 30분 걷기, 거의 안 함",
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.all(12),
          ),
          maxLines: 2,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return '운동 여부를 입력해주세요';
            }
            return null;
          },
        );
    }
  }

  Widget _buildAnalyzeButton() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              padding: EdgeInsets.zero,
            ),
            onPressed: _isAnalyzing ? null : _analyzeCurrentField,
            child: Ink(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF0F4C75),
                    const Color(0xFF3282B8),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Container(
                alignment: Alignment.center,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.analytics,
                      color: Colors.white,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "분석하기",
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNextButton(_SocialField field) {
    final isLast = field == _SocialField.values.last;
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.white,
          side: const BorderSide(color: Colors.white),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        onPressed: () {
          if (isLast) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => IsDiseaseRightPage(),
              ),
            );
          } else {
            _goToNextPage();
          }
        },
        child: Text(
          "다음 단계로",
          style: const TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildResultSection(_SocialField field) {
    final keywords = _keywordsByField[field] ?? [];
    final diseases = _diseasesByField[field] ?? [];
    final isAnalyzed = _completedFields.contains(field);

    if (keywords.isEmpty && diseases.isEmpty && !isAnalyzed) {
      return Column(
        children: [
          Icon(
            Icons.info_outline,
            color: Colors.white.withOpacity(0.7),
            size: 36,
          ),
          const SizedBox(height: 12),
          Text(
            "분석하기 버튼을 누르면 해당 항목에 대한 키워드와 관련 질병이 표시됩니다.",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withOpacity(0.85),
              height: 1.5,
            ),
          ),
        ],
      );
    }

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
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
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF3282B8).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.lightbulb,
                      color: Color(0xFF3282B8),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    "분석 결과",
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A202C),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                "추출된 키워드",
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF0F4C75),
                ),
              ),
              const SizedBox(height: 10),
              if (keywords.isEmpty)
                Text(
                  "없음",
                  style: TextStyle(
                    color: Colors.grey[600],
                  ),
                )
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: keywords
                      .map(
                        (keyword) => Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: 6,
                            horizontal: 12,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFBBE1FA),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            keyword,
                            style: const TextStyle(
                              color: Color(0xFF0F4C75),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
              const SizedBox(height: 20),
              const Text(
                "해당 키워드를 포함한 질병",
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF0F4C75),
                ),
              ),
              const SizedBox(height: 10),
              if (diseases.isEmpty)
                Text(
                  "없음",
                  style: TextStyle(
                    color: Colors.grey[600],
                  ),
                )
              else
                Column(
                  children: diseases
                      .map(
                        (disease) => Container(
                          width: double.infinity,
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                disease['질환명']?.toString() ?? '이름 미확인',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF1A202C),
                                ),
                              ),
                              if (disease['요약'] != null &&
                                  disease['요약'].toString().isNotEmpty) ...[
                                const SizedBox(height: 6),
                                Text(
                                  disease['요약'].toString(),
                                  style: TextStyle(
                                    color: Colors.grey[700],
                                    height: 1.5,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      )
                      .toList(),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputCard({
    required IconData icon,
    required String title,
    required Widget child,
  }) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
            border: Border.all(
              color: Colors.white.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F4C75).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      icon,
                      color: const Color(0xFF0F4C75),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A202C),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              child,
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSelectionButton(String text, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected 
              ? const Color(0xFF0F4C75).withOpacity(0.1)
              : Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected 
                ? const Color(0xFF0F4C75)
                : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: isSelected 
                ? const Color(0xFF0F4C75)
                : Colors.grey[700],
          ),
        ),
      ),
    );
  }
}