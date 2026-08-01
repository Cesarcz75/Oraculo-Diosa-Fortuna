
import 'dart:math';
import 'models.dart';

class StatisticalEngine {
  StatisticalEngine(this.history) {
    if (history.length < 20) {
      throw ArgumentError('El histórico requiere al menos 20 sorteos.');
    }
    _fit();
  }

  final List<List<int>> history;

  late final List<double> _numberFrequency;
  late final List<double> _sumProbability;
  late final List<double> _parityProbability;
  late final List<double> _repeatProbability;
  late final List<List<double>> _pairLift;

  List<int> get lastDraw => history.last;
  List<int> get previousDraw => history[history.length - 2];

  void _fit() {
    final numberCounts = List<double>.filled(40, 2);
    final sumCounts = List<double>.filled(220, .7);
    final parityCounts = List<double>.filled(7, .7);
    final repeatCounts = List<double>.filled(7, .7);
    final pairCounts = List.generate(40, (_) => List<double>.filled(40, 0));

    for (var i = 0; i < history.length; i++) {
      final draw = history[i];
      for (final n in draw) {
        numberCounts[n]++;
      }
      sumCounts[draw.reduce((a, b) => a + b)]++;
      parityCounts[draw.where((n) => n.isEven).length]++;

      if (i > 0) {
        final previous = history[i - 1].toSet();
        repeatCounts[draw.where(previous.contains).length]++;
      }

      for (var a = 0; a < draw.length; a++) {
        for (var b = a + 1; b < draw.length; b++) {
          pairCounts[draw[a]][draw[b]]++;
          pairCounts[draw[b]][draw[a]]++;
        }
      }
    }

    _numberFrequency = _normalize(numberCounts.sublist(1));
    _sumProbability = _normalize(sumCounts);
    _parityProbability = _normalize(parityCounts);
    _repeatProbability = _normalize(repeatCounts);

    _pairLift = List.generate(40, (_) => List<double>.filled(40, 0));
    for (var a = 1; a <= 39; a++) {
      for (var b = 1; b <= 39; b++) {
        final expected = _numberFrequency[a - 1] *
            _numberFrequency[b - 1] *
            history.length *
            30;
        _pairLift[a][b] =
            log(1 + pairCounts[a][b]) - log(1 + expected);
      }
    }
  }

  List<double> _normalize(List<double> values) {
    final total = values.fold<double>(0, (a, b) => a + b);
    return values.map((value) => value / total).toList();
  }

  List<RankedCombination> rankTop({
    required List<int> latestDraw,
    int topN = 10,
    void Function(int done, int total)? onProgress,
  }) {
    final latest = [...latestDraw]..sort();
    final candidates = <RankedCombination>[];
    const total = 3262623;
    var done = 0;

    void consider(RankedCombination item) {
      candidates.add(item);
      candidates.sort((a, b) => b.score.compareTo(a.score));
      if (candidates.length > topN) {
        candidates.removeLast();
      }
    }

    for (var a = 1; a <= 34; a++) {
      for (var b = a + 1; b <= 35; b++) {
        for (var c = b + 1; c <= 36; c++) {
          for (var d = c + 1; d <= 37; d++) {
            for (var e = d + 1; e <= 38; e++) {
              for (var f = e + 1; f <= 39; f++) {
                final combo = [a, b, c, d, e, f];
                consider(_evaluate(combo, latest));
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
    return candidates;
  }

  double scoreOnly(List<int> combo, List<int> latest) {
    return _evaluate(combo, latest).score;
  }

  RankedCombination _evaluate(List<int> combo, List<int> latest) {
    final sum = combo.reduce((a, b) => a + b);
    final evens = combo.where((n) => n.isEven).length;
    final repeated = combo.where(latest.contains).length;
    var consecutivePairs = 0;
    for (var i = 0; i < 5; i++) {
      if (combo[i + 1] - combo[i] == 1) consecutivePairs++;
    }

    var score = 0.0;
    score += 2.0 * log(_sumProbability[sum] + 1e-15);
    score += .8 * log(_parityProbability[evens] + 1e-15);
    score += 1.2 * log(_repeatProbability[repeated] + 1e-15);

    final frequencyScore = combo.fold<double>(
      0,
      (value, n) => value + log(_numberFrequency[n - 1] + 1e-15),
    );
    score += .35 * frequencyScore / 6;

    var pairScore = 0.0;
    for (var i = 0; i < 6; i++) {
      for (var j = i + 1; j < 6; j++) {
        pairScore += _pairLift[combo[i]][combo[j]];
      }
    }
    score += .45 * pairScore / 15;

    // Suave preferencia histórica: 0 o 1 pareja consecutiva.
    if (consecutivePairs == 0 || consecutivePairs == 1) {
      score += .25;
    } else {
      score -= consecutivePairs * .25;
    }

    // Equilibrio bajos/altos como peso suave.
    final lows = combo.where((n) => n <= 19).length;
    score -= (lows - 3).abs() * .08;

    return RankedCombination(
      numbers: combo,
      score: score,
      sum: sum,
      evens: evens,
      repeated: repeated,
    );
  }
}
