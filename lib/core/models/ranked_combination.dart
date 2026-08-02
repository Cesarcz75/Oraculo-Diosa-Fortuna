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
    return RankedCombination(
      numbers: List<int>.from(map['numbers']! as List<Object?>),
      score: (map['score']! as num).toDouble(),
      sum: map['sum']! as int,
      evens: map['evens']! as int,
      repeated: map['repeated']! as int,
    );
  }
}
