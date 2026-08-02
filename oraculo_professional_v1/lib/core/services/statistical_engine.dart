import 'dart:math';
import '../models/ranked_combination.dart';

class StatisticalEngine {
  StatisticalEngine(this.history) {
    if (history.length < 20) {
      throw ArgumentError('Se requieren al menos 20 sorteos.');
    }
    _fit();
  }

  final List<List<int>> history;

  late final List<double> _numberProbability;
  late final List<double> _sumProbability;
  late final List<double> _parityProbability;
  late final List<double> _repeatProbability;
  late final List<List<double>> _pairLift;

  void _fit() {
    final List<double> numberCounts = List<double>.filled(40, 2);
    final List<double> sumCounts = List<double>.filled(220, 0.7);
    final List<double> parityCounts = List<double>.filled(7, 0.7);
    final List<double> repeatCounts = List<double>.filled(7, 0.7);
    final List<List<double>> pairCounts = List<List<double>>.generate(
      40,
      (_) => List<double>.filled(40, 0),
    );

    for (int drawIndex = 0; drawIndex < history.length; drawIndex++) {
      final List<int> draw = history[drawIndex];

      for (final int value in draw) {
        numberCounts[value]++;
      }

      final int sum = draw.reduce((int a, int b) => a + b);
      sumCounts[sum]++;
      parityCounts[draw.where((int value) => value.isEven).length]++;

      if (drawIndex > 0) {
        final Set<int> previous = history[drawIndex - 1].toSet();
        repeatCounts[draw.where(previous.contains).length]++;
      }

      for (int a = 0; a < draw.length; a++) {
        for (int b = a + 1; b < draw.length; b++) {
          pairCounts[draw[a]][draw[b]]++;
          pairCounts[draw[b]][draw[a]]++;
        }
      }
    }

    _numberProbability = _normalize(numberCounts.sublist(1));
    _sumProbability = _normalize(sumCounts);
    _parityProbability = _normalize(parityCounts);
    _repeatProbability = _normalize(repeatCounts);

    _pairLift = List<List<double>>.generate(
      40,
      (_) => List<double>.filled(40, 0),
    );

    for (int a = 1; a <= 39; a++) {
      for (int b = 1; b <= 39; b++) {
        final double expected = _numberProbability[a - 1] *
            _numberProbability[b - 1] *
            history.length *
            30;
        _pairLift[a][b] =
            log(1 + pairCounts[a][b]) - log(1 + expected);
      }
    }
  }

  List<double> _normalize(List<double> values) {
    final double total = values.fold<double>(0, (double a, double b) => a + b);
    return values.map((double value) => value / total).toList();
  }

  double scoreOnly(List<int> combo, List<int> latest) {
    return evaluate(combo, latest).score;
  }

  RankedCombination evaluate(List<int> combo, List<int> latest) {
    final int sum = combo.reduce((int a, int b) => a + b);
    final int evens = combo.where((int value) => value.isEven).length;
    final int repeated = combo.where(latest.contains).length;

    int consecutivePairs = 0;
    for (int index = 0; index < combo.length - 1; index++) {
      if (combo[index + 1] - combo[index] == 1) {
        consecutivePairs++;
      }
    }

    final int lows = combo.where((int value) => value <= 19).length;

    double score = 0;
    score += 2.0 * log(_sumProbability[sum] + 1e-15);
    score += 0.8 * log(_parityProbability[evens] + 1e-15);
    score += 1.2 * log(_repeatProbability[repeated] + 1e-15);

    final double frequencyScore = combo.fold<double>(
      0,
      (double value, int number) =>
          value + log(_numberProbability[number - 1] + 1e-15),
    );
    score += 0.35 * frequencyScore / 6;

    double pairScore = 0;
    for (int a = 0; a < combo.length; a++) {
      for (int b = a + 1; b < combo.length; b++) {
        pairScore += _pairLift[combo[a]][combo[b]];
      }
    }
    score += 0.45 * pairScore / 15;

    if (consecutivePairs <= 1) {
      score += 0.25;
    } else {
      score -= consecutivePairs * 0.25;
    }

    score -= (lows - 3).abs() * 0.08;

    return RankedCombination(
      numbers: List<int>.unmodifiable(combo),
      score: score,
      sum: sum,
      evens: evens,
      repeated: repeated,
    );
  }

  List<RankedCombination> rankTop({
    required List<int> latest,
    int topN = 10,
    void Function(int done, int total)? onProgress,
  }) {
    final List<RankedCombination> top = <RankedCombination>[];
    const int total = 3262623;
    int done = 0;

    void consider(RankedCombination item) {
      top.add(item);
      top.sort(
        (RankedCombination a, RankedCombination b) =>
            b.score.compareTo(a.score),
      );
      if (top.length > topN) {
        top.removeLast();
      }
    }

    for (int a = 1; a <= 34; a++) {
      for (int b = a + 1; b <= 35; b++) {
        for (int c = b + 1; c <= 36; c++) {
          for (int d = c + 1; d <= 37; d++) {
            for (int e = d + 1; e <= 38; e++) {
              for (int f = e + 1; f <= 39; f++) {
                final List<int> combo = <int>[a, b, c, d, e, f];
                consider(evaluate(combo, latest));
                done++;
                if (done % 25000 == 0) {
                  onProgress?.call(done, total);
                }
              }
            }
          }
        }
      }
    }

    onProgress?.call(total, total);
    return top;
  }
}
