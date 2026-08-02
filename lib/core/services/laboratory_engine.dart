import '../models/laboratory_experiment.dart';

class LaboratoryEngine {
  const LaboratoryEngine();

  ExperimentResult evaluate({
    required LaboratoryExperiment experiment,
    required List<List<int>> history,
    double trainingFraction = 0.70,
  }) {
    if (history.length < 40) {
      throw ArgumentError('Se requieren al menos 40 sorteos.');
    }
    if (trainingFraction <= 0 || trainingFraction >= 1) {
      throw ArgumentError('La fracción de entrenamiento debe estar entre 0 y 1.');
    }

    final int splitIndex =
        (history.length * trainingFraction).floor().clamp(20, history.length - 20);

    int trainingMatches = 0;
    int validationMatches = 0;

    for (int index = 0; index < history.length; index++) {
      final bool matches = _matches(
        experiment: experiment,
        draw: history[index],
        previousDraw: index == 0 ? null : history[index - 1],
      );

      if (index < splitIndex) {
        if (matches) {
          trainingMatches++;
        }
      } else if (matches) {
        validationMatches++;
      }
    }

    final int trainingSamples = splitIndex;
    final int validationSamples = history.length - splitIndex;
    final double trainingRate = trainingMatches / trainingSamples;
    final double validationRate = validationMatches / validationSamples;
    final double absoluteGap = (trainingRate - validationRate).abs();

    // Measures temporal consistency only; it is not a prediction metric.
    final double stabilityScore =
        (100 * (1 - absoluteGap)).clamp(0, 100).toDouble();

    return ExperimentResult(
      experiment: experiment,
      trainingSamples: trainingSamples,
      validationSamples: validationSamples,
      trainingMatches: trainingMatches,
      validationMatches: validationMatches,
      trainingRate: trainingRate,
      validationRate: validationRate,
      absoluteGap: absoluteGap,
      stabilityScore: stabilityScore,
    );
  }

  bool _matches({
    required LaboratoryExperiment experiment,
    required List<int> draw,
    required List<int>? previousDraw,
  }) {
    switch (experiment.ruleType) {
      case ExperimentRuleType.sumRange:
        final int sum = draw.fold<int>(0, (int total, int value) => total + value);
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
        return repeats >= experiment.minimum && repeats <= experiment.maximum;
    }
  }
}
