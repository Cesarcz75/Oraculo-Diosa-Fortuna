
import 'dart:math';
import 'statistical_engine.dart';

class QuickBacktestResult {
  const QuickBacktestResult({
    required this.drawsTested,
    required this.averageHitsModel,
    required this.averageHitsRandom,
    required this.modelThreePlus,
    required this.randomThreePlus,
  });

  final int drawsTested;
  final double averageHitsModel;
  final double averageHitsRandom;
  final int modelThreePlus;
  final int randomThreePlus;
}

class QuickBacktester {
  const QuickBacktester();

  QuickBacktestResult run(
    List<List<int>> history, {
    int drawsToTest = 30,
    int randomCandidates = 25000,
    int seed = 20260801,
  }) {
    if (history.length < drawsToTest + 100) {
      throw ArgumentError('Histórico insuficiente para la validación.');
    }

    final rng = Random(seed);
    var modelHitsTotal = 0;
    var randomHitsTotal = 0;
    var modelThreePlus = 0;
    var randomThreePlus = 0;

    final start = history.length - drawsToTest;
    for (var index = start; index < history.length; index++) {
      final train = history.sublist(0, index);
      final actual = history[index].toSet();
      final latest = train.last;

      final engine = StatisticalEngine(train);
      final modelCandidate = _bestOfRandomSample(
        engine,
        latest,
        randomCandidates,
        rng,
      );
      final randomCandidate = _randomCombination(rng);

      final modelHits = modelCandidate.where(actual.contains).length;
      final randomHits = randomCandidate.where(actual.contains).length;

      modelHitsTotal += modelHits;
      randomHitsTotal += randomHits;
      if (modelHits >= 3) modelThreePlus++;
      if (randomHits >= 3) randomThreePlus++;
    }

    return QuickBacktestResult(
      drawsTested: drawsToTest,
      averageHitsModel: modelHitsTotal / drawsToTest,
      averageHitsRandom: randomHitsTotal / drawsToTest,
      modelThreePlus: modelThreePlus,
      randomThreePlus: randomThreePlus,
    );
  }

  List<int> _bestOfRandomSample(
    StatisticalEngine engine,
    List<int> latest,
    int samples,
    Random rng,
  ) {
    RankedScore? best;
    for (var i = 0; i < samples; i++) {
      final combo = _randomCombination(rng);
      final score = engine.scoreOnly(combo, latest);
      if (best == null || score > best.score) {
        best = RankedScore(combo, score);
      }
    }
    return best!.numbers;
  }

  List<int> _randomCombination(Random rng) {
    final set = <int>{};
    while (set.length < 6) {
      set.add(rng.nextInt(39) + 1);
    }
    final result = set.toList()..sort();
    return result;
  }
}

class RankedScore {
  const RankedScore(this.numbers, this.score);

  final List<int> numbers;
  final double score;
}
