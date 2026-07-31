import 'package:flutter/material.dart';
import '../data/block_model.dart';
import '../data/block_repository.dart';

class BlockController extends ChangeNotifier {
  static final BlockController instance = BlockController();
  final BlockRepository _repository = BlockRepository();

  List<BlockRuleModel> rules = [];
  List<BlockHistoryModel> history = [];
  int selectedChipIndex = 0;
  String? errorMessage;
  bool isInitialized = false;

  int get rulesCount => rules.length;
  int get historyCount => history.length;

  String get hintText {
    switch (selectedChipIndex) {
      case 0:
        return 'e.g., +15551234567';
      case 1:
        return 'e.g., +1800 or 140';
      case 2:
        return 'e.g., 91 or 1';
      case 3:
        return 'e.g., Spam or Telemarketer';
      default:
        return 'Enter value';
    }
  }

  String get infoTitle {
    switch (selectedChipIndex) {
      case 0:
        return 'Block Exact Number';
      case 1:
        return 'Block Series (Starts With)';
      case 2:
        return 'Block Country Code';
      case 3:
        return 'Block by Caller Name';
      default:
        return '';
    }
  }

  String get infoDesc {
    switch (selectedChipIndex) {
      case 0:
        return 'Blocks incoming calls matching this exact phone number.';
      case 1:
        return 'Blocks all incoming calls starting with this specific digit series.';
      case 2:
        return 'Blocks all incoming calls originating from this country code.';
      case 3:
        return 'Blocks calls if the identified caller name contains this keyword.';
      default:
        return '';
    }
  }

  TextInputType get inputType {
    if (selectedChipIndex == 3) {
      return TextInputType.text;
    }
    return TextInputType.phone;
  }

  int get maxLength {
    switch (selectedChipIndex) {
      case 0:
        return 20;
      case 1:
        return 15;
      case 2:
        return 5;
      case 3:
        return 20;
      default:
        return 20;
    }
  }

  Future<void> init() async {
    rules = await _repository.getRules();
    history = await _repository.getHistory();
    isInitialized = true;
    notifyListeners();
  }

  void setChipIndex(int index) {
    if (selectedChipIndex != index) {
      selectedChipIndex = index;
      errorMessage = null;
      notifyListeners();
    }
  }

  void clearError() {
    if (errorMessage != null) {
      errorMessage = null;
      notifyListeners();
    }
  }

  Future<bool> addRule(String rawInput) async {
    final inputValue = rawInput.trim();
    clearError();

    if (inputValue.isEmpty) {
      errorMessage = 'Please enter a value';
      notifyListeners();
      return false;
    }

    final isDuplicate = rules.any((r) =>
        r.ruleType == selectedChipIndex &&
        r.ruleValue.toLowerCase() == inputValue.toLowerCase());

    if (isDuplicate) {
      errorMessage = 'Already in blocklist';
      notifyListeners();
      return false;
    }

    final newRule = BlockRuleModel(
      id: DateTime.now().millisecondsSinceEpoch,
      ruleValue: inputValue,
      ruleType: selectedChipIndex,
      timestamp: DateTime.now().millisecondsSinceEpoch,
    );

    await _repository.insertRule(newRule);
    rules = await _repository.getRules();
    notifyListeners();
    return true;
  }

  Future<void> deleteRule(int id) async {
    await _repository.deleteRule(id);
    rules = await _repository.getRules();
    notifyListeners();
  }

  Future<void> clearHistory() async {
    await _repository.clearHistory();
    history = await _repository.getHistory();
    notifyListeners();
  }
}
