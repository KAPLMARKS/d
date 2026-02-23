import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class FavoritesService {
  static FavoritesService? _instance;
  late SharedPreferences _prefs;

  FavoritesService._();

  static FavoritesService get instance {
    _instance ??= FavoritesService._();
    return _instance!;
  }

  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
  }

  Future<void> addFavorite(FavoriteMeditation fav) async {
    final list = getFavorites();
    list.insert(0, fav);
    await _save(list);
  }

  Future<void> removeFavorite(String id) async {
    final list = getFavorites();
    list.removeWhere((f) => f.id == id);
    await _save(list);
  }

  Future<void> toggleFavorite(FavoriteMeditation fav) async {
    if (isFavorite(fav.id)) {
      await removeFavorite(fav.id);
    } else {
      await addFavorite(fav);
    }
  }

  bool isFavorite(String id) {
    return getFavorites().any((f) => f.id == id);
  }

  List<FavoriteMeditation> getFavorites() {
    final data = _prefs.getString('favorite_meditations');
    if (data == null) return [];
    final list = jsonDecode(data) as List;
    return list.map((e) => FavoriteMeditation.fromJson(e)).toList();
  }

  Future<void> _save(List<FavoriteMeditation> list) async {
    await _prefs.setString(
      'favorite_meditations',
      jsonEncode(list.map((e) => e.toJson()).toList()),
    );
  }
}

class FavoriteMeditation {
  final String id;
  final String title;
  final String description;
  final String script;
  final String duration;
  final String goal;
  final String sound;
  final String voiceStyle;
  final DateTime date;

  FavoriteMeditation({
    required this.id,
    required this.title,
    required this.description,
    required this.script,
    required this.duration,
    required this.goal,
    required this.sound,
    required this.voiceStyle,
    required this.date,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'script': script,
        'duration': duration,
        'goal': goal,
        'sound': sound,
        'voiceStyle': voiceStyle,
        'date': date.toIso8601String(),
      };

  factory FavoriteMeditation.fromJson(Map<String, dynamic> json) =>
      FavoriteMeditation(
        id: json['id'],
        title: json['title'],
        description: json['description'],
        script: json['script'] ?? '',
        duration: json['duration'],
        goal: json['goal'],
        sound: json['sound'] ?? '',
        voiceStyle: json['voiceStyle'] ?? '',
        date: DateTime.parse(json['date']),
      );
}
