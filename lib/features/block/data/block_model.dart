class BlockRuleModel {
  final int id;
  final String ruleValue;
  final int ruleType;
  final int timestamp;

  BlockRuleModel({
    required this.id,
    required this.ruleValue,
    required this.ruleType,
    required this.timestamp,
  });

  String get ruleTypeName {
    switch (ruleType) {
      case 0:
        return 'Exact Number';
      case 1:
        return 'Starts With';
      case 2:
        return 'Country Code';
      case 3:
        return 'Caller Name';
      default:
        return 'Unknown';
    }
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'ruleValue': ruleValue,
        'ruleType': ruleType,
        'timestamp': timestamp,
      };

  factory BlockRuleModel.fromJson(Map<String, dynamic> json) => BlockRuleModel(
        id: json['id'] as int,
        ruleValue: json['ruleValue'] as String,
        ruleType: json['ruleType'] as int,
        timestamp: json['timestamp'] as int,
      );
}

class BlockHistoryModel {
  final int id;
  final String blockedNumber;
  final String? name;
  final int ruleType;
  final String? ruleValue;
  final String? reason;
  final int timestamp;

  BlockHistoryModel({
    required this.id,
    required this.blockedNumber,
    this.name,
    required this.ruleType,
    this.ruleValue,
    this.reason,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'blockedNumber': blockedNumber,
        'name': name,
        'ruleType': ruleType,
        'ruleValue': ruleValue,
        'reason': reason,
        'timestamp': timestamp,
      };

  factory BlockHistoryModel.fromJson(Map<String, dynamic> json) =>
      BlockHistoryModel(
        id: json['id'] as int,
        blockedNumber: json['blockedNumber'] as String,
        name: json['name'] as String?,
        ruleType: json['ruleType'] as int? ?? -1,
        ruleValue: json['ruleValue'] as String?,
        reason: json['reason'] as String?,
        timestamp: json['timestamp'] as int,
      );
}
