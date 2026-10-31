import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/bet_game.dart';
import '../models/frequency_stats.dart';

class StorageService {
  static const String _keyUserProfile = 'megasena_user_profile_v1';
  static const String _keyFrequencyStats = 'megasena_frequency_stats_v1';
  static const String _keySavedGames = 'megasena_saved_games_v1';

  Future<void> saveUserProfile(Map<String, String> user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUserProfile, jsonEncode(user));
  }

  Future<Map<String, String>?> loadUserProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyUserProfile);
    if (raw == null) return null;
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    return decoded.map((k, v) => MapEntry(k, v.toString()));
  }

  Future<void> clearUserProfile() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyUserProfile);
  }

  Future<void> saveFrequencyStats(FrequencyStats stats) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyFrequencyStats, jsonEncode(stats.toJson()));
  }

  Future<FrequencyStats?> loadFrequencyStats() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyFrequencyStats);
    if (raw == null) return null;
    try {
      return FrequencyStats.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<void> saveGames(List<BetGame> games) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(games.map((g) => g.toJson()).toList());
    await prefs.setString(_keySavedGames, encoded);
  }

  Future<List<BetGame>> loadGames() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keySavedGames);
    if (raw == null) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((item) => BetGame.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// Apaga todos os jogos atuais quando o usuário solicita um Novo Jogo
  Future<void> clearGames() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keySavedGames);
  }
}
