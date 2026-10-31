import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/batch_request_item.dart';
import '../services/game_generator_service.dart';
import '../theme/app_theme.dart';

class GeneratorSheet extends StatefulWidget {
  final bool hasExistingGames;
  final bool isAppendMode;
  final int existingGamesCount;
  final ValueChanged<List<BatchRequestItem>> onConfirmGenerate;

  const GeneratorSheet({
    super.key,
    required this.hasExistingGames,
    this.isAppendMode = false,
    this.existingGamesCount = 0,
    required this.onConfirmGenerate,
  });

  @override
  State<GeneratorSheet> createState() => _GeneratorSheetState();
}

class _GeneratorSheetState extends State<GeneratorSheet> {
  late final List<BatchRequestItem> _items;
  final List<TextEditingController> _controllers = [];

  int get _maxAllowedToAdd => widget.isAppendMode
      ? (GameGeneratorService.maxTotalGames - widget.existingGamesCount).clamp(0, 999)
      : GameGeneratorService.maxTotalGames;

  @override
  void initState() {
    super.initState();
    final initialQty = _maxAllowedToAdd >= 10 ? 10 : _maxAllowedToAdd;
    _items = [
      BatchRequestItem(dozensCount: 6, gamesQuantity: initialQty),
    ];
    _controllers.add(TextEditingController(text: initialQty.toString()));
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  int get _totalGamesRequested =>
      _items.fold(0, (sum, item) => sum + item.gamesQuantity);

  int get _remainingQuota =>
      (_maxAllowedToAdd - _totalGamesRequested).clamp(0, 999);

  void _addLine() {
    if (_totalGamesRequested >= _maxAllowedToAdd) return;
    // Sugere a próxima quantidade de dezenas ainda não usada ou 6 por padrão
    final usedDozens = _items.map((e) => e.dozensCount).toSet();
    int suggestedDozens = 6;
    for (int d = 6; d <= 20; d++) {
      if (!usedDozens.contains(d)) {
        suggestedDozens = d;
        break;
      }
    }
    final defaultQty = _remainingQuota >= 5 ? 5 : _remainingQuota;
    setState(() {
      _items.add(BatchRequestItem(
        dozensCount: suggestedDozens,
        gamesQuantity: defaultQty,
      ));
      _controllers.add(TextEditingController(text: defaultQty.toString()));
    });
  }

  void _removeLine(int index) {
    if (_items.length <= 1) return;
    setState(() {
      _items.removeAt(index);
      final ctrl = _controllers.removeAt(index);
      ctrl.dispose();
    });
  }

  void _submit() {
    final total = _totalGamesRequested;
    if (total <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Informe pelo menos 1 jogo para gerar.')),
      );
      return;
    }
    if (total > _maxAllowedToAdd) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.isAppendMode
                ? 'Você já tem ${widget.existingGamesCount} jogo(s). Só é possível adicionar mais $_maxAllowedToAdd até o limite de 999.'
                : 'O limite máximo é de 999 jogos no total. Ajuste as quantidades.',
          ),
        ),
      );
      return;
    }

    widget.onConfirmGenerate(_items);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final total = _totalGamesRequested;
    final finalTotalInBase = widget.isAppendMode
        ? widget.existingGamesCount + total
        : total;
    final exceedsLimit = total > _maxAllowedToAdd;

    return Container(
      padding: EdgeInsets.fromLTRB(20, 16, 20, 20 + bottomInset),
      decoration: const BoxDecoration(
        color: AppTheme.bgSecondary,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(
          top: BorderSide(color: AppTheme.emeraldAccent, width: 1.2),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.textSecondary.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(
                  widget.isAppendMode ? Icons.playlist_add_circle_rounded : Icons.bolt_rounded,
                  color: AppTheme.neonEmerald,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.isAppendMode ? 'Adicionar Jogos aos Atuais' : 'Novo Lote de Jogos',
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: exceedsLimit
                        ? AppTheme.warmCoral.withValues(alpha: 0.2)
                        : AppTheme.neonEmerald.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: exceedsLimit ? AppTheme.warmCoral : AppTheme.neonEmerald,
                    ),
                  ),
                  child: Text(
                    'Total: $finalTotalInBase / 999',
                    style: TextStyle(
                      color: exceedsLimit ? AppTheme.warmCoral : AppTheme.neonEmerald,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              widget.isAppendMode
                  ? 'Mantém seus ${widget.existingGamesCount} jogo(s) atuais (e os marcados como realizados) e garante zero repetição com os já criados.'
                  : widget.hasExistingGames
                      ? 'Atenção: Ao gerar um novo combinado, a lista atual será apagada e substituída.'
                      : 'Escolha quantas dezenas (6 a 20) e a quantidade de jogos por linha.',
              style: TextStyle(
                color: (!widget.isAppendMode && widget.hasExistingGames)
                    ? AppTheme.goldHighlight
                    : AppTheme.textSecondary,
                fontSize: 12.5,
              ),
            ),
            const SizedBox(height: 16),
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.45,
              ),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _items.length,
                itemBuilder: (context, index) {
                  return _buildRequestRow(index);
                },
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                TextButton.icon(
                  onPressed: _totalGamesRequested >= _maxAllowedToAdd ? null : _addLine,
                  icon: const Icon(Icons.add_circle_outline_rounded, size: 18),
                  label: const Text('Adicionar outra dezena'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppTheme.neonEmerald,
                  ),
                ),
                const Spacer(),
                Text(
                  'Disponível: $_remainingQuota jogos',
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: (total <= 0 || exceedsLimit) ? null : _submit,
                icon: Icon(
                  widget.isAppendMode ? Icons.add_task_rounded : Icons.auto_awesome_rounded,
                ),
                label: Text(
                  widget.isAppendMode
                      ? 'Adicionar +$total Jogo(s) sem Repetir'
                      : widget.hasExistingGames
                          ? 'Apagar Atuais e Gerar $total Jogo(s)'
                          : 'Gerar $total Jogo(s) Agora',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRequestRow(int index) {
    final item = _items[index];
    final rule = GameGeneratorService.getRuleForDozens(item.dozensCount);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Seletor de Dezenas (6 a 20)
              Expanded(
                flex: 5,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Dezenas por jogo',
                      style: TextStyle(color: AppTheme.textSecondary, fontSize: 11),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: AppTheme.bgPrimary,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.borderSubtle),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<int>(
                          value: item.dozensCount,
                          isExpanded: true,
                          dropdownColor: AppTheme.surfaceCard,
                          items: List.generate(15, (i) => i + 6).map((d) {
                            return DropdownMenuItem<int>(
                              value: d,
                              child: Text(
                                '$d dezenas',
                                style: const TextStyle(
                                  color: AppTheme.textPrimary,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                ),
                              ),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val == null) return;
                            setState(() {
                              item.dozensCount = val;
                            });
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              // Quantidade de jogos
              Expanded(
                flex: 4,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Qtd. de jogos',
                      style: TextStyle(color: AppTheme.textSecondary, fontSize: 11),
                    ),
                    const SizedBox(height: 4),
                    TextField(
                      controller: _controllers[index],
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(3),
                      ],
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: AppTheme.bgPrimary,
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppTheme.borderSubtle),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppTheme.borderSubtle),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppTheme.neonEmerald),
                        ),
                      ),
                      onChanged: (value) {
                        final parsed = int.tryParse(value) ?? 0;
                        setState(() {
                          item.gamesQuantity = parsed;
                        });
                      },
                    ),
                  ],
                ),
              ),
              if (_items.length > 1) ...[
                const SizedBox(width: 6),
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: IconButton(
                    onPressed: () => _removeLine(index),
                    icon: const Icon(
                      Icons.delete_outline_rounded,
                      color: AppTheme.warmCoral,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          // Regra de distribuição aplicada automaticamente para a dezena selecionada
          Row(
            children: [
              const Icon(
                Icons.tune_rounded,
                size: 13,
                color: AppTheme.emeraldAccent,
              ),
              const SizedBox(width: 6),
              Text(
                'Matriz ${item.dozensCount} dez: ',
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '${rule.hotCount} Mais Sort. (Q)  •  ${rule.moderateCount} Mod. (M)  •  ${rule.coldCount} Menos Sort. (B)',
                style: const TextStyle(
                  color: AppTheme.neonEmerald,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
