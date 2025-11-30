// session_manager.dart
// 세션 ID를 서버에서 받아서 저장하고 관리하는 유틸리티

class SessionManager {
  static String? _sessionId;

  // 세션 ID 가져오기 (서버에서 받은 세션 ID 반환, 없으면 null)
  static String? getSessionId() {
    return _sessionId;
  }

  // 서버에서 받은 세션 ID 저장 (이미 있으면 저장하지 않음)
  static void setSessionId(String sessionId) {
    if (sessionId.isEmpty) return;
    
    // 이미 같은 세션 ID가 저장되어 있으면 저장하지 않음
    if (_sessionId == sessionId) {
      return;
    }
    
    _sessionId = sessionId;
    print('✅ 세션 ID 저장: $sessionId');
  }

  // 응답 헤더에서 세션 ID 추출 및 저장 (없을 때만)
  static void saveSessionIdFromResponse(Map<String, String> headers) {
    // HTTP 헤더는 대소문자 구분이 없으므로 여러 형식 확인
    final sessionId = headers['x-session-id'] ?? 
                      headers['X-Session-Id'] ?? 
                      headers['X-SESSION-ID'];
    
    if (sessionId != null && sessionId.isNotEmpty) {
      setSessionId(sessionId); // 내부에서 중복 체크
    }
  }

  // 세션 초기화 (새로운 검진 시작 시 사용)
  static void resetSession() {
    _sessionId = null;
  }

  // 현재 세션 ID 반환 (디버깅용)
  static String? getCurrentSessionId() {
    return _sessionId;
  }
}

