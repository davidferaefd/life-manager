import 'life_task.dart';
import 'user_profile.dart';
import 'vocabulary_item.dart';
import 'xp_entry.dart';

class AppData {
  AppData({
    required this.profile,
    required List<LifeTask> tasks,
    required List<XpEntry> xpHistory,
    required List<VocabularyItem> vocabulary,
  })  : tasks = List.unmodifiable(tasks),
        xpHistory = List.unmodifiable(xpHistory),
        vocabulary = List.unmodifiable(vocabulary);

  factory AppData.empty() => AppData(
        profile: const UserProfile(),
        tasks: const [],
        xpHistory: const [],
        vocabulary: const [],
      );

  final UserProfile profile;
  final List<LifeTask> tasks;
  final List<XpEntry> xpHistory;
  final List<VocabularyItem> vocabulary;

  Map<String, Object?> toJson() => {
        'profile': profile.toJson(),
        'tasks': tasks.map((task) => task.toJson()).toList(),
        'xpHistory': xpHistory.map((entry) => entry.toJson()).toList(),
        'vocabulary': vocabulary.map((item) => item.toJson()).toList(),
      };

  factory AppData.fromJson(Map<String, dynamic> json) => AppData(
        profile: UserProfile.fromJson(
          Map<String, dynamic>.from(json['profile'] as Map),
        ),
        tasks: _decodeList(json['tasks'], LifeTask.fromJson),
        xpHistory: _decodeList(json['xpHistory'], XpEntry.fromJson),
        vocabulary: _decodeList(json['vocabulary'], VocabularyItem.fromJson),
      );

  static List<T> _decodeList<T>(
    Object? value,
    T Function(Map<String, dynamic>) decode,
  ) {
    if (value is! List) {
      throw const FormatException('A lista de dados locais está inválida.');
    }
    return value
        .map((item) => decode(Map<String, dynamic>.from(item as Map)))
        .toList();
  }
}
