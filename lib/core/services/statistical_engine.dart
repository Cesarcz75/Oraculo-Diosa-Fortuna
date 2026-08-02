import 'dart:math';
import '../models/ranked_combination.dart';
import '../models/model_config.dart';

class StatisticalEngine {
  StatisticalEngine(this.history, this.config) {
    if (history.length < 20) {
      throw ArgumentError('Se requieren al menos 20 sorteos.');
    }
    _fit();
  }

  final List<List<int>> history;
  final ModelConfig config;

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

      sumCounts[draw.reduce((int a, int b) => a + b)]++;
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
    final double total = values.fold<double>(
      0,
      (double a, double b) => a + b,
    );
    return values.map((double value) => value / total).toList();
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

    final Map<String, double> contributions = <String, double>{};
    final RuleConfig sumRule = config.rule('sum');
    final RuleConfig parityRule = config.rule('parity');
    final RuleConfig repeatRule = config.rule('repeat');
    final RuleConfig frequencyRule = config.rule('numberFrequency');
    final RuleConfig pairRule = config.rule('pairLift');
    final RuleConfig consecutiveRule = config.rule('consecutive');
    final RuleConfig lowHighRule = config.rule('lowHigh');

    if (sumRule.enabled) {
      contributions['Suma histórica'] =
          sumRule.weight * log(_sumProbability[sum] + 1e-15);
    }
    if (parityRule.enabled) {
      contributions['Paridad'] =
          parityRule.weight * log(_parityProbability[evens] + 1e-15);
    }
    if (repeatRule.enabled) {
      contributions['Repetición'] =
          repeatRule.weight * log(_repeatProbability[repeated] + 1e-15);
    }

    final double frequencyScore = combo.fold<double>(
      0,
      (double value, int number) =>
          value + log(_numberProbability[number - 1] + 1e-15),
    );
    if (frequencyRule.enabled) {
      contributions['Frecuencia individual'] =
          frequencyRule.weight * frequencyScore / 6;
    }

    double pairScore = 0;
    for (int a = 0; a < combo.length; a++) {
      for (int b = a + 1; b < combo.length; b++) {
        pairScore += _pairLift[combo[a]][combo[b]];
      }
    }
    if (pairRule.enabled) {
      contributions['Pares históricos'] =
          pairRule.weight * pairScore / 15;
    }

    if (consecutiveRule.enabled) {
      contributions['Consecutivos'] = consecutivePairs <= 1
          ? consecutiveRule.weight
          : -(consecutivePairs * consecutiveRule.weight);
    }
    if (lowHighRule.enabled) {
      contributions['Bajos y altos'] =
          -(lows - 3).abs() * lowHighRule.weight;
    }

    final double score = contributions.values.fold<double>(
      0,
      (double total, double value) => total + value,
    );

    return RankedCombination(
      numbers: List<int>.unmodifiable(combo),
      score: score,
      sum: sum,
      evens: evens,
      repeated: repeated,
      contributions: Map<String, double>.unmodifiable(contributions),
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
                consider(
                  evaluate(<int>[a, b, c, d, e, f], latest),
                );
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
