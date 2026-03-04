// lib/features/ai/data/datasources/ai_local_datasource.dart
import 'dart:convert';
import 'package:hive/hive.dart';

class AiLocalDataSource {
  static const _boxName = "ai_wait_stats";
  static const _loggedEntriesBox = "logged_entries";

  Future<Box> _statsBox() async => await Hive.openBox(_boxName);
  Future<Box> _loggedBox() async => await Hive.openBox(_loggedEntriesBox);

  Future<Map<String, dynamic>?> getStatsJson(String serviceId) async {
    try {
      final box = await _statsBox();
      final raw = box.get(serviceId);
      if (raw == null) return null;
      return jsonDecode(raw as String) as Map<String, dynamic>;
    } catch (e) {
      return null;
    }
  }

  Future<void> saveStatsJson(
    String serviceId,
    Map<String, dynamic> json,
  ) async {
    try {
      final box = await _statsBox();
      await box.put(serviceId, jsonEncode(json));
    } catch (e) {
      // Silent fail for now
    }
  }

  Future<bool> wasEntryLogged(String entryId) async {
    try {
      final box = await _loggedBox();
      return box.get(entryId) == true;
    } catch (e) {
      return false;
    }
  }

  Future<void> markEntryLogged(String entryId) async {
    try {
      final box = await _loggedBox();
      await box.put(entryId, true);
    } catch (e) {
      // Silent fail
    }
  }

  Future<void> clearAll() async {
    try {
      final statsBox = await _statsBox();
      final loggedBox = await _loggedBox();
      await statsBox.clear();
      await loggedBox.clear();
    } catch (e) {
      // Silent fail
    }
  }
}
