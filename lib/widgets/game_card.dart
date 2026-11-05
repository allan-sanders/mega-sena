import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/bet_game.dart';
import '../models/frequency_stats.dart';
import '../services/game_generator_service.dart';
import '../theme/app_theme.dart';

class GameCard extends StatelessWidget {
  final BetGame game;
  final FrequencyStats? stats;
  final ValueChanged<bool> onToggleCompleted;
  final VoidCallback onDeleteGame;

  const GameCard({
    super.key,
    required this.game,
    required this.stats,
    required this.onToggleCompleted,
    required this.onDeleteGame,
  });

  @override
  Widget build(BuildContext context) {
    final rule = GameGeneratorService.distributionTable[game.dozensCount];
    final isDone = game.isCompleted;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOutCubic,
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDone
              ? [
                  const Color(0xFF0E261B).withValues(alpha: 0.65),
                  const Color(0xFF091710).withValues(alpha: 0.65),
                ]
              : [
                  const Color(0xFF152A1F),
                  const Color(0xFF0E1D15),
                ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDone
              ? AppTheme.neonEmerald.withValues(alpha: 0.55)
              : AppTheme.borderSubtle,
          width: isDone ? 1.4 : 1.0,
        ),
        boxShadow: [
          if (!isDone)
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.28),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            HapticFeedback.lightImpact();
            onToggleCompleted(!isDone);
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: isDone
                            ? AppTheme.neonEmerald.withValues(alpha: 0.18)
                            : AppTheme.bgPrimary,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isDone
                              ? AppTheme.neonEmerald.withValues(alpha: 0.5)
                              : AppTheme.borderSubtle,
                        ),
                      ),
                      child: Text(
                        'JOGO #${game.sequenceNumber.toString().padLeft(3, '0')}',
                        style: TextStyle(
                          color: isDone ? AppTheme.neonEmerald : AppTheme.textPrimary,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceGlass,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${game.dozensCount} dezenas',
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (rule != null) ...[
                      const SizedBox(width: 6),
                      Text(
                        '(${rule.hotCount}Q•${rule.moderateCount}M•${rule.coldCount}B)',
                        style: TextStyle(
                          color: AppTheme.textSecondary.withValues(alpha: 0.7),
                          fontSize: 11,
                        ),
                      ),
                    ],
                    const Spacer(),

                    // Excluir Jogo
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded, size: 20, color: AppTheme.warmCoral),
                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                      padding: EdgeInsets.zero,
                      onPressed: onDeleteGame,
                    ),
                    const SizedBox(width: 4),

                    // Realizado/Marcar
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: isDone
                            ? AppTheme.neonEmerald
                            : AppTheme.bgPrimary.withValues(alpha: 0.8),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                          color: isDone ? AppTheme.neonEmerald : AppTheme.emeraldAccent,
                          width: 1.2,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isDone
                                ? Icons.check_circle_rounded
                                : Icons.radio_button_unchecked_rounded,
                            size: 16,
                            color: isDone ? const Color(0xFF032212) : AppTheme.neonEmerald,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: game.numbers.map((number) {
                    final tier = stats?.getTierForNumber(number);
                    return _buildNumberBall(number, tier, isDone);
                  }).toList(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNumberBall(int number, NumberTier? tier, bool isGameCompleted) {
    Color borderColor = AppTheme.emeraldAccent;
    Color dotColor = AppTheme.neonEmerald;

    if (tier == NumberTier.hot) {
      borderColor = AppTheme.goldHighlight;
      dotColor = AppTheme.goldHighlight;
    } else if (tier == NumberTier.moderate) {
      borderColor = AppTheme.neonEmerald;
      dotColor = AppTheme.neonEmerald;
    } else if (tier == NumberTier.cold) {
      borderColor = AppTheme.coolCyan;
      dotColor = AppTheme.coolCyan;
    }

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: isGameCompleted ? 0.58 : 1.0,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              borderColor.withValues(alpha: 0.22),
              AppTheme.bgPrimary.withValues(alpha: 0.92),
            ],
            center: const Alignment(-0.3, -0.3),
            radius: 0.95,
          ),
          border: Border.all(
            color: borderColor.withValues(alpha: 0.75),
            width: 1.5,
          ),
          boxShadow: [
            if (!isGameCompleted)
              BoxShadow(
                color: borderColor.withValues(alpha: 0.16),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Text(
              number.toString().padLeft(2, '0'),
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w800,
                decoration: isGameCompleted ? TextDecoration.lineThrough : null,
              ),
            ),
            Positioned(
              bottom: 5,
              child: Container(
                width: 4,
                height: 4,
                decoration: BoxDecoration(
                  color: dotColor,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
