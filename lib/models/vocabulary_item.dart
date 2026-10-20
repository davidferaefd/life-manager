class VocabularyItem {
  const VocabularyItem({
    required this.id,
    required this.term,
    required this.translation,
    required this.createdAt,
    this.lastReviewedAt,
    this.reviewCount = 0,
  })  : assert(reviewCount >= 0),
        assert(term != ''),
        assert(translation != '');

  final String id;
  final String term;
  final String translation;
  final DateTime createdAt;
  final DateTime? lastReviewedAt;
  final int reviewCount;

  Map<String, Object?> toJson() => {
        'id': id,
        'term': term,
        'translation': translation,
        'createdAt': createdAt.toIso8601String(),
        'lastReviewedAt': lastReviewedAt?.toIso8601String(),
        'reviewCount': reviewCount,
      };

  factory VocabularyItem.fromJson(Map<String, dynamic> json) => VocabularyItem(
        id: json['id'] as String,
        term: json['term'] as String,
        translation: json['translation'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
        lastReviewedAt: json['lastReviewedAt'] == null
            ? null
            : DateTime.parse(json['lastReviewedAt'] as String),
        reviewCount: json['reviewCount'] as int? ?? 0,
      );
}
