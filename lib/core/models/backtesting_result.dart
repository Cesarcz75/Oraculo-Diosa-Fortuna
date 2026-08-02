import 'laboratory_experiment.dart';

class BacktestingWindowResult {
  const BacktestingWindowResult({
    required this.windowNumber,
    required this.startIndex,
    required this.endIndex,
    required this.samples,
    required this.matches,
    required this.matchRate,
  });

  final int windowNumber;
  final int startIndex;
  final int endIndex;
  final int samples;
  final int matches;
  final double matchRate;
}

class BacktestingReport {
  const BacktestingReport({
    required this.experiment,
    required this.windowSize,
    required this.step,
    required this.windows,
    required this.averageRate,
    required this.minimumRate,
    required this.maximumRate,
    required this.standardDeviation,
    required this.consistencyScore,
  });

  final LaboratoryExperiment experiment;
  final int windowSize;
  final int step;
  final List<BacktestingWindowResult> windows;
  final double averageRate;
  final double minimumRate;
  final double maximumRate;
  final double standardDeviation;
  final double consistencyScore;

  String get conclusion {
    if (windows.length < 3) {
      return 'Se requieren más ventanas para una conclusión sólida';
    }
    if (consistencyScore >= 90) {
      return 'Consistencia temporal muy alta';
    }
    if (consistencyScore >= 75) {
      return 'Consistencia temporal alta';
    }
    if (consistencyScore >= 55) {
      return 'Consistencia temporal moderada';
    }
    return 'Consistencia temporal baja';
  }
}
