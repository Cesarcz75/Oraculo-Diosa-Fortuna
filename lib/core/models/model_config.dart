class RuleConfig {
  const RuleConfig({
    required this.key,
    required this.id,
    required this.label,
    required this.category,
    required this.description,
    required this.status,
    required this.evidenceLevel,
    required this.author,
    required this.introducedVersion,
    required this.enabled,
    required this.weight,
  });

  final String key;
  final String id;
  final String label;
  final String category;
  final String description;
  final String status;
  final int evidenceLevel;
  final String author;
  final String introducedVersion;
  final bool enabled;
  final double weight;

  factory RuleConfig.fromMap(String key, Map<String, dynamic> map) {
    return RuleConfig(
      key: key,
      id: map['id'] as String? ?? 'PIT-${key.toUpperCase()}',
      label: map['label'] as String? ?? key,
      category: map['category'] as String? ?? 'Estadística',
      description: map['description'] as String? ??
          'Regla estadística utilizada por el Motor Fortuna.',
      status: map['status'] as String? ?? 'Experimental',
      evidenceLevel: (map['evidenceLevel'] as num? ?? 1).toInt().clamp(1, 5),
      author: map['author'] as String? ?? 'PRIME Innovation Thinking',
      introducedVersion: map['introducedVersion'] as String? ?? '3.5.0',
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
      id: 'PIT-${key.toUpperCase()}',
      label: key,
      category: 'Sin clasificar',
      description: 'Esta regla no está registrada en la biblioteca PIT.',
      status: 'Inactiva',
      evidenceLevel: 1,
      author: 'PRIME Innovation Thinking',
      introducedVersion: engineVersion,
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
      engineVersion: map['engineVersion'] as String? ?? '3.5.0',
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
