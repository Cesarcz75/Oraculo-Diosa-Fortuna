class RuleScore {
  const RuleScore({
    required this.label,
    required this.weightedValue,
    required this.influence,
  });

  final String label;
  final double weightedValue;

  /// Relative share of the absolute score magnitude, from 0 to 1.
  final double influence;

  Map<String, Object> toMap() => <String, Object>{
        'label': label,
        'weightedValue': weightedValue,
        'influence': influence,
      };

  factory RuleScore.fromMap(Map<Object?, Object?> map) {
    final Object? label = map['label'];
    final Object? weightedValue = map['weightedValue'];
    final Object? influence = map['influence'];

    if (label is! String || weightedValue is! num || influence is! num) {
      throw const FormatException('Aporte de regla inválido.');
    }

    return RuleScore(
      label: label,
      weightedValue: weightedValue.toDouble(),
      influence: influence.toDouble(),
    );
  }
}

class ScoreBreakdown {
  const ScoreBreakdown({
    required this.total,
    required this.pitIndex,
    required this.rules,
  });

  /// Raw weighted score used to order the ranking.
  final double total;

  /// Internal 0–100 balance indicator based on how distributed the score is
  /// among the active rules. It is not a probability of winning.
  final double pitIndex;
  final List<RuleScore> rules;

  Map<String, Object> toMap() => <String, Object>{
        'total': total,
        'pitIndex': pitIndex,
        'rules': rules.map((RuleScore item) => item.toMap()).toList(),
      };

  factory ScoreBreakdown.fromMap(Map<Object?, Object?> map) {
    final Object? total = map['total'];
    final Object? pitIndex = map['pitIndex'];
    final Object? rawRules = map['rules'];

    if (total is! num || pitIndex is! num || rawRules is! List) {
      throw const FormatException('Desglose de puntuación inválido.');
    }

    return ScoreBreakdown(
      total: total.toDouble(),
      pitIndex: pitIndex.toDouble(),
      rules: rawRules
          .whereType<Map>()
          .map(
            (Map item) => RuleScore.fromMap(
              Map<Object?, Object?>.from(item),
            ),
          )
          .toList(growable: false),
    );
  }
}
