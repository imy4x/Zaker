import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zaker/models/study_session.dart';

// خدمة جديدة لإدارة التخزين المحلي
class StorageService {
  Future<void> saveSession(int slotIndex, StudySession session) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = jsonEncode(session.toJson());
    await prefs.setString('session_$slotIndex', jsonString);
  }

  Future<StudySession?> getSession(int slotIndex) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString('session_$slotIndex');
    if (jsonString != null) {
      return StudySession.fromJson(jsonDecode(jsonString));
    }
    return null;
  }

  Future<void> deleteSession(int slotIndex) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('session_$slotIndex');
  }
}
