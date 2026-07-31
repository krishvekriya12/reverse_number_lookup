import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'block_model.dart';

class BlockRepository {
  static const String _rulesKey = 'block_rules_list';
  static const String _historyKey = 'block_history_list';

  Future<List<BlockRuleModel>> getRules() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList(_rulesKey) ?? [];
      return list
          .map((e) => BlockRuleModel.fromJson(jsonDecode(e)))
          .toList()
        ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    } catch (_) {
      return [];
    }
  }

  Future<void> insertRule(BlockRuleModel rule) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final rules = await getRules();
      rules.removeWhere(
          (e) => e.ruleType == rule.ruleType && e.ruleValue.toLowerCase() == rule.ruleValue.toLowerCase());
      rules.insert(0, rule);
      final encoded = rules.map((e) => jsonEncode(e.toJson())).toList();
      await prefs.setStringList(_rulesKey, encoded);
    } catch (_) {}
  }

  Future<void> deleteRule(int id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final rules = await getRules();
      rules.removeWhere((e) => e.id == id);
      final encoded = rules.map((e) => jsonEncode(e.toJson())).toList();
      await prefs.setStringList(_rulesKey, encoded);
    } catch (_) {}
  }

  Future<List<BlockHistoryModel>> getHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList(_historyKey) ?? [];
      return list
          .map((e) => BlockHistoryModel.fromJson(jsonDecode(e)))
          .toList()
        ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    } catch (_) {
      return [];
    }
  }

  Future<void> recordBlockedCall(BlockHistoryModel entry) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final history = await getHistory();
      history.insert(0, entry);
      final encoded = history.map((e) => jsonEncode(e.toJson())).toList();
      await prefs.setStringList(_historyKey, encoded);
    } catch (_) {}
  }

  Future<void> clearHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_historyKey);
    } catch (_) {}
  }
}
