import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zaker/models/study_list.dart';
import 'package:zaker/models/study_session.dart';

class StorageService {
  static const _sessionsKey = 'study_sessions_list_v3';
  static const _listsKey = 'study_lists_v1';

  // --- دوال الجلسات ---
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
        await prefs.remove(_sessionsKey);
        return [];
      }
    }
    return [];
  }

  // --- دوال القوائم ---
  Future<void> saveLists(List<StudyList> lists) async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> listsJson = lists.map((l) => jsonEncode(l.toJson())).toList();
    await prefs.setStringList(_listsKey, listsJson);
  }

  Future<List<StudyList>> getLists() async {
    final prefs = await SharedPreferences.getInstance();
    final listsJson = prefs.getStringList(_listsKey);
    if (listsJson != null) {
      try {
        return listsJson.map((l) => StudyList.fromJson(jsonDecode(l))).toList();
      } catch (e) {
        print("Error decoding lists: $e. Clearing old data.");
        await prefs.remove(_listsKey);
        return [];
      }
    }
    return [];
  }
}

