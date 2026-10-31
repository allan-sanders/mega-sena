import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:mega_sena_app/models/batch_request_item.dart';
import 'package:mega_sena_app/models/draw_result.dart';
import 'package:mega_sena_app/models/frequency_stats.dart';
import 'package:mega_sena_app/services/game_generator_service.dart';
import 'package:mega_sena_app/services/lottery_sync_service.dart';

void main() {
  group('Regras de Sincronização Semanal (Base Domingo)', () {
    test('Se sincronizou no domingo, não deve sincronizar na segunda-feira seguinte', () {
      final sundayMorning = DateTime(2026, 10, 25, 10, 30); // Domingo
      final mondayAfternoon = DateTime(2026, 10, 26, 15, 0); // Segunda-feira

      final shouldSync = LotterySyncService.shouldSyncForCurrentWeek(
        lastSyncDate: sundayMorning,
        now: mondayAfternoon,
      );

      expect(shouldSync, isFalse);
    });

    test('Se sincronizou na semana anterior, deve sincronizar a partir do próximo domingo', () {
      final previousSunday = DateTime(2026, 10, 18, 14, 0); // Domingo anterior
      final currentSunday = DateTime(2026, 10, 25, 8, 0); // Novo domingo

      final shouldSync = LotterySyncService.shouldSyncForCurrentWeek(
        lastSyncDate: previousSunday,
        now: currentSunday,
      );

      expect(shouldSync, isTrue);
    });
  });

  group('Classificação 30% (18) / 40% (24) / 30% (18) e Matriz 6 a 20 dezenas', () {
    late FrequencyStats stats;

    setUp(() {
      final rng = Random(42);
      final List<DrawResult> draws = [];
      for (int i = 1; i <= 100; i++) {
        final Set<int> nums = {};
        while (nums.length < 6) {
          nums.add(rng.nextInt(60) + 1);
        }
        draws.add(
          DrawResult(
            contestNumber: 2700 + i,
            drawDate: DateTime(2026, 1, 1).add(Duration(days: i * 3)),
            numbers: nums.toList()..sort(),
          ),
        );
      }
      stats = FrequencyStats.fromDraws(draws);
    });

    test('Deve dividir exatamente as 60 dezenas em 18 Quentes, 24 Moderadas e 18 Frias sem sobreposição', () {
      expect(stats.hotNumbers.length, 18);
      expect(stats.moderateNumbers.length, 24);
      expect(stats.coldNumbers.length, 18);

      final allGrouped = {
        ...stats.hotNumbers,
        ...stats.moderateNumbers,
        ...stats.coldNumbers,
      };
      expect(allGrouped.length, 60);
    });

    test('Deve respeitar a tabela de distribuição para todas as dezenas de 6 a 20 e o limite de 999 jogos', () {
      final generator = GameGeneratorService();

      for (int dozens = 6; dozens <= 20; dozens++) {
        final rule = GameGeneratorService.getRuleForDozens(dozens);
        final games = generator.generateBatch(
          requests: [BatchRequestItem(dozensCount: dozens, gamesQuantity: 3)],
          stats: stats,
          random: Random(100 + dozens),
        );

        expect(games.length, 3);
        for (final game in games) {
          expect(game.numbers.length, dozens);
          final qCount = game.numbers.where((n) => stats.hotNumbers.contains(n)).length;
          final mCount = game.numbers.where((n) => stats.moderateNumbers.contains(n)).length;
          final bCount = game.numbers.where((n) => stats.coldNumbers.contains(n)).length;

          expect(qCount, rule.hotCount);
          expect(mCount, rule.moderateCount);
          expect(bCount, rule.coldCount);
        }
      }
    });

    test('Deve bloquear pedidos acima de 999 jogos', () {
      final generator = GameGeneratorService();
      expect(
        () => generator.generateBatch(
          requests: [
            BatchRequestItem(dozensCount: 6, gamesQuantity: 500),
            BatchRequestItem(dozensCount: 7, gamesQuantity: 500),
          ],
          stats: stats,
        ),
        throwsArgumentError,
      );
    });

    test('Ao adicionar jogos aos já existentes, não deve repetir nenhum jogo da base e deve respeitar o teto global de 999', () {
      final generator = GameGeneratorService();

      // Gera um primeiro lote de 50 jogos
      final initialBatch = generator.generateBatch(
        requests: [BatchRequestItem(dozensCount: 6, gamesQuantity: 50)],
        stats: stats,
        random: Random(777),
      );

      // Marca alguns como realizados
      initialBatch[0] = initialBatch[0].copyWith(isCompleted: true);
      initialBatch[1] = initialBatch[1].copyWith(isCompleted: true);

      // Solicita adicionar +40 jogos passando os existentes na base
      final appendedBatch = generator.generateBatch(
        requests: [BatchRequestItem(dozensCount: 6, gamesQuantity: 40)],
        stats: stats,
        existingGames: initialBatch,
        random: Random(777), // Mesma seed proposital para forçar colisão e testar a proteção anti-repetição
      );

      final combined = [...initialBatch, ...appendedBatch];
      expect(combined.length, 90);

      // Verifica numeração sequencial contínua (#051 a #090)
      expect(appendedBatch.first.sequenceNumber, 51);
      expect(appendedBatch.last.sequenceNumber, 90);

      // Garante que todas as 90 combinações na base são 100% únicas
      final uniqueKeys = combined.map((g) => g.combinationKey).toSet();
      expect(uniqueKeys.length, 90);

      // Verifica que o teto de 999 considera os jogos já existentes (90 + 910 = 1000 -> erro)
      expect(
        () => generator.generateBatch(
          requests: [BatchRequestItem(dozensCount: 6, gamesQuantity: 910)],
          stats: stats,
          existingGames: combined,
        ),
        throwsArgumentError,
      );
    });
  });
}
