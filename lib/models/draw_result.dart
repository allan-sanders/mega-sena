class DrawResult {
  final int contestNumber;
  final DateTime drawDate;
  final List<int> numbers;

  const DrawResult({
    required this.contestNumber,
    required this.drawDate,
    required this.numbers,
  });

  Map<String, dynamic> toJson() => {
        'contestNumber': contestNumber,
        'drawDate': drawDate.toIso8601String(),
        'numbers': numbers,
      };

  factory DrawResult.fromJson(Map<String, dynamic> json) {
    return DrawResult(
      contestNumber: json['contestNumber'] as int,
      drawDate: DateTime.parse(json['drawDate'] as String),
      numbers: (json['numbers'] as List<dynamic>).map((e) => e as int).toList(),
    );
  }

  /// Faz o parse do payload oficial da API da Caixa Loterias
  factory DrawResult.fromCaixaApiJson(Map<String, dynamic> json) {
    final numero = (json['numero'] as num).toInt();
    final rawDezenas = (json['listaDezenas'] ?? json['dezenasSorteadasOrdemSorteio'] ?? []) as List<dynamic>;
    final dezenas = rawDezenas.map((d) => int.parse(d.toString().trim())).toList()..sort();

    DateTime parsedDate = DateTime.now();
    final dataApuracao = json['dataApuracao']?.toString();
    if (dataApuracao != null && dataApuracao.contains('/')) {
      final parts = dataApuracao.split('/');
      if (parts.length == 3) {
        parsedDate = DateTime(
          int.parse(parts[2]),
          int.parse(parts[1]),
          int.parse(parts[0]),
        );
      }
    }

    return DrawResult(
      contestNumber: numero,
      drawDate: parsedDate,
      numbers: dezenas,
    );
  }
}
