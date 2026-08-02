class RankedCombination {
  const RankedCombination({
    required this.numbers,
    required this.score,
    required this.sum,
    required this.evens,
    required this.repeated,
    required this.contributions,
  });

  final List<int> numbers;
  final double score;
  final int sum;
  final int evens;
  final int repeated;
  final Map<String, double> contributions;

  int get odds => 6 - evens;
  String get label => numbers.join(' - ');

  Map<String, Object> toMap() {
    return <String, Object>{
      'numbers': numbers,
      'score': score,
      'sum': sum,
      'evens': evens,
      'repeated': repeated,
      'contributions': contributions,
    };
  }

  factory RankedCombination.fromMap(Map<Object?, Object?> map) {
    final Object? rawNumbers = map['numbers'];
    final Object? rawScore = map['score'];
    final Object? rawSum = map['sum'];
    final Object? rawEvens = map['evens'];
    final Object? rawRepeated = map['repeated'];
    final Object? rawContributions = map['contributions'];

    if (rawNumbers is! List ||
        rawScore is! num ||
        rawSum is! int ||
        rawEvens is! int ||
        rawRepeated is! int ||
        rawContributions is! Map) {
      throw const FormatException('Resultado de ranking inválido.');
    }

    final Map<String, double> contributions = <String, double>{};
    rawContributions.forEach((Object? key, Object? value) {
      if (key is String && value is num) {
        contributions[key] = value.toDouble();
      }
    });

    return RankedCombination(
      numbers: rawNumbers.cast<int>(),
      score: rawScore.toDouble(),
      sum: rawSum,
      evens: rawEvens,
      repeated: rawRepeated,
      contributions: Map<String, double>.unmodifiable(contributions),
    );
  }
}
