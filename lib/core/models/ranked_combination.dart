class RankedCombination {
  const RankedCombination({
    required this.numbers,
    required this.score,
    required this.sum,
    required this.evens,
    required this.repeated,
  });

  final List<int> numbers;
  final double score;
  final int sum;
  final int evens;
  final int repeated;

  int get odds => 6 - evens;
  String get label => numbers.join(' - ');

  Map<String, Object> toMap() {
    return <String, Object>{
      'numbers': numbers,
      'score': score,
      'sum': sum,
      'evens': evens,
      'repeated': repeated,
    };
  }

  factory RankedCombination.fromMap(Map<Object?, Object?> map) {
    final Object? rawNumbers = map['numbers'];
    final Object? rawScore = map['score'];
    final Object? rawSum = map['sum'];
    final Object? rawEvens = map['evens'];
    final Object? rawRepeated = map['repeated'];

    if (rawNumbers is! List ||
        rawScore is! num ||
        rawSum is! int ||
        rawEvens is! int ||
        rawRepeated is! int) {
      throw const FormatException('Resultado de ranking inválido.');
    }

    return RankedCombination(
      numbers: rawNumbers.cast<int>(),
      score: rawScore.toDouble(),
      sum: rawSum,
      evens: rawEvens,
      repeated: rawRepeated,
    );
  }
}
