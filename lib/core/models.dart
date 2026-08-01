
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

  String get label => numbers.join(' - ');
  int get odds => 6 - evens;
}
