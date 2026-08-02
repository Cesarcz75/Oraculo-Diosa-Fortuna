class RuleConfig {
  const RuleConfig({
    required this.key,
    required this.label,
    required this.enabled,
    required this.weight,
  });

  final String key;
  final String label;
  final bool enabled;
  final double weight;

  factory RuleConfig.fromMap(String key, Map<String, dynamic> map) {
    return RuleConfig(
      key: key,
      label: map['label'] as String? ?? key,
      enabled: map['enabled'] as bool? ?? true,
      weight: (map['weight'] as num? ?? 0).toDouble(),
    );
  }
}

class ModelConfig {
  const ModelConfig({
    required this.modelName,
    required this.engineName,
    required this.engineVersion,
    required this.rules,
    required this.disclaimer,
  });

  final String modelName;
  final String engineName;
  final String engineVersion;
  final List<RuleConfig> rules;
  final String disclaimer;

  RuleConfig rule(String key) {
    for (final RuleConfig rule in rules) {
      if (rule.key == key) {
        return rule;
      }
    }
    return RuleConfig(
      key: key,
      label: key,
      enabled: false,
      weight: 0,
    );
  }

  factory ModelConfig.fromMap(Map<String, dynamic> map) {
    final Map<String, dynamic> rawRules =
        Map<String, dynamic>.from(map['rules'] as Map? ?? <String, dynamic>{});

    return ModelConfig(
      modelName: map['modelName'] as String? ?? 'Modelo Oficial PIT',
      engineName: map['engineName'] as String? ?? 'Motor Fortuna',
      engineVersion: map['engineVersion'] as String? ?? '3.2.0',
      rules: rawRules.entries
          .map(
            (MapEntry<String, dynamic> entry) => RuleConfig.fromMap(
              entry.key,
              Map<String, dynamic>.from(entry.value as Map),
            ),
          )
          .toList(growable: false),
      disclaimer: map['disclaimer'] as String? ??
          'El índice de ajuste no representa una probabilidad de ganar.',
    );
  }
}
