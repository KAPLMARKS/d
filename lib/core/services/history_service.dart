import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class HistoryService {
  static HistoryService? _instance;
  late SharedPreferences _prefs;

  HistoryService._();

  static HistoryService get instance {
    _instance ??= HistoryService._();
    return _instance!;
  }

  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
  }

  Future<void> addMeditationEntry(HistoryEntry entry) async {
    final entries = getMeditationEntries();
    entries.insert(0, entry);
    await _prefs.setString(
      'meditation_history',
      jsonEncode(entries.map((e) => e.toJson()).toList()),
    );
  }

  List<HistoryEntry> getMeditationEntries() {
    final data = _prefs.getString('meditation_history');
    if (data == null) return [];
    final list = jsonDecode(data) as List;
    return list.map((e) => HistoryEntry.fromJson(e)).toList();
  }

  Future<void> addBreathingEntry(HistoryEntry entry) async {
    final entries = getBreathingEntries();
    entries.insert(0, entry);
    await _prefs.setString(
      'breathing_history',
      jsonEncode(entries.map((e) => e.toJson()).toList()),
    );
  }

  List<HistoryEntry> getBreathingEntries() {
    final data = _prefs.getString('breathing_history');
    if (data == null) return [];
    final list = jsonDecode(data) as List;
    return list.map((e) => HistoryEntry.fromJson(e)).toList();
  }

  Future<void> deleteEntry(String id, {required bool isMeditation}) async {
    if (isMeditation) {
      final entries = getMeditationEntries();
      entries.removeWhere((e) => e.id == id);
      await _prefs.setString(
        'meditation_history',
        jsonEncode(entries.map((e) => e.toJson()).toList()),
      );
    } else {
      final entries = getBreathingEntries();
      entries.removeWhere((e) => e.id == id);
      await _prefs.setString(
        'breathing_history',
        jsonEncode(entries.map((e) => e.toJson()).toList()),
      );
    }
  }

}

class HistoryEntry {
  final String id;
  final String title;
  final String goal;
  final int durationMinutes;
  final DateTime date;
  final String type;

  HistoryEntry({
    required this.id,
    required this.title,
    required this.goal,
    required this.durationMinutes,
    required this.date,
    required this.type,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'goal': goal,
        'durationMinutes': durationMinutes,
        'date': date.toIso8601String(),
        'type': type,
      };

  factory HistoryEntry.fromJson(Map<String, dynamic> json) => HistoryEntry(
        id: json['id'],
        title: json['title'],
        goal: json['goal'],
        durationMinutes: json['durationMinutes'],
        date: DateTime.parse(json['date']),
        type: json['type'],
      );
}
