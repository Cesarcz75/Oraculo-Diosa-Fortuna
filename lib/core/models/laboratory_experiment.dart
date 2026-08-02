enum ExperimentRuleType {
  sumRange,
  exactEvenCount,
  maximumConsecutivePairs,
  exactRepeatCount,
}

extension ExperimentRuleTypeLabel on ExperimentRuleType {
  String get label {
    switch (this) {
      case ExperimentRuleType.sumRange:
        return 'Rango de suma';
      case ExperimentRuleType.exactEvenCount:
        return 'Cantidad exacta de pares';
      case ExperimentRuleType.maximumConsecutivePairs:
        return 'Máximo de parejas consecutivas';
      case ExperimentRuleType.exactRepeatCount:
        return 'Repetidos respecto al sorteo anterior';
    }
  }
}

class LaboratoryExperiment {
  const LaboratoryExperiment({
    required this.id,
    required this.name,
    required this.description,
    required this.ruleType,
    required this.minimum,
    required this.maximum,
    required this.createdAt,
  });

  final String id;
  final String name;
  final String description;
  final ExperimentRuleType ruleType;
  final int minimum;
  final int maximum;
  final DateTime createdAt;

  LaboratoryExperiment copyWith({
    String? id,
    String? name,
    String? description,
    ExperimentRuleType? ruleType,
    int? minimum,
    int? maximum,
    DateTime? createdAt,
  }) {
    return LaboratoryExperiment(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      ruleType: ruleType ?? this.ruleType,
      minimum: minimum ?? this.minimum,
      maximum: maximum ?? this.maximum,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class ExperimentResult {
  const ExperimentResult({
    required this.experiment,
    required this.trainingSamples,
    required this.validationSamples,
    required this.trainingMatches,
    required this.validationMatches,
    required this.trainingRate,
    required this.validationRate,
    required this.absoluteGap,
    required this.stabilityScore,
  });

  final LaboratoryExperiment experiment;
  final int trainingSamples;
  final int validationSamples;
  final int trainingMatches;
  final int validationMatches;
  final double trainingRate;
  final double validationRate;
  final double absoluteGap;
  final double stabilityScore;

  String get conclusion {
    if (validationSamples < 30) {
      return 'Muestra de validación insuficiente';
    }
    if (stabilityScore >= 90) {
      return 'Comportamiento muy estable';
    }
    if (stabilityScore >= 75) {
      return 'Comportamiento estable';
    }
    if (stabilityScore >= 55) {
      return 'Estabilidad moderada';
    }
    return 'Comportamiento inestable';
  }
}

class ManagedExperiment {
  const ManagedExperiment({
    required this.result,
    this.archived = false,
  });

  final ExperimentResult result;
  final bool archived;

  ManagedExperiment copyWith({
    ExperimentResult? result,
    bool? archived,
  }) {
    return ManagedExperiment(
      result: result ?? this.result,
      archived: archived ?? this.archived,
    );
  }
}
