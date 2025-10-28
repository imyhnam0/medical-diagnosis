//두번째 페이지
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class YourDiseasePage extends StatefulWidget {
  final String userInput;
  final Map<String, dynamic>? personalInfo;
  const YourDiseasePage({super.key, required this.userInput, this.personalInfo});

  @override
  State<YourDiseasePage> createState() => _YourDiseasePageState();
}

class _YourDiseasePageState extends State<YourDiseasePage> {


  final Map<String, List<String>> symptomCategories = {
    "흉부 관련 증상": [
      "흉통", "협심증 유사 흉통", "갑작스러운 흉통", "설명되지 않는 흉통",
      "안정 시 흉통", "작열성 흉통", "흉골 뒤 압박감", "흉부 불편감",
      "흉부 압박감", "흉벽 통증", "흉벽 불편감", "늑골 압통",
      "방사통", "방사성 흉통"
    ],

    "호흡기 증상": [
      "호흡곤란", "가벼운 호흡곤란", "운동 시 호흡곤란",
      "야간 발작성 호흡곤란", "기침", "가래", "객혈",
      "마른기침", "흉막성 통증", "천명음"
    ],

    "심혈관/전신 증상": [
      "발열", "야간 발한", "피로", "전신 권태", "체중 감소",
      "두근거림", "실신", "어지럼증", "다리 부종"
    ],

    "소화기 증상": [
      "오심", "구토", "설사", "소화기 증상", "속쓰림", "역류",
      "연하곤란", "상복부 불편감", "명치 통증", "복부 불편감",
      "복부 팽만"
    ],

    "신경/근골격계 증상": [
      "목 통증", "등 통증", "등통증", "등/허리 통증",
      "관절통", "국소 근육통", "국소 통증", "근육통",
      "골통", "이질통", "작열통", "압통",
      "움직임 제한", "근력 약화", "팔 약화",
      "감각 이상", "저림", "전신 통증",
      "두개골/흉부 변형", "뻣뻣함", "통증"
    ],

    "피부/감각 증상": [
      "발진", "작열감", "가려움", "유방 멍울", "멍"
    ],

    "신경/인지 기능 증상": [
      "시각 증상", "수면 문제"
    ],

    "정신/심리 증상": [
      "건강 불안", "신체 증상에 대한 집착", "걱정", "플래시백"
    ],

    "여성 생식 관련 증상": [
      "골반 통증", "생리 문제"
    ],

    "기타/기온 반응 관련 증상": [
      "우상복부 통증", "측두부 통증", "설명되지 않는 다발성 증상",
      "추위 불내성"
    ]
  };
  final Map<String, String> symptomCategoryDescriptions = {
    "흉부 관련 증상": "심장이나 가슴 쪽이 아프거나 답답하게 느껴져요.",
    "호흡기 증상": "숨이 차거나 기침, 가래 등 호흡에 불편함이 있어요.",
    "심혈관/전신 증상": "몸 전체가 피곤하거나 맥박, 어지럼, 식은땀 같은 증상이 있어요.",
    "소화기 증상": "속이 더부룩하거나 구역, 속쓰림, 설사 같은 위장 증상이 있어요.",
    "신경/근골격계 증상": "근육이나 관절이 아프고, 저리거나 힘이 잘 안 들어가요.",
    "피부/감각 증상": "피부가 가렵거나 붉은 반점, 멍, 화끈거림이 있어요.",
    "신경/인지 기능 증상": "시야가 흐리거나 잠이 잘 오지 않아요.",
    "정신/심리 증상": "몸이나 건강에 대한 불안, 스트레스, 또는 과거의 트라우마가 떠올라요.",
    "여성 생식 관련 증상": "아랫배 통증, 생리 이상 같은 여성 건강 관련 변화가 있어요.",
    "기타/기온 반응 관련 증상": "특정 부위 통증, 혹은 추위에 예민하게 반응해요."
  };

