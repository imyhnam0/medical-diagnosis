class DiseaseDataManager {
  static final DiseaseDataManager _instance = DiseaseDataManager._internal();
  factory DiseaseDataManager() => _instance;
  DiseaseDataManager._internal();

  // 각 분석 단계별 질병 리스트 저장
  List<Map<String, dynamic>> _symptomDiseases = []; // 증상 관련 질병
  List<Map<String, dynamic>> _pastDiseases = [];
  List<Map<String, dynamic>> _socialDiseases = [];
  List<Map<String, dynamic>> _aggravatingDiseases = [];
  List<Map<String, dynamic>> _riskFactorDiseases = [];
  List<String> _symptomKeywords = [];
  List<String> _pastDiseaseKeywords = [];
  List<String> _socialKeywords = [];
  List<String> _aggravatingKeywords = [];
  List<String> _riskFactorKeywords = [];

  // Getters
  List<Map<String, dynamic>> get symptomDiseases => _symptomDiseases;
  List<Map<String, dynamic>> get pastDiseases => _pastDiseases;
  List<Map<String, dynamic>> get socialDiseases => _socialDiseases;
  List<Map<String, dynamic>> get aggravatingDiseases => _aggravatingDiseases;
  List<Map<String, dynamic>> get riskFactorDiseases => _riskFactorDiseases;
  List<String> get symptomKeywords => _symptomKeywords;
  List<String> get pastDiseaseKeywords => _pastDiseaseKeywords;
  List<String> get socialKeywords => _socialKeywords;
  List<String> get aggravatingKeywords => _aggravatingKeywords;
  List<String> get riskFactorKeywords => _riskFactorKeywords;

  // 모든 질병 리스트 합치기
  List<Map<String, dynamic>> get allDiseases => [..._symptomDiseases, ..._pastDiseases, ..._socialDiseases, ..._aggravatingDiseases, ..._riskFactorDiseases];
  
  // 모든 키워드 합치기
  List<String> get allKeywords => [..._symptomKeywords, ..._pastDiseaseKeywords, ..._socialKeywords, ..._aggravatingKeywords, ..._riskFactorKeywords];

  // 데이터 설정 메서드들
  void setSymptomDiseases(List<Map<String, dynamic>> diseases) {
    _symptomDiseases = diseases;
  }

  void setPastDiseases(List<Map<String, dynamic>> diseases) {
    _pastDiseases = diseases;
  }

  void setSocialDiseases(List<Map<String, dynamic>> diseases) {
    _socialDiseases = diseases;
  }

  void setSymptomKeywords(List<String> keywords) {
    _symptomKeywords = keywords;
  }

  void setPastDiseaseKeywords(List<String> keywords) {
    _pastDiseaseKeywords = keywords;
  }

  void setSocialKeywords(List<String> keywords) {
    _socialKeywords = keywords;
  }

  void setAggravatingKeywords(List<String> keywords) {
    _aggravatingKeywords = keywords;
  }

  void setRiskFactorKeywords(List<String> keywords) {
    _riskFactorKeywords = keywords;
  }

  //키워드들
  void setAggravatingDiseases(List<Map<String, dynamic>> diseases) {
    _aggravatingDiseases = diseases;
  }
  //키워드들
  void setRiskFactorDiseases(List<Map<String, dynamic>> diseases) {
    _riskFactorDiseases = diseases;
  }

  // 데이터 초기화
  void clearAll() {
    _symptomDiseases.clear();
    _pastDiseases.clear();
    _socialDiseases.clear();
    _aggravatingDiseases.clear();
    _riskFactorDiseases.clear();
    _symptomKeywords.clear();
    _pastDiseaseKeywords.clear();
    _socialKeywords.clear();
    _aggravatingKeywords.clear();
    _riskFactorKeywords.clear();
    print("🔄 DiseaseDataManager 초기화 완료");
  }

  // 새로운 진단 시작 시 초기화
  void initializeNewDiagnosis() {
    clearAll();
    print("🆕 새로운 진단을 시작합니다. 모든 데이터가 초기화되었습니다.");
  }

  // 디버그용 출력
  void printAllData() {
    print("=== 저장된 모든 질병 데이터 ===");
    print("증상 관련 질병 (${_symptomDiseases.length}개):");
    if (_symptomDiseases.isEmpty) {
      print("  - 없음");
    } else {
      final symptomNames = _symptomDiseases.map((d) => d['질환명'] as String).toList();
      for (var i = 0; i < symptomNames.length; i += 10) {
        final end = (i + 10 < symptomNames.length) ? i + 10 : symptomNames.length;
        print("  ${symptomNames.sublist(i, end).join(', ')}");
      }
    }
    print("증상 키워드 (${_symptomKeywords.length}개):");
    if (_symptomKeywords.isEmpty) {
      print("  - 없음");
    } else {
      for (var i = 0; i < _symptomKeywords.length; i += 10) {
        final end = (i + 10 < _symptomKeywords.length) ? i + 10 : _symptomKeywords.length;
        print("  ${_symptomKeywords.sublist(i, end).join(', ')}");
      }
    }
    
    print("\n과거 질환 이력 질병 (${_pastDiseases.length}개):");
    if (_pastDiseases.isEmpty) {
      print("  - 없음");
    } else {
      final pastNames = _pastDiseases.map((d) => d['질환명'] as String).toList();
      for (var i = 0; i < pastNames.length; i += 10) {
        final end = (i + 10 < pastNames.length) ? i + 10 : pastNames.length;
        print("  ${pastNames.sublist(i, end).join(', ')}");
      }
    }
    print("과거 질환 이력 키워드 (${_pastDiseaseKeywords.length}개):");
    if (_pastDiseaseKeywords.isEmpty) {
      print("  - 없음");
    } else {
      for (var i = 0; i < _pastDiseaseKeywords.length; i += 10) {
        final end = (i + 10 < _pastDiseaseKeywords.length) ? i + 10 : _pastDiseaseKeywords.length;
        print("  ${_pastDiseaseKeywords.sublist(i, end).join(', ')}");
      }
    }
    
    print("\n사회적 이력 질병 (${_socialDiseases.length}개):");
    if (_socialDiseases.isEmpty) {
      print("  - 없음");
    } else {
      final socialNames = _socialDiseases.map((d) => d['질환명'] as String).toList();
      for (var i = 0; i < socialNames.length; i += 10) {
        final end = (i + 10 < socialNames.length) ? i + 10 : socialNames.length;
        print("  ${socialNames.sublist(i, end).join(', ')}");
      }
    }
    print("사회적 이력 키워드 (${_socialKeywords.length}개):");
    if (_socialKeywords.isEmpty) {
      print("  - 없음");
    } else {
      for (var i = 0; i < _socialKeywords.length; i += 10) {
        final end = (i + 10 < _socialKeywords.length) ? i + 10 : _socialKeywords.length;
        print("  ${_socialKeywords.sublist(i, end).join(', ')}");
      }
    }
    
    print("\n악화 요인 관련 질병 (${_aggravatingDiseases.length}개):");
    if (_aggravatingDiseases.isEmpty) {
      print("  - 없음");
    } else {
      final aggravatingNames = _aggravatingDiseases.map((d) => d['질환명'] as String).toList();
      for (var i = 0; i < aggravatingNames.length; i += 10) {
        final end = (i + 10 < aggravatingNames.length) ? i + 10 : aggravatingNames.length;
        print("  ${aggravatingNames.sublist(i, end).join(', ')}");
      }
    }
    print("악화 요인 키워드 (${_aggravatingKeywords.length}개):");
    if (_aggravatingKeywords.isEmpty) {
      print("  - 없음");
    } else {
      for (var i = 0; i < _aggravatingKeywords.length; i += 10) {
        final end = (i + 10 < _aggravatingKeywords.length) ? i + 10 : _aggravatingKeywords.length;
        print("  ${_aggravatingKeywords.sublist(i, end).join(', ')}");
      }
    }
    
    print("\n위험 요인 관련 질병 (${_riskFactorDiseases.length}개):");
    if (_riskFactorDiseases.isEmpty) {
      print("  - 없음");
    } else {
      final riskFactorNames = _riskFactorDiseases.map((d) => d['질환명'] as String).toList();
      for (var i = 0; i < riskFactorNames.length; i += 10) {
        final end = (i + 10 < riskFactorNames.length) ? i + 10 : riskFactorNames.length;
        print("  ${riskFactorNames.sublist(i, end).join(', ')}");
      }
    }
    print("위험 요인 키워드 (${_riskFactorKeywords.length}개):");
    if (_riskFactorKeywords.isEmpty) {
      print("  - 없음");
    } else {
      for (var i = 0; i < _riskFactorKeywords.length; i += 10) {
        final end = (i + 10 < _riskFactorKeywords.length) ? i + 10 : _riskFactorKeywords.length;
        print("  ${_riskFactorKeywords.sublist(i, end).join(', ')}");
      }
    }
  
  }
}
