class XpEntry {
  const XpEntry({
    required this.id,
    required this.taskId,
    required this.amount,
    required this.earnedAt,
  }) : assert(amount > 0);

  final String id;
  final String taskId;
  final int amount;
  final DateTime earnedAt;

  Map<String, Object?> toJson() => {
        'id': id,
        'taskId': taskId,
        'amount': amount,
        'earnedAt': earnedAt.toIso8601String(),
      };

  factory XpEntry.fromJson(Map<String, dynamic> json) => XpEntry(
        id: json['id'] as String,
        taskId: json['taskId'] as String,
        amount: json['amount'] as int,
        earnedAt: DateTime.parse(json['earnedAt'] as String),
      );
}