  final Map<String, String> symptomDescriptions = {
    "흉통": "가슴이 아프거나 뻐근하게 느껴져요.",
    "협심증 유사 흉통": "가슴이 꽉 조이고 숨이 막히는 느낌이에요.",
    "갑작스러운 흉통": "갑자기 가슴이 심하게 아파왔어요.",
    "설명되지 않는 흉통": "이유 없이 가슴이 계속 아픈 것 같아요.",
    "안정 시 흉통": "가만히 있을 때도 가슴이 아파요.",
    "작열성 흉통": "가슴이 화끈거리거나 타는 듯한 느낌이에요.",
    "흉골 뒤 압박감": "가슴 한가운데가 눌리거나 짓눌리는 느낌이에요.",
    "흉부 불편감": "가슴이 답답하거나 불편해요.",
    "흉부 압박감": "가슴이 꽉 조여오고 숨쉬기 힘들어요.",
    "흉벽 통증": "움직이거나 눌렀을 때 가슴 겉이 아파요.",
    "흉벽 불편감": "가슴 바깥쪽이 뻐근하거나 묵직하게 느껴져요.",
    "늑골 압통": "갈비뼈를 누르면 아파요.",
    "방사통": "가슴 통증이 팔이나 어깨, 턱으로 번져요.",
    "방사성 흉통": "가슴이 아프면서 통증이 등이나 팔 쪽으로 퍼져요.",
    "호흡곤란": "숨쉬기가 힘들고 답답해요.",
    "가벼운 호흡곤란": "숨이 약간 차고 평소보다 숨쉬기 불편해요.",
    "운동 시 호흡곤란": "조금만 움직여도 숨이 차요.",
    "야간 발작성 호흡곤란": "밤에 갑자기 숨이 막혀 깨요.",
    "기침": "기침이 자주 나와요.",
    "가래": "가래가 끓거나 자주 뱉게 돼요.",
    "객혈": "기침할 때 피가 섞여 나와요.",
    "마른기침": "가래 없이 기침만 계속 나와요.",
    "흉막성 통증": "숨을 깊이 쉴 때 가슴 옆이 찌릿하게 아파요.",
    "천명음": "숨쉴 때 쌕쌕거리는 소리가 나요.",
    "발열": "몸이 뜨겁고 열이 나요.",
    "야간 발한": "자면서 식은땀이 많이 나요.",
    "피로": "계속 피곤하고 힘이 없어요.",
    "전신 권태": "몸이 무겁고 아무것도 하기 싫어요.",
    "체중 감소": "식단을 바꾸지 않았는데 살이 빠졌어요.",
    "두근거림": "심장이 빠르게 뛰는 게 느껴져요.",
    "실신": "눈앞이 깜깜해지고 쓰러질 뻔했어요.",
    "어지럼증": "머리가 빙빙 돌거나 중심이 안 잡혀요.",
    "다리 부종": "다리가 붓고 신발이 꽉 낄 때가 있어요.",
    "오심": "속이 메스껍고 토할 것 같아요.",
    "구토": "실제로 토했거나 속이 울렁거려요.",
    "설사": "묽은 변을 자주 봐요.",
    "소화기 증상": "소화가 잘 안 되고 더부룩해요.",
    "속쓰림": "속이 쓰리고 화끈거려요.",
    "역류": "음식이나 신물이 목으로 올라와요.",
    "연하곤란": "음식 삼키기가 힘들어요.",
    "상복부 불편감": "명치 근처가 답답하고 묵직해요.",
    "명치 통증": "명치가 아프거나 눌리면 통증이 있어요.",
    "복부 불편감": "배가 더부룩하고 불편해요.",
    "복부 팽만": "배가 부풀고 가스가 찬 느낌이에요.",
    "목 통증": "목이 뻣뻣하거나 움직일 때 아파요.",
    "등 통증": "등이 아프고 뻐근해요.",
    "등통증": "등이 결리거나 통증이 느껴져요.",
    "등/허리 통증": "허리나 등 전체가 아파요.",
    "관절통": "무릎, 어깨 등 관절이 아프거나 뻐근해요.",
    "국소 근육통": "몸의 한 부위 근육이 아파요.",
    "국소 통증": "특정 부위가 찌르듯 아파요.",
    "근육통": "운동 후처럼 근육이 뻐근하고 아파요.",
    "골통": "뼈 속이 쑤시거나 욱신거려요.",
    "이질통": "몸 한쪽이 욱신거리거나 쥐어짜는 느낌이에요.",
    "작열통": "불에 데인 것처럼 타는 통증이 있어요.",
    "압통": "누르면 아프고 눌린 느낌이에요.",
    "움직임 제한": "통증 때문에 몸을 자유롭게 움직이기 힘들어요.",
    "근력 약화": "힘이 잘 안 들어가요.",
    "팔 약화": "팔에 힘이 빠지거나 물건 들기 힘들어요.",
    "감각 이상": "피부 감각이 둔하거나 이상하게 느껴져요.",
    "저림": "손발이 저리거나 찌릿해요.",
    "전신 통증": "온몸이 쑤시고 아파요.",
    "두개골/흉부 변형": "머리나 가슴뼈 모양이 평소와 달라 보여요.",
    "뻣뻣함": "몸이 굳은 느낌이 나고 부드럽게 안 움직여요.",
    "통증": "어딘가 아프고 불편해요.",
    "발진": "피부에 붉은 점이나 부스럼이 났어요.",
    "작열감": "피부가 화끈거리거나 뜨거워요.",
    "가려움": "피부가 계속 가려워요.",
    "유방 멍울": "가슴에 덩어리나 혹 같은 게 만져져요.",
    "멍": "피부에 멍이 들었어요.",
    "시각 증상": "시야가 흐리거나 갑자기 잘 안 보여요.",
    "수면 문제": "잠이 잘 안 오거나 자주 깨요.",
    "건강 불안": "몸에 이상이 있을까 불안해요.",
    "신체 증상에 대한 집착": "몸의 증상에 지나치게 집중돼요.",
    "걱정": "별일 아닌 것도 계속 걱정돼요.",
    "플래시백": "힘들었던 기억이 갑자기 떠올라 괴로워요.",
    "골반 통증": "아랫배나 골반이 아파요.",
    "생리 문제": "생리 주기가 불규칙하거나 양상이 달라졌어요.",
    "우상복부 통증": "오른쪽 윗배가 아파요.",
    "측두부 통증": "관자놀이 쪽이 욱신거리거나 조여요.",
    "설명되지 않는 다발성 증상": "여러 군데가 아픈데 이유를 모르겠어요.",
    "추위 불내성": "조금만 추워도 몸이 심하게 떨리거나 불편해요.",
  };



