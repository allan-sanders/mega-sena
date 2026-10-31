import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class ProgressHeader extends StatelessWidget {
  final int totalGames;
  final int completedGames;

  const ProgressHeader({
    super.key,
    required this.totalGames,
    required this.completedGames,
  });

  @override
  Widget build(BuildContext context) {
    final double ratio = totalGames == 0 ? 0.0 : (completedGames / totalGames).clamp(0.0, 1.0);
    final int pendingGames = totalGames - completedGames;
    final int percentage = (ratio * 100).round();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.check_circle_outline_rounded,
                color: AppTheme.neonEmerald,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Progresso de Jogos Realizados',
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: ratio == 1.0
                      ? AppTheme.neonEmerald.withValues(alpha: 0.2)
                      : AppTheme.bgPrimary,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: ratio == 1.0 ? AppTheme.neonEmerald : AppTheme.borderSubtle,
                  ),
                ),
                child: Text(
                  '$completedGames / $totalGames ($percentage%)',
                  style: TextStyle(
                    color: ratio == 1.0 ? AppTheme.neonEmerald : AppTheme.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0, end: ratio),
              duration: const Duration(milliseconds: 350),
              curve: Curves.easeOutCubic,
              builder: (context, animatedValue, _) {
                return LinearProgressIndicator(
                  value: animatedValue,
                  minHeight: 9,
                  backgroundColor: AppTheme.bgPrimary,
                  valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.neonEmerald),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                pendingGames == 0
                    ? 'Todos os jogos deste lote foram realizados!'
                    : 'Faltam registrar $pendingGames jogo(s) no volante/Caixa',
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 12,
                ),
              ),
              Text(
                'Máx: 999',
                style: TextStyle(
                  color: AppTheme.textSecondary.withValues(alpha: 0.7),
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
