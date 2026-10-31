import 'draw_result.dart';

enum NumberTier {
  hot,      // Mais sorteados (30% -> 18 dezenas)
  moderate, // Moderados (40% -> 24 dezenas)
  cold,     // Menos sorteados (30% -> 18 dezenas)
}

class FrequencyStats {
  /// Mapa de dezena (1..60) -> quantidade de vezes sorteada nos últimos 100 jogos
  final Map<int, int> frequencies;

  /// As 18 dezenas mais sorteadas (30%)
  final List<int> hotNumbers;

  /// As 24 dezenas intermediárias (40%)
  final List<int> moderateNumbers;

  /// As 18 dezenas menos sorteadas (30%)
  final List<int> coldNumbers;

  /// Último concurso considerado na sincronização
  final int latestContestNumber;

  /// Quantidade de concursos analisados (meta: 100)
  final int totalDrawsAnalyzed;

  /// Data/hora em que a sincronização ocorreu
  final DateTime syncedAt;

  const FrequencyStats({
    required this.frequencies,
    required this.hotNumbers,
    required this.moderateNumbers,
    required this.coldNumbers,
    required this.latestContestNumber,
    required this.totalDrawsAnalyzed,
    required this.syncedAt,
  });

  NumberTier getTierForNumber(int number) {
    if (hotNumbers.contains(number)) return NumberTier.hot;
    if (moderateNumbers.contains(number)) return NumberTier.moderate;
    return NumberTier.cold;
  }

  /// Calcula as frequências e divide exatamente em 18 (30%), 24 (40%) e 18 (30%)
  /// usando critério de desempate determinístico (quem saiu mais recentemente e depois número da dezena).
  factory FrequencyStats.fromDraws(List<DrawResult> draws, {DateTime? syncTime}) {
    final Map<int, int> counts = {for (int n = 1; n <= 60; n++) n: 0};
    final Map<int, int> lastSeenContest = {for (int n = 1; n <= 60; n++) n: 0};

    int latestContest = 0;
    for (final draw in draws) {
      if (draw.contestNumber > latestContest) {
        latestContest = draw.contestNumber;
      }
      for (final n in draw.numbers) {
        if (n >= 1 && n <= 60) {
          counts[n] = (counts[n] ?? 0) + 1;
          if (draw.contestNumber > (lastSeenContest[n] ?? 0)) {
            lastSeenContest[n] = draw.contestNumber;
          }
        }
      }
    }

    final List<int> allNumbers = List.generate(60, (i) => i + 1);
    allNumbers.sort((a, b) {
      final freqCompare = (counts[b] ?? 0).compareTo(counts[a] ?? 0);
      if (freqCompare != 0) return freqCompare;
      // Desempate 1: saiu em concurso mais recente
      final recentCompare = (lastSeenContest[b] ?? 0).compareTo(lastSeenContest[a] ?? 0);
      if (recentCompare != 0) return recentCompare;
      // Desempate 2: menor número da dezena
      return a.compareTo(b);
    });

    // 30% de 60 = 18 dezenas mais sorteadas
    final hot = allNumbers.sublist(0, 18)..sort();
    // 40% de 60 = 24 dezenas moderadas
    final moderate = allNumbers.sublist(18, 42)..sort();
    // 30% de 60 = 18 dezenas menos sorteadas
    final cold = allNumbers.sublist(42, 60)..sort();

    return FrequencyStats(
      frequencies: counts,
      hotNumbers: hot,
      moderateNumbers: moderate,
      coldNumbers: cold,
      latestContestNumber: latestContest,
      totalDrawsAnalyzed: draws.length,
      syncedAt: syncTime ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'frequencies': frequencies.map((k, v) => MapEntry(k.toString(), v)),
        'hotNumbers': hotNumbers,
        'moderateNumbers': moderateNumbers,
        'coldNumbers': coldNumbers,
        'latestContestNumber': latestContestNumber,
        'totalDrawsAnalyzed': totalDrawsAnalyzed,
        'syncedAt': syncedAt.toIso8601String(),
      };

  factory FrequencyStats.fromJson(Map<String, dynamic> json) {
    final rawFreq = json['frequencies'] as Map<String, dynamic>;
    return FrequencyStats(
      frequencies: rawFreq.map((k, v) => MapEntry(int.parse(k), v as int)),
      hotNumbers: (json['hotNumbers'] as List<dynamic>).map((e) => e as int).toList(),
      moderateNumbers: (json['moderateNumbers'] as List<dynamic>).map((e) => e as int).toList(),
      coldNumbers: (json['coldNumbers'] as List<dynamic>).map((e) => e as int).toList(),
      latestContestNumber: json['latestContestNumber'] as int,
      totalDrawsAnalyzed: json['totalDrawsAnalyzed'] as int,
      syncedAt: DateTime.parse(json['syncedAt'] as String),
    );
  }
}
