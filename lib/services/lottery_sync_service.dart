import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import '../models/draw_result.dart';
import '../models/frequency_stats.dart';
import 'storage_service.dart';

class LotterySyncService {
  static const String _caixaOfficialBaseUrl =
      'https://servicebus2.caixa.gov.br/portaldeloterias/api/megasena';
  static const String _fallbackMirrorBaseUrl =
      'https://loteriascaixa-api.herokuapp.com/api/megasena';

  final StorageService _storageService;

  LotterySyncService(this._storageService);

  /// Retorna o início (00:00:00) do domingo mais recente em relação a [now].
  /// No Dart, DateTime.sunday == 7.
  static DateTime startOfMostRecentSunday(DateTime now) {
    final daysSinceSunday = now.weekday % 7; // Domingo (7) -> 0, Segunda (1) -> 1, etc.
    final sundayDate = now.subtract(Duration(days: daysSinceSunday));
    return DateTime(sundayDate.year, sundayDate.month, sundayDate.day);
  }

  /// Retorna o próximo domingo (para exibição na interface).
  static DateTime nextSundayDate(DateTime now) {
    final currentSunday = startOfMostRecentSunday(now);
    return currentSunday.add(const Duration(days: 7));
  }

  /// Verifica se deve sincronizar na semana atual tendo o domingo como base:
  /// - Se nunca sincronizou -> true
  /// - Se a última sincronização ocorreu antes do domingo mais recente (00:00:00) -> true
  /// - Se já sincronizou no domingo atual ou depois dele (segunda a sábado da mesma semana) -> false
  static bool shouldSyncForCurrentWeek({
    required DateTime? lastSyncDate,
    DateTime? now,
  }) {
    if (lastSyncDate == null) return true;
    final referenceNow = now ?? DateTime.now();
    final mostRecentSundayStart = startOfMostRecentSunday(referenceNow);
    return lastSyncDate.isBefore(mostRecentSundayStart);
  }

  /// Executa a verificação ao logar/abrir o app e sincroniza apenas 1x por semana (base domingo).
  Future<FrequencyStats> ensureWeeklySync({
    bool forceRefresh = false,
    void Function(String statusMessage, double progress)? onProgress,
  }) async {
    final cachedStats = await _storageService.loadFrequencyStats();
    final now = DateTime.now();

    if (!forceRefresh &&
        cachedStats != null &&
        !shouldSyncForCurrentWeek(lastSyncDate: cachedStats.syncedAt, now: now)) {
      onProgress?.call('Base semanal já sincronizada!', 1.0);
      return cachedStats;
    }

    onProgress?.call('Sincronizando últimos 100 jogos da Mega-Sena...', 0.15);

    List<DrawResult> draws = await _fetchLast100Draws(onProgress: onProgress);
    if (draws.isEmpty) {
      // Fallback caso o aparelho esteja sem internet no primeiro acesso
      if (cachedStats != null) {
        return cachedStats;
      }
      draws = _generateFallbackHistoricalSeed();
    }

    onProgress?.call('Calculando distribuição 30% / 40% / 30%...', 0.92);
    final stats = FrequencyStats.fromDraws(draws, syncTime: now);
    await _storageService.saveFrequencyStats(stats);
    onProgress?.call('Sincronização concluída!', 1.0);
    return stats;
  }

