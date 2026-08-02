import 'dart:math';
import '../models/backtesting_result.dart';
import '../models/laboratory_experiment.dart';

class BacktestingEngine {
  const BacktestingEngine();

  BacktestingReport run({
    required LaboratoryExperiment experiment,
    required List<List<int>> history,
    required int windowSize,
    required int step,
  }) {
    if (windowSize < 20) {
      throw ArgumentError('La ventana debe tener al menos 20 sorteos.');
    }
    if (step < 1) {
      throw ArgumentError('El paso debe ser mayor que cero.');
    }
    if (history.length < windowSize) {
      throw ArgumentError(
        'El histórico es menor que el tamaño de la ventana.',
      );
    }

    final List<BacktestingWindowResult> windows =
        <BacktestingWindowResult>[];

    int windowNumber = 1;
    for (int start = 0;
        start + windowSize <= history.length;
        start += step) {
      final int endExclusive = start + windowSize;
      int matches = 0;

      for (int index = start; index < endExclusive; index++) {
        final List<int>? previousDraw =
            index == 0 ? null : history[index - 1];

        if (_matches(
          experiment: experiment,
          draw: history[index],
          previousDraw: previousDraw,
        )) {
          matches++;
        }
      }

      windows.add(
        BacktestingWindowResult(
          windowNumber: windowNumber,
          startIndex: start + 1,
          endIndex: endExclusive,
          samples: windowSize,
          matches: matches,
          matchRate: matches / windowSize,
        ),
      );
      windowNumber++;
    }

    final List<double> rates = windows
        .map((BacktestingWindowResult result) => result.matchRate)
        .toList(growable: false);

    final double average = rates.fold<double>(
          0,
          (double total, double value) => total + value,
        ) /
        rates.length;

    final double variance = rates.fold<double>(
          0,
          (double total, double value) =>
              total + pow(value - average, 2).toDouble(),
        ) /
        rates.length;

    final double standardDeviation = sqrt(variance);
    final double minimum = rates.reduce(min);
    final double maximum = rates.reduce(max);

    // A relative dispersion score. It measures stability, not prediction.
    final double relativeDispersion =
        average == 0 ? standardDeviation : standardDeviation / average;
    final double consistencyScore =
        (100 * (1 - relativeDispersion)).clamp(0, 100).toDouble();

    return BacktestingReport(
      experiment: experiment,
      windowSize: windowSize,
      step: step,
      windows: List<BacktestingWindowResult>.unmodifiable(windows),
      averageRate: average,
      minimumRate: minimum,
      maximumRate: maximum,
      standardDeviation: standardDeviation,
      consistencyScore: consistencyScore,
    );
  }

  bool _matches({
    required LaboratoryExperiment experiment,
    required List<int> draw,
    required List<int>? previousDraw,
  }) {
    switch (experiment.ruleType) {
      case ExperimentRuleType.sumRange:
        final int sum = draw.fold<int>(
          0,
          (int total, int value) => total + value,
        );
        return sum >= experiment.minimum && sum <= experiment.maximum;

      case ExperimentRuleType.exactEvenCount:
        final int evens = draw.where((int value) => value.isEven).length;
        return evens >= experiment.minimum && evens <= experiment.maximum;

      case ExperimentRuleType.maximumConsecutivePairs:
        int consecutivePairs = 0;
        for (int index = 0; index < draw.length - 1; index++) {
          if (draw[index + 1] - draw[index] == 1) {
            consecutivePairs++;
          }
        }
        return consecutivePairs >= experiment.minimum &&
            consecutivePairs <= experiment.maximum;

      case ExperimentRuleType.exactRepeatCount:
        if (previousDraw == null) {
          return false;
        }
        final Set<int> previous = previousDraw.toSet();
        final int repeats = draw.where(previous.contains).length;
        return repeats >= experiment.minimum &&
            repeats <= experiment.maximum;
    }
  }
}