  final Set<String> selectedSymptoms = {};
  final TextEditingController _controller = TextEditingController();

  Future<List<String>> _getMatchedSymptoms(String input) async {
    final allSymptoms = symptomCategories.values.expand((e) => e).toList();

    final prompt = """
    당신은 의료 전문가로서 사용자의 문장에서 증상을 추출하는 AI입니다.  
    주어진 "증상 리스트"를 우선적으로 참고하되,  
    만약 사용자의 표현이 리스트에 없는 새로운 증상이라면 의미를 보존한 자연스러운 이름으로 직접 생성해도 됩니다.
    
    규칙:
    1️⃣ 사용자의 문장에서 의학적으로 의미 있는 모든 증상을 찾아내세요.  
    2️⃣ "증상 리스트"에 존재하는 항목이 있으면 그대로 사용하세요.  
    2️⃣ 비슷한 표현이 여러 증상과 연관된다면 **모두 포함하세요.**  
   (예: "가슴이 아프다" → "흉통, 설명되지 않는 흉통, 갑작스러운 흉통")
    3️⃣ 존재하지 않으면 사용자의 문맥에 맞게 새로운 증상명을 간단하게 만들어 추가하세요.  
       - 예: "머리가 아파요" → "두통"
       - 예: "팔꿈치가 아파요" → "팔꿈치 통증"
       - 예: "가슴이 조여요" → "흉통"
    4️⃣ 결과는 쉼표(,)로 구분된 증상명 리스트 형태로만 출력합니다.  
    5️⃣ 불필요한 설명, 문장, 해석은 포함하지 마세요.  
    6️⃣ 출력은 예시처럼: "흉통, 두통, 팔꿈치 통증"
    규칙:
      
    사용자 입력:
    "$input"
    
    증상 리스트:
    ${allSymptoms.join(", ")}
    """;


    final response = await http.post(
      Uri.parse("https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent"),
      headers: {
        "Content-Type": "application/json",
        "X-goog-api-key": "AIzaSyCIYlmRYTOdfi_qOtcxHlp046oqZC-3uPI",
      },
      body: jsonEncode({
        "contents": [
          {
            "parts": [
              {"text": prompt}
            ]
          }
        ]
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      if (data["candidates"] != null &&
          data["candidates"].isNotEmpty &&
          data["candidates"][0]["content"] != null &&
          data["candidates"][0]["content"]["parts"] != null &&
          data["candidates"][0]["content"]["parts"].isNotEmpty) {
        final rawText = data["candidates"][0]["content"]["parts"][0]["text"].trim();

        // 쉼표 기준 분리 → 중복 제거
        final results = rawText.split(",").map((e) => e.trim()).toSet().toList();
        return List<String>.from(results);
      } else {
        print("⚠️ Gemini 응답 파싱 실패: ${response.body}");
        return <String>[];
      }
    } else {
      print("API Error: ${response.body}");
      return <String>[];
    }
  }
  void _showConfirmDialog(BuildContext context, List<String> matchedSymptoms) {
    final TextEditingController popupController = TextEditingController();
    final primaryColor = const Color(0xFF2E7D8A);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  gradient: LinearGradient(
                    colors: [Colors.white, const Color(0xFFF8FAFC)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: primaryColor.withOpacity(0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 제목 + 아이콘
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(Icons.check_circle, color: primaryColor, size: 24),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          "증상 확인",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: primaryColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // 선택된 증상 리스트
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: primaryColor.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: primaryColor.withOpacity(0.2)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "선택된 증상 (${selectedSymptoms.length}개)",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: primaryColor,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ...selectedSymptoms.map((symptom) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 3),
                              child: Row(
                                children: [
                                  Icon(Icons.check_circle, color: primaryColor, size: 16),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      symptom, 
                                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // 추가 입력창
                    TextField(
                      controller: popupController,
                      decoration: InputDecoration(
                        hintText: "추가 증상이 있나요?",
                        hintStyle: TextStyle(color: Colors.grey[400]),
                        prefixIcon: Icon(Icons.add_comment, color: primaryColor),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: primaryColor.withOpacity(0.3)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: Colors.grey.withOpacity(0.3)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: primaryColor, width: 2),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // 버튼 영역
                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(color: Colors.grey.withOpacity(0.3)),
                              ),
                            ),
                            onPressed: () {
                              Navigator.pop(context); // 팝업 닫기
                              
                            },
                            child: Text(
                              "없습니다",
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryColor,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              elevation: 2,
                            ),
                            onPressed: () async {
                              final newInput = popupController.text.trim();
                              if (newInput.isNotEmpty) {
                                final newMatches = await _getMatchedSymptoms(newInput);
                                if (newMatches.isNotEmpty) {
                                  setState(() {
                                    selectedSymptoms.addAll(newMatches);
                                  });
                                  setStateDialog(() {}); // 팝업 UI 갱신
                                  popupController.clear();
                                }
                              }
                            },
                            child: const Text(
                              "추가 입력",
                              style: TextStyle(
                                color: Colors.white, 
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    )
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }





  void _matchSymptoms(String input) async {
    if (input.trim().isEmpty) return;

    final matchedSymptoms = await _getMatchedSymptoms(input);

    if (matchedSymptoms.isNotEmpty) {
      setState(() {
        selectedSymptoms.addAll(matchedSymptoms);
      });

      _showConfirmDialog(context, matchedSymptoms); // ✅ 팝업 띄우기
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("증상을 매칭하지 못했습니다.")),
      );
    }

    _controller.clear();
  }



  @override
  Widget build(BuildContext context) {
    final primaryColor = const Color(0xFF2E7D8A); // 의료 테마 색상
    final secondaryColor = const Color(0xFF4A90A4);
    final accentColor = const Color(0xFF7FB3D3);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
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
          "증상 입력 / 선택", 
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
        child: Column(
          children: [
            // AI 기반 증상 매칭 시스템 안내
            

            // 증상 입력 섹션
            Container(
              width: double.infinity,
              margin: const EdgeInsets.symmetric(horizontal: 16),
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
                  // 섹션 제목
                  Row(
                    children: [
                      Icon(
                        Icons.edit_note,
                        color: primaryColor,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "가슴이 아픈게 어떻게 아프시고 관련된 증상이 더 있나요",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: primaryColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // 입력창
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: primaryColor.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: TextField(
                      controller: _controller,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: "예: 가슴이 아프고 숨이 차요, 어지럽고 피곤해요",
                        hintStyle: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 14,
                        ),
                        prefixIcon: Icon(Icons.medical_services, color: primaryColor),
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
                  
                  const SizedBox(height: 16),
                  
                  // 확인 버튼
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        elevation: 2,
                      ),
                      onPressed: () => _matchSymptoms(_controller.text),
                      icon: const Icon(
                        Icons.auto_awesome,
                        color: Colors.white,
                        size: 20,
                      ),
                      label: const Text(
                        "AI로 증상 분석하기",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // 증상 카테고리 선택 안내
            Container(
              width: double.infinity,
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.blue.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.list_alt,
                    color: Colors.blue[600],
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      "또는 아래 카테고리에서 직접 선택하세요",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.blue[700],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),
            
            // 증상 체크리스트
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: symptomCategories.entries.map((entry) {
                final hasSelected = entry.value.any((s) => selectedSymptoms.contains(s));

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: hasSelected 
                          ? primaryColor.withOpacity(0.15)
                          : Colors.grey.withOpacity(0.1),
                        blurRadius: hasSelected ? 12 : 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                    border: hasSelected 
                      ? Border.all(color: primaryColor.withOpacity(0.3), width: 1.5)
                      : null,
                  ),
                  child: ExpansionTile(
                    tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    childrenPadding: const EdgeInsets.only(bottom: 8),
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: hasSelected 
                          ? primaryColor.withOpacity(0.1)
                          : Colors.grey.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        hasSelected ? Icons.check_circle : Icons.medical_information,
                        color: hasSelected ? primaryColor : Colors.grey[600],
                        size: 24,
                      ),
                    ),
                    title: Text(
                      entry.key,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        color: hasSelected ? primaryColor : Colors.grey[800],
                      ),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        symptomCategoryDescriptions[entry.key] ?? "",
                        style: TextStyle(
                          color: Colors.grey[600], 
                          fontSize: 13,
                          height: 1.3,
                        ),
                      ),
                    ),
                    children: entry.value.map((symptom) {
                      final isSelected = selectedSymptoms.contains(symptom);
                      final hasDescription = symptomDescriptions.containsKey(symptom);

                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: isSelected 
                            ? primaryColor.withOpacity(0.08)
                            : Colors.grey.withOpacity(0.03),
                          borderRadius: BorderRadius.circular(12),
                          border: isSelected 
                            ? Border.all(color: primaryColor.withOpacity(0.2), width: 1)
                            : null,
                        ),
                        child: Column(
                          children: [
                            CheckboxListTile(
                              activeColor: primaryColor,
                              checkColor: Colors.white,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                              title: Text(
                                symptom,
                                style: TextStyle(
                                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                                  color: isSelected ? primaryColor : Colors.grey[800],
                                  fontSize: 15,
                                ),
                              ),
                              value: isSelected,
                              onChanged: (checked) {
                                setState(() {
                                  if (checked!) {
                                    selectedSymptoms.add(symptom);
                                  } else {
                                    selectedSymptoms.remove(symptom);
                                  }
                                });
                              },
                            ),
                            // ✅ 설명이 있으면 바로 표시
                            if (hasDescription)
                              Container(
                                margin: const EdgeInsets.only(left: 16, right: 16, bottom: 12),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.blue[50],
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: accentColor.withOpacity(0.3)),
                                ),
                                child: Text(
                                  symptomDescriptions[symptom] ?? "",
                                  style: TextStyle(
                                    color: Colors.grey[700], 
                                    fontSize: 12,
                                    height: 1.4,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      );
                    }).toList(),

                  ),
                );
              }).toList(),
              ),
            ),
            
            const SizedBox(height: 100), // 하단 네비게이션 바 공간 확보
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                elevation: selectedSymptoms.isEmpty ? 0 : 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: EdgeInsets.zero,
                backgroundColor: selectedSymptoms.isEmpty 
                  ? Colors.grey[300] 
                  : null,
              ).copyWith(
                backgroundColor: WidgetStateProperty.resolveWith<Color?>((states) {
                  if (selectedSymptoms.isEmpty) return Colors.grey[300];
                  return null;
                }),
              ),
              onPressed: selectedSymptoms.isEmpty
                  ? null
                  : () {
                print("✅ 선택된 증상 리스트: $selectedSymptoms");
                
              },
              child: selectedSymptoms.isEmpty
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.info_outline, color: Colors.grey[600], size: 20),
                      const SizedBox(width: 8),
                      Text(
                        "증상을 선택해주세요",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  )
                : Ink(
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
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.arrow_forward,
                            color: Colors.white,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            "다음 단계로 (${selectedSymptoms.length}개 선택됨)",
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
      ),
    );
  }
}