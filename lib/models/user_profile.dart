class UserProfile {
  const UserProfile({
    this.displayName = 'Minha jornada',
    this.totalXp = 0,
    this.currentStreak = 0,
    this.lastActiveDate,
  })  : assert(totalXp >= 0),
        assert(currentStreak >= 0);

  final String displayName;
  final int totalXp;
  final int currentStreak;
  final String? lastActiveDate;

  int get level => totalXp ~/ 100 + 1;

  int get xpInCurrentLevel => totalXp % 100;

  String get levelTitle {
    if (level < 2) return 'Novato';
    if (level < 5) return 'Produtivo';
    if (level < 10) return 'Consistente';
    return 'Imparável';
  }

  UserProfile copyWith({
    String? displayName,
    int? totalXp,
    int? currentStreak,
    String? lastActiveDate,
    bool clearLastActiveDate = false,
  }) {
    return UserProfile(
      displayName: displayName ?? this.displayName,
      totalXp: totalXp ?? this.totalXp,
      currentStreak: currentStreak ?? this.currentStreak,
      lastActiveDate:
          clearLastActiveDate ? null : lastActiveDate ?? this.lastActiveDate,
    );
  }

  Map<String, Object?> toJson() => {
        'displayName': displayName,
        'totalXp': totalXp,
        'currentStreak': currentStreak,
        'lastActiveDate': lastActiveDate,
      };

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
        displayName: json['displayName'] as String? ?? 'Minha jornada',
        totalXp: json['totalXp'] as int? ?? 0,
        currentStreak: json['currentStreak'] as int? ?? 0,
        lastActiveDate: json['lastActiveDate'] as String?,
      );
}
