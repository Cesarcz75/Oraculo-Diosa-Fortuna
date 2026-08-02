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

  static ExperimentRuleType fromName(String value) {
    return ExperimentRuleType.values.firstWhere(
      (ExperimentRuleType type) => type.name == value,
      orElse: () => ExperimentRuleType.sumRange,
    );
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

  Map<String, Object> toMap() {
    return <String, Object>{
      'id': id,
      'name': name,
      'description': description,
      'ruleType': ruleType.name,
      'minimum': minimum,
      'maximum': maximum,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory LaboratoryExperiment.fromMap(Map<String, dynamic> map) {
    return LaboratoryExperiment(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? 'Experimento',
      description: map['description'] as String? ?? '',
      ruleType: ExperimentRuleTypeLabel.fromName(
        map['ruleType'] as String? ?? '',
      ),
      minimum: (map['minimum'] as num? ?? 0).toInt(),
      maximum: (map['maximum'] as num? ?? 0).toInt(),
      createdAt: DateTime.tryParse(map['createdAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
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

  Map<String, Object> toMap() {
    return <String, Object>{
      'experiment': experiment.toMap(),
      'trainingSamples': trainingSamples,
      'validationSamples': validationSamples,
      'trainingMatches': trainingMatches,
      'validationMatches': validationMatches,
      'trainingRate': trainingRate,
      'validationRate': validationRate,
      'absoluteGap': absoluteGap,
      'stabilityScore': stabilityScore,
    };
  }

  factory ExperimentResult.fromMap(Map<String, dynamic> map) {
    return ExperimentResult(
      experiment: LaboratoryExperiment.fromMap(
        Map<String, dynamic>.from(
          map['experiment'] as Map? ?? <String, dynamic>{},
        ),
      ),
      trainingSamples: (map['trainingSamples'] as num? ?? 0).toInt(),
      validationSamples: (map['validationSamples'] as num? ?? 0).toInt(),
      trainingMatches: (map['trainingMatches'] as num? ?? 0).toInt(),
      validationMatches: (map['validationMatches'] as num? ?? 0).toInt(),
      trainingRate: (map['trainingRate'] as num? ?? 0).toDouble(),
      validationRate: (map['validationRate'] as num? ?? 0).toDouble(),
      absoluteGap: (map['absoluteGap'] as num? ?? 0).toDouble(),
      stabilityScore: (map['stabilityScore'] as num? ?? 0).toDouble(),
    );
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

  Map<String, Object> toMap() {
    return <String, Object>{
      'result': result.toMap(),
      'archived': archived,
    };
  }

  factory ManagedExperiment.fromMap(Map<String, dynamic> map) {
    return ManagedExperiment(
      result: ExperimentResult.fromMap(
        Map<String, dynamic>.from(
          map['result'] as Map? ?? <String, dynamic>{},
        ),
      ),
      archived: map['archived'] as bool? ?? false,
    );
  }
}
