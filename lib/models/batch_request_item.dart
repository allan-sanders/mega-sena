class TierDistributionRule {
  final int dozensCount;
  final int hotCount;      // q: Mais sorteados
  final int moderateCount; // m: Moderados
  final int coldCount;     // b: Menos sorteados

  const TierDistributionRule({
    required this.dozensCount,
    required this.hotCount,
    required this.moderateCount,
    required this.coldCount,
  }) : assert(hotCount + moderateCount + coldCount == dozensCount);

  String get label => '${hotCount}Q • ${moderateCount}M • ${coldCount}F';
}

class BatchRequestItem {
  int dozensCount;
  int gamesQuantity;

  BatchRequestItem({
    required this.dozensCount,
    required this.gamesQuantity,
  });
}
