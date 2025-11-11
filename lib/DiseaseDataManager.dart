class DiseaseDataManager {
  static final DiseaseDataManager _instance = DiseaseDataManager._internal();
  factory DiseaseDataManager() => _instance;
  DiseaseDataManager._internal();

  final Map<String, double> _diseaseScoreTotals = {};


  Map<String, double> get diseaseScoreTotals => _diseaseScoreTotals;


  // 데이터 초기화
  void clearAll() {
    _diseaseScoreTotals.clear();
    print("🔄 DiseaseDataManager 초기화 완료");
  }

  // 새로운 진단 시작 시 초기화
  void initializeNewDiagnosis() {
    clearAll();
    print("🆕 새로운 진단을 시작합니다. 모든 데이터가 초기화되었습니다.");
  }

  void addDiseaseScores(
    Iterable<Map<String, dynamic>> diseases, {
    double score = 1.0,
  }) {
    for (final disease in diseases) {
      final rawName = disease['질환명'];
      if (rawName == null) continue;
      final name = rawName.toString().trim();
      if (name.isEmpty) continue;
      _diseaseScoreTotals[name] = (_diseaseScoreTotals[name] ?? 0) + score;
    }
  }

  void printScoreTotals() {
  if (_diseaseScoreTotals.isEmpty) {
    print("\n질병 점수 총합: 데이터 없음");
    return;
  }

  print("\n🩺 질병 점수 총합:");

  // 점수 순으로 내림차순 정렬
  final sorted = _diseaseScoreTotals.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));

  const int itemsPerLine = 5;
  final buffer = StringBuffer();

  for (int i = 0; i < sorted.length; i++) {
    final entry = sorted[i];
    buffer.write("${entry.key}(${entry.value.toStringAsFixed(1)}점)");

    // 5개 단위로 줄바꿈
    if ((i + 1) % itemsPerLine == 0 || i == sorted.length - 1) {
      print(buffer.toString());
      buffer.clear();
    } else {
      buffer.write("  |  "); // 구분자
    }
  }
}

}