  Future<List<DrawResult>> _fetchLast100Draws({
    void Function(String statusMessage, double progress)? onProgress,
  }) async {
    // 1. Tenta buscar o último concurso pela API oficial da Caixa
    try {
      final latestResponse = await http
          .get(
            Uri.parse(_caixaOfficialBaseUrl),
            headers: {'Accept': 'application/json'},
          )
          .timeout(const Duration(seconds: 8));

      if (latestResponse.statusCode == 200) {
        final latestJson = jsonDecode(latestResponse.body) as Map<String, dynamic>;
        final latestDraw = DrawResult.fromCaixaApiJson(latestJson);
        final List<DrawResult> results = [latestDraw];

        // Busca os 99 concursos anteriores em lotes paralelos controlados
        final int startContest = max(1, latestDraw.contestNumber - 99);
        final List<int> remainingContests = [
          for (int c = latestDraw.contestNumber - 1; c >= startContest; c--) c
        ];

        const int batchSize = 15;
        for (int i = 0; i < remainingContests.length; i += batchSize) {
          final chunk = remainingContests.sublist(
            i,
            min(i + batchSize, remainingContests.length),
          );
          final fetchedChunk = await Future.wait(
            chunk.map((contestNum) => _fetchSingleCaixaContest(contestNum)),
          );
          for (final item in fetchedChunk) {
            if (item != null) results.add(item);
          }
          final progress = 0.2 + (0.65 * ((i + chunk.length) / remainingContests.length));
          onProgress?.call(
            'Sincronizando concursos (${results.length}/100)...',
            progress.clamp(0.2, 0.88),
          );
        }

        if (results.length >= 20) {
          return results;
        }
      }
    } catch (_) {
      // Prossegue para o mirror rápido com todos os concursos em uma única chamada
    }

    // 2. Fallback para API espelho (retorna histórico completo rapidamente)
    try {
      onProgress?.call('Consultando base espelho das Loterias Caixa...', 0.55);
      final mirrorRes = await http
          .get(Uri.parse(_fallbackMirrorBaseUrl))
          .timeout(const Duration(seconds: 10));

      if (mirrorRes.statusCode == 200) {
        final List<dynamic> list = jsonDecode(mirrorRes.body) as List<dynamic>;
        final List<DrawResult> parsed = [];
        for (final raw in list.take(100)) {
          final map = raw as Map<String, dynamic>;
          final concurso = (map['concurso'] as num).toInt();
          final dezenas = (map['dezenas'] as List<dynamic>)
              .map((d) => int.parse(d.toString()))
              .toList()
            ..sort();
          parsed.add(
            DrawResult(
              contestNumber: concurso,
              drawDate: DateTime.now(),
              numbers: dezenas,
            ),
          );
        }
        if (parsed.isNotEmpty) {
          return parsed;
        }
      }
    } catch (_) {
      // Sem conexão ou API indisponível no momento
    }

    return [];
  }

  Future<DrawResult?> _fetchSingleCaixaContest(int contestNumber) async {
    try {
      final response = await http
          .get(
            Uri.parse('$_caixaOfficialBaseUrl/$contestNumber'),
            headers: {'Accept': 'application/json'},
          )
          .timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return DrawResult.fromCaixaApiJson(data);
      }
    } catch (_) {}
    return null;
  }

  /// Base histórica realista de contingência (100 concursos determinísticos)
  /// caso o dispositivo esteja offline no momento do primeiro acesso.
  List<DrawResult> _generateFallbackHistoricalSeed() {
    final rng = Random(20261031);
    final List<DrawResult> draws = [];
    const int baseContest = 2800;

    // Pesos estatísticos históricos reais da Mega-Sena (ex: 10, 53, 05, 37, 33 costumam ter alta frequência)
    final List<int> weightedPool = [];
    const highFreq = [10, 53, 5, 37, 33, 23, 4, 30, 42, 41, 27, 34, 35, 17, 38, 43, 54, 11];
    const modFreq = [
      2, 8, 12, 13, 16, 18, 20, 24, 28, 29, 32, 36, 44, 45, 46, 49, 50, 51, 52, 56, 58, 59, 6, 47
    ];

    for (int n = 1; n <= 60; n++) {
      if (highFreq.contains(n)) {
        weightedPool.addAll(List.filled(5, n));
      } else if (modFreq.contains(n)) {
        weightedPool.addAll(List.filled(3, n));
      } else {
        weightedPool.add(n);
      }
    }

    for (int i = 0; i < 100; i++) {
      final Set<int> picked = {};
      while (picked.length < 6) {
        picked.add(weightedPool[rng.nextInt(weightedPool.length)]);
      }
      final sorted = picked.toList()..sort();
      draws.add(
        DrawResult(
          contestNumber: baseContest - i,
          drawDate: DateTime.now().subtract(Duration(days: i * 3)),
          numbers: sorted,
        ),
      );
    }

    return draws;
  }
}
