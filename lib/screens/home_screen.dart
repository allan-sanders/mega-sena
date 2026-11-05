import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../models/batch_request_item.dart';
import '../models/bet_game.dart';
import '../models/frequency_stats.dart';
import '../services/auth_service.dart';
import '../services/game_generator_service.dart';
import '../services/lottery_sync_service.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';
import '../widgets/game_card.dart';
import '../widgets/progress_header.dart';
import '../widgets/stats_banner_card.dart';
import 'generator_sheet.dart';
import 'manual_game_sheet.dart';

enum GameFilter { all, pending, completed }

class HomeScreen extends StatefulWidget {
  final UserAccount user;
  final StorageService storageService;
  final LotterySyncService syncService;
  final GameGeneratorService generatorService;
  final VoidCallback onLogout;

  const HomeScreen({
    super.key,
    required this.user,
    required this.storageService,
    required this.syncService,
    required this.generatorService,
    required this.onLogout,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  FrequencyStats? _stats;
  List<BetGame> _games = [];
  bool _isSyncing = true;
  String _syncMessage = 'Verificando sincronização semanal...';
  double _syncProgress = 0.1;
  GameFilter _activeFilter = GameFilter.all;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    setState(() => _isSyncing = true);

    final stats = await widget.syncService.ensureWeeklySync(
      onProgress: (msg, progress) {
        if (mounted) {
          setState(() {
            _syncMessage = msg;
            _syncProgress = progress;
          });
        }
      },
    );

    final savedGames = await widget.storageService.loadGames();

    if (mounted) {
      setState(() {
        _stats = stats;
        _games = savedGames;
        _isSyncing = false;
      });
    }
  }

  Future<void> _toggleGameCompleted(BetGame game, bool completed) async {
    final index = _games.indexWhere((g) => g.id == game.id);
    if (index == -1) return;

    setState(() {
      _games[index] = _games[index].copyWith(isCompleted: completed);
    });
    await widget.storageService.saveGames(_games);
  }

  Future<void> _deleteGame(BetGame game) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: AppTheme.surfaceCard,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: AppTheme.warmCoral, width: 1.2),
          ),
          title: const Row(
            children: [
              Icon(Icons.delete_outline, color: AppTheme.warmCoral),
              SizedBox(width: 10),
              Text(
                'Excluir Jogo?',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          content: Text(
            'Deseja excluir permanentemente o Jogo #${game.sequenceNumber.toString().padLeft(3, '0')}?',
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancelar', style: TextStyle(color: AppTheme.textSecondary)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.warmCoral),
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Excluir', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );

    if (shouldDelete == true && mounted) {
      setState(() {
        _games.removeWhere((g) => g.id == game.id);
      });
      await widget.storageService.saveGames(_games);
    }
  }

  Future<void> _exportGames() async {
    if (_games.isEmpty) return;

    final sb = StringBuffer();
    sb.writeln('=== DEZENA CERTA MS ===');
    sb.writeln('Total de Jogos: ${_games.length}');
    sb.writeln('');

    for (final game in _games) {
      final status = game.isCompleted ? '[REALIZADO]' : '[PENDENTE]';
      final numbers = game.numbers.map((n) => n.toString().padLeft(2, '0')).join(' - ');
      sb.writeln('Jogo #${game.sequenceNumber.toString().padLeft(3, '0')} $status');
      sb.writeln(numbers);
      sb.writeln('');
    }

    await Share.share(sb.toString(), subject: 'Meus Jogos - Dezena Certa MS');
  }

  Future<void> _openNewGamesBuilder() async {
    if (_stats == null) return;

    if (_games.isNotEmpty) {
      final completedCount = _games.where((g) => g.isCompleted).length;
      final shouldProceed = await showDialog<bool>(
        context: context,
        builder: (ctx) {
          return AlertDialog(
            backgroundColor: AppTheme.surfaceCard,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: const BorderSide(color: AppTheme.goldHighlight, width: 1.2),
            ),
            title: const Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: AppTheme.goldHighlight),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Substituir Jogos Atuais?',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            content: Text(
              'Você possui atualmente um combinado de ${_games.length} jogo(s) '
              '($completedCount realizado(s) e ${_games.length - completedCount} pendente(s)).\n\n'
              'Ao gerar um NOVO LOTE, todos os jogos anteriores serão excluídos permanentemente. Deseja continuar?',
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 14,
                height: 1.45,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text(
                  'Cancelar',
                  style: TextStyle(color: AppTheme.textSecondary),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.neonEmerald,
                  foregroundColor: const Color(0xFF032212),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text('Sim, criar novo lote'),
              ),
            ],
          );
        },
      );

      if (shouldProceed != true || !mounted) return;
    }

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return GeneratorSheet(
          hasExistingGames: _games.isNotEmpty,
          isAppendMode: false,
          existingGamesCount: _games.length,
          onConfirmGenerate: (requests) async {
            await _handleGenerateNewBatch(requests);
          },
        );
      },
    );
  }

  void _openAppendGamesBuilder() {
    if (_stats == null) return;

    if (_games.length >= GameGeneratorService.maxTotalGames) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Você já atingiu o limite máximo de 999 jogos na base atual.',
          ),
        ),
      );
      return;
    }

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return GeneratorSheet(
          hasExistingGames: _games.isNotEmpty,
          isAppendMode: true,
          existingGamesCount: _games.length,
          onConfirmGenerate: (requests) async {
            await _handleAppendBatch(requests);
          },
        );
      },
    );
  }

  void _openManualGameBuilder() {
    if (_stats == null) return;

    if (_games.length >= GameGeneratorService.maxTotalGames) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Você já atingiu o limite máximo de 999 jogos na base atual.'),
        ),
      );
      return;
    }

    final nextSequence = _games.isEmpty ? 1 : _games.map((g) => g.sequenceNumber).reduce((a, b) => a > b ? a : b) + 1;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return ManualGameSheet(
          nextSequenceNumber: nextSequence,
          onSaveManualGame: (newGame) async {
            final updatedList = [..._games, newGame];
            await widget.storageService.saveGames(updatedList);
            if (mounted) {
              setState(() {
                _games = updatedList;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Jogo manual adicionado com sucesso!'),
                ),
              );
            }
          },
        );
      },
    );
  }

  Future<void> _handleGenerateNewBatch(List<BatchRequestItem> requests) async {
    if (_stats == null) return;

    await widget.storageService.clearGames();

    final newGames = widget.generatorService.generateBatch(
      requests: requests,
      stats: _stats!,
    );

    await widget.storageService.saveGames(newGames);

    if (mounted) {
      setState(() {
        _games = newGames;
        _activeFilter = GameFilter.all;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${newGames.length} novo(s) jogo(s) gerado(s) com sucesso! Jogos anteriores apagados.',
          ),
        ),
      );
    }
  }

  Future<void> _handleAppendBatch(List<BatchRequestItem> requests) async {
    if (_stats == null) return;

    final addedGames = widget.generatorService.generateBatch(
      requests: requests,
      stats: _stats!,
      existingGames: _games,
    );

    final updatedList = [..._games, ...addedGames];
    await widget.storageService.saveGames(updatedList);

    if (mounted) {
      setState(() {
        _games = updatedList;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '+${addedGames.length} jogo(s) inédito(s) adicionado(s)! Total na base: ${updatedList.length}.',
          ),
        ),
      );
    }
  }

  void _showTiersDetailsModal() {
    final stats = _stats;
    if (stats == null) return;

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppTheme.bgSecondary,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      isScrollControlled: true,
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.72,
          maxChildSize: 0.9,
          minChildSize: 0.5,
          builder: (context, scrollController) {
            return Padding(
              padding: const EdgeInsets.all(20),
              child: ListView(
                controller: scrollController,
                children: [
                  const Text(
                    'Classificação 30% • 40% • 30%',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Baseada nos últimos ${stats.totalDrawsAnalyzed} concursos.',
                    style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                  ),
                  const SizedBox(height: 18),
                  _buildTierSection(
                    title: 'Mais Sorteados — 30% (18 Dezenas)',
                    subtitle: 'Grupo Q (Quentes)',
                    numbers: stats.hotNumbers,
                    frequencies: stats.frequencies,
                    color: AppTheme.goldHighlight,
                  ),
                  const SizedBox(height: 16),
                  _buildTierSection(
                    title: 'Moderados — 40% (24 Dezenas)',
                    subtitle: 'Grupo M (Intermediários)',
                    numbers: stats.moderateNumbers,
                    frequencies: stats.frequencies,
                    color: AppTheme.neonEmerald,
                  ),
                  const SizedBox(height: 16),
                  _buildTierSection(
                    title: 'Menos Sorteados — 30% (18 Dezenas)',
                    subtitle: 'Grupo B (Baixa frequência)',
                    numbers: stats.coldNumbers,
                    frequencies: stats.frequencies,
                    color: AppTheme.coolCyan,
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildTierSection({
    required String title,
    required String subtitle,
    required List<int> numbers,
    required Map<int, int> frequencies,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 14),
                ),
              ),
              Text(
                subtitle,
                style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11.5),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: numbers.map((n) {
              final freq = frequencies[n] ?? 0;
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.bgPrimary,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: color.withValues(alpha: 0.45)),
                ),
                child: RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: n.toString().padLeft(2, '0'),
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.w800,
                          fontSize: 13.5,
                        ),
                      ),
                      TextSpan(
                        text: ' (${freq}x)',
                        style: TextStyle(
                          color: color,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  List<BetGame> get _filteredGames {
    switch (_activeFilter) {
      case GameFilter.pending:
        return _games.where((g) => !g.isCompleted).toList();
      case GameFilter.completed:
        return _games.where((g) => g.isCompleted).toList();
      case GameFilter.all:
        return _games;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isSyncing) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(
                  width: 56,
                  height: 56,
                  child: CircularProgressIndicator(
                    color: AppTheme.neonEmerald,
                    strokeWidth: 3.5,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  _syncMessage,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 14),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: _syncProgress,
                    minHeight: 6,
                    backgroundColor: AppTheme.surfaceCard,
                    valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.neonEmerald),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final completedCount = _games.where((g) => g.isCompleted).length;
    final visibleGames = _filteredGames;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Dezena Certa MS'),
            Text(
              'Olá, ${widget.user.displayName}',
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Novo Lote',
            onPressed: _openNewGamesBuilder,
            icon: const Icon(Icons.autorenew_rounded, color: AppTheme.goldHighlight),
          ),
          IconButton(
            tooltip: 'Exportar Jogos',
            onPressed: _games.isNotEmpty ? _exportGames : null,
            icon: Icon(
              Icons.ios_share_rounded,
              color: _games.isNotEmpty ? AppTheme.coolCyan : AppTheme.textSecondary.withValues(alpha: 0.3),
            ),
          ),
          IconButton(
            tooltip: 'Estatísticas',
            onPressed: _showTiersDetailsModal,
            icon: const Icon(Icons.analytics_outlined, color: AppTheme.neonEmerald),
          ),
          IconButton(
            tooltip: 'Sair da conta',
            onPressed: widget.onLogout,
            icon: const Icon(Icons.logout_rounded, color: AppTheme.textSecondary),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              if (_stats != null)
                StatsBannerCard(
                  stats: _stats!,
                  onInspectTiers: _showTiersDetailsModal,
                ),
              const SizedBox(height: 12),

              if (_games.isNotEmpty) ...[
                // Cabeçalho e botão NOVO LOTE na parte superior
                Row(
                  children: [
                    Expanded(
                      child: ProgressHeader(
                        totalGames: _games.length,
                        completedGames: completedCount,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildFilterTabs(completedCount),
                const SizedBox(height: 10),
              ],
              Expanded(
                child: _games.isEmpty
                    ? _buildEmptyState()
                    : visibleGames.isEmpty
                        ? Center(
                            child: Text(
                              _activeFilter == GameFilter.pending
                                  ? 'Nenhum jogo pendente! Todos foram realizados.'
                                  : 'Nenhum jogo marcado como realizado ainda.',
                              style: const TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 14,
                              ),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.only(bottom: 96),
                            itemCount: visibleGames.length,
                            itemBuilder: (context, index) {
                              final game = visibleGames[index];
                              return GameCard(
                                key: ValueKey(game.id),
                                game: game,
                                stats: _stats,
                                onToggleCompleted: (done) => _toggleGameCompleted(game, done),
                                onDeleteGame: () => _deleteGame(game),
                              );
                            },
                          ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            Expanded(
              flex: 1,
              child: SizedBox(
                height: 56,
                child: OutlinedButton.icon(
                  onPressed: _openManualGameBuilder,
                  style: OutlinedButton.styleFrom(
                    backgroundColor: AppTheme.surfaceCard,
                    foregroundColor: AppTheme.textPrimary,
                    side: const BorderSide(color: AppTheme.borderSubtle, width: 1.3),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  icon: const Icon(Icons.edit_note_rounded, size: 20),
                  label: const Text(
                    'MANUAL',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 2,
              child: SizedBox(
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: _games.isEmpty ? _openNewGamesBuilder : _openAppendGamesBuilder,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                  icon: Icon(_games.isEmpty ? Icons.auto_awesome_rounded : Icons.playlist_add_rounded, size: 22),
                  label: Text(
                    _games.isEmpty ? 'GERAR JOGOS' : 'NOVOS JOGOS',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterTabs(int completedCount) {
    final pendingCount = _games.length - completedCount;

    return Row(
      children: [
        _buildFilterChip(
          label: 'Todos (${_games.length})',
          selected: _activeFilter == GameFilter.all,
          onTap: () => setState(() => _activeFilter = GameFilter.all),
        ),
        const SizedBox(width: 8),
        _buildFilterChip(
          label: 'Pendentes ($pendingCount)',
          selected: _activeFilter == GameFilter.pending,
          onTap: () => setState(() => _activeFilter = GameFilter.pending),
        ),
        const SizedBox(width: 8),
        _buildFilterChip(
          label: 'Realizados ($completedCount)',
          selected: _activeFilter == GameFilter.completed,
          onTap: () => setState(() => _activeFilter = GameFilter.completed),
        ),
      ],
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 9),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected
                ? AppTheme.neonEmerald.withValues(alpha: 0.18)
                : AppTheme.surfaceCard,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? AppTheme.neonEmerald : AppTheme.borderSubtle,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? AppTheme.neonEmerald : AppTheme.textSecondary,
              fontSize: 12,
              fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppTheme.surfaceCard,
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.borderSubtle),
              ),
              child: const Icon(
                Icons.confirmation_number_outlined,
                color: AppTheme.neonEmerald,
                size: 38,
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Nenhum jogo ativo no momento',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Gere novos jogos baseados nas estatísticas ou adicione jogos manualmente.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 13.5,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
