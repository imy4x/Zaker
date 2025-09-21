import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zaker/models/study_session.dart';

class StorageService {
  static const _sessionsKey = 'study_sessions_list_v2';

  Future<void> saveSessions(List<StudySession> sessions) async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> sessionsJson = sessions.map((s) => jsonEncode(s.toJson())).toList();
    await prefs.setStringList(_sessionsKey, sessionsJson);
  }

  Future<List<StudySession>> getSessions() async {
    final prefs = await SharedPreferences.getInstance();
    final sessionsJson = prefs.getStringList(_sessionsKey);
    if (sessionsJson != null) {
      try {
        return sessionsJson.map((s) => StudySession.fromJson(jsonDecode(s))).toList();
      } catch (e) {
        print("Error decoding sessions: $e. Clearing old data.");
        await prefs.remove(_sessionsKey); // Clear corrupted data
        return [];
      }
    }
    return []; // إرجاع قائمة فارغة إذا لم توجد جلسات مخزنة
  }
}
