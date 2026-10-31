import 'package:flutter/material.dart';
import '../models/frequency_stats.dart';
import '../services/lottery_sync_service.dart';
import '../theme/app_theme.dart';

class StatsBannerCard extends StatelessWidget {
  final FrequencyStats stats;
  final VoidCallback onInspectTiers;

  const StatsBannerCard({
    super.key,
    required this.stats,
    required this.onInspectTiers,
  });

  String _formatDate(DateTime dt) {
    final d = dt.day.toString().padLeft(2, '0');
    final m = dt.month.toString().padLeft(2, '0');
    return '$d/$m/${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    final nextSunday = LotterySyncService.nextSundayDate(DateTime.now());

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF132A1F),
            Color(0xFF0D1D15),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.emeraldAccent.withValues(alpha: 0.35),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.neonEmerald.withValues(alpha: 0.06),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppTheme.neonEmerald.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: AppTheme.neonEmerald.withValues(alpha: 0.4),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.sync_rounded,
                      size: 14,
                      color: AppTheme.neonEmerald,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Base Semanal • Últimos ${stats.totalDrawsAnalyzed} Jogos',
                      style: const TextStyle(
                        color: AppTheme.neonEmerald,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              InkWell(
                onTap: onInspectTiers,
                borderRadius: BorderRadius.circular(12),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Row(
                    children: [
                      Text(
                        'Ver 30/40/30',
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(width: 4),
                      Icon(
                        Icons.chevron_right_rounded,
                        size: 16,
                        color: AppTheme.textSecondary,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildTierPill(
                label: 'Mais Sorteados (30%)',
                count: '${stats.hotNumbers.length} dez',
                color: AppTheme.goldHighlight,
              ),
              const SizedBox(width: 8),
              _buildTierPill(
                label: 'Moderados (40%)',
                count: '${stats.moderateNumbers.length} dez',
                color: AppTheme.neonEmerald,
              ),
              const SizedBox(width: 8),
              _buildTierPill(
                label: 'Menos Sort. (30%)',
                count: '${stats.coldNumbers.length} dez',
                color: AppTheme.coolCyan,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Concurso ref: #${stats.latestContestNumber} (${_formatDate(stats.syncedAt)})',
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 11.5,
                ),
              ),
              Text(
                'Próx. sync: Dom ${_formatDate(nextSunday)}',
                style: const TextStyle(
                  color: AppTheme.emeraldAccent,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTierPill({
    required String label,
    required String count,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: AppTheme.bgPrimary.withValues(alpha: 0.55),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    count,
                    style: TextStyle(
                      color: color,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 10,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
