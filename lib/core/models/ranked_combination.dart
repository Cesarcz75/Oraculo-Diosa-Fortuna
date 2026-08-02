import 'score_breakdown.dart';

class RankedCombination {
  const RankedCombination({
    required this.numbers,
    required this.sum,
    required this.evens,
    required this.repeated,
    required this.breakdown,
  });

  final List<int> numbers;
  final int sum;
  final int evens;
  final int repeated;
  final ScoreBreakdown breakdown;

  double get score => breakdown.total;
  double get pitIndex => breakdown.pitIndex;
  int get odds => 6 - evens;
  String get label => numbers.join(' - ');

  Map<String, double> get contributions => <String, double>{
        for (final RuleScore rule in breakdown.rules)
          rule.label: rule.weightedValue,
      };

  Map<String, Object> toMap() => <String, Object>{
        'numbers': numbers,
        'sum': sum,
        'evens': evens,
        'repeated': repeated,
        'breakdown': breakdown.toMap(),
      };

  factory RankedCombination.fromMap(Map<Object?, Object?> map) {
    final Object? rawNumbers = map['numbers'];
    final Object? rawSum = map['sum'];
    final Object? rawEvens = map['evens'];
    final Object? rawRepeated = map['repeated'];
    final Object? rawBreakdown = map['breakdown'];

    if (rawNumbers is! List ||
        rawSum is! int ||
        rawEvens is! int ||
        rawRepeated is! int ||
        rawBreakdown is! Map) {
      throw const FormatException('Resultado de ranking inválido.');
    }

    return RankedCombination(
      numbers: rawNumbers.cast<int>(),
      sum: rawSum,
      evens: rawEvens,
      repeated: rawRepeated,
      breakdown: ScoreBreakdown.fromMap(
        Map<Object?, Object?>.from(rawBreakdown),
      ),
    );
  }
}
