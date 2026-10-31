class BetGame {
  final String id;
  final int sequenceNumber;
  final int dozensCount;
  final List<int> numbers;
  final bool isCompleted;
  final DateTime createdAt;

  const BetGame({
    required this.id,
    required this.sequenceNumber,
    required this.dozensCount,
    required this.numbers,
    this.isCompleted = false,
    required this.createdAt,
  });

  BetGame copyWith({
    bool? isCompleted,
  }) {
    return BetGame(
      id: id,
      sequenceNumber: sequenceNumber,
      dozensCount: dozensCount,
      numbers: numbers,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt,
    );
  }

  /// Assinatura única das dezenas ordenadas para garantir que não existam jogos repetidos
  String get combinationKey {
    final sorted = List<int>.from(numbers)..sort();
    return sorted.map((n) => n.toString().padLeft(2, '0')).join('-');
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'sequenceNumber': sequenceNumber,
        'dozensCount': dozensCount,
        'numbers': numbers,
        'isCompleted': isCompleted,
        'createdAt': createdAt.toIso8601String(),
      };

  factory BetGame.fromJson(Map<String, dynamic> json) {
    return BetGame(
      id: json['id'] as String,
      sequenceNumber: json['sequenceNumber'] as int,
      dozensCount: json['dozensCount'] as int,
      numbers: (json['numbers'] as List<dynamic>).map((e) => e as int).toList(),
      isCompleted: json['isCompleted'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}
