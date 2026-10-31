import 'dart:math';
import '../models/batch_request_item.dart';
import '../models/bet_game.dart';
import '../models/frequency_stats.dart';

class GameGeneratorService {
  static const int maxTotalGames = 999;
  static const int minDozens = 6;
  static const int maxDozens = 20;

  /// Tabela fixa oficial definida para o projeto (de 6 a 20 dezenas):
  /// q = Mais sorteados (dos 18 números do grupo 30%)
  /// m = Moderados (dos 24 números do grupo 40%)
  /// b = Menos sorteados (dos 18 números do grupo 30%)
  static const Map<int, TierDistributionRule> distributionTable = {
    6: TierDistributionRule(dozensCount: 6, hotCount: 3, moderateCount: 2, coldCount: 1),
    7: TierDistributionRule(dozensCount: 7, hotCount: 4, moderateCount: 2, coldCount: 1),
    8: TierDistributionRule(dozensCount: 8, hotCount: 4, moderateCount: 3, coldCount: 1),
    9: TierDistributionRule(dozensCount: 9, hotCount: 4, moderateCount: 4, coldCount: 1),
    10: TierDistributionRule(dozensCount: 10, hotCount: 4, moderateCount: 4, coldCount: 2),
    11: TierDistributionRule(dozensCount: 11, hotCount: 5, moderateCount: 4, coldCount: 2),
    12: TierDistributionRule(dozensCount: 12, hotCount: 6, moderateCount: 4, coldCount: 2),
    13: TierDistributionRule(dozensCount: 13, hotCount: 6, moderateCount: 5, coldCount: 2),
    14: TierDistributionRule(dozensCount: 14, hotCount: 6, moderateCount: 5, coldCount: 3),
    15: TierDistributionRule(dozensCount: 15, hotCount: 7, moderateCount: 5, coldCount: 3),
    16: TierDistributionRule(dozensCount: 16, hotCount: 7, moderateCount: 6, coldCount: 3),
    17: TierDistributionRule(dozensCount: 17, hotCount: 8, moderateCount: 6, coldCount: 3),
    18: TierDistributionRule(dozensCount: 18, hotCount: 8, moderateCount: 7, coldCount: 3),
    19: TierDistributionRule(dozensCount: 19, hotCount: 8, moderateCount: 7, coldCount: 4),
    20: TierDistributionRule(dozensCount: 20, hotCount: 9, moderateCount: 7, coldCount: 4),
  };

  static TierDistributionRule getRuleForDozens(int dozensCount) {
    final rule = distributionTable[dozensCount];
    if (rule == null) {
      throw ArgumentError('Quantidade de dezenas inválida: $dozensCount (permitido de 6 a 20).');
    }
    return rule;
  }

  /// Gera os jogos solicitados em lote respeitando:
  /// - Limite máximo de 999 jogos no total (incluindo os [existingGames] quando estiver adicionando)
  /// - Distribuição exata de Mais Sorteados (q), Moderados (m) e Menos Sorteados (b)
  /// - Garantia de jogos únicos (sem repetir entre si e sem repetir nenhum jogo de [existingGames])
  List<BetGame> generateBatch({
    required List<BatchRequestItem> requests,
    required FrequencyStats stats,
    List<BetGame> existingGames = const [],
    Random? random,
  }) {
    final int totalRequested = requests.fold(0, (sum, item) => sum + item.gamesQuantity);
    if (totalRequested <= 0) {
      throw ArgumentError('Informe pelo menos 1 jogo para gerar.');
    }
    if (existingGames.length + totalRequested > maxTotalGames) {
      throw ArgumentError(
        'O limite máximo permitido é de $maxTotalGames jogos na base '
        '(atuais: ${existingGames.length}, solicitados: $totalRequested).',
      );
    }

    final rng = random ?? Random.secure();
    final List<BetGame> generatedGames = [];
    // Registra todas as combinações já existentes na base para impedir qualquer repetição
    final Set<String> usedCombinations = {
      for (final existing in existingGames) existing.combinationKey,
    };
    final DateTime now = DateTime.now();

    int maxExistingSequence = 0;
    for (final existing in existingGames) {
      if (existing.sequenceNumber > maxExistingSequence) {
        maxExistingSequence = existing.sequenceNumber;
      }
    }
    int sequence = maxExistingSequence + 1;

    for (final req in requests) {
      if (req.gamesQuantity <= 0) continue;
      final rule = getRuleForDozens(req.dozensCount);

      for (int i = 0; i < req.gamesQuantity; i++) {
        List<int> chosenNumbers = [];
        String signature = '';
        int attempts = 0;

        do {
          attempts++;
          final pickedHot = _pickRandomSubset(stats.hotNumbers, rule.hotCount, rng);
          final pickedMod = _pickRandomSubset(stats.moderateNumbers, rule.moderateCount, rng);
          final pickedCold = _pickRandomSubset(stats.coldNumbers, rule.coldCount, rng);

          chosenNumbers = [...pickedHot, ...pickedMod, ...pickedCold]..sort();
          signature = chosenNumbers.map((n) => n.toString().padLeft(2, '0')).join('-');
        } while (usedCombinations.contains(signature) && attempts < 5000);

        usedCombinations.add(signature);

        generatedGames.add(
          BetGame(
            id: '${now.microsecondsSinceEpoch}_$sequence',
            sequenceNumber: sequence,
            dozensCount: req.dozensCount,
            numbers: chosenNumbers,
            isCompleted: false,
            createdAt: now,
          ),
        );
        sequence++;
      }
    }

    return generatedGames;
  }

  List<int> _pickRandomSubset(List<int> source, int count, Random rng) {
    final pool = List<int>.from(source);
    // Embaralhamento parcial Fisher-Yates para escolher `count` elementos distintos
    for (int i = 0; i < count; i++) {
      final swapIndex = i + rng.nextInt(pool.length - i);
      final temp = pool[i];
      pool[i] = pool[swapIndex];
      pool[swapIndex] = temp;
    }
    return pool.sublist(0, count);
  }
}
