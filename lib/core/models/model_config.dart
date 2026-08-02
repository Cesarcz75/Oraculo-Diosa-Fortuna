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

  RuleConfig copyWith({bool? enabled, double? weight}) {
    return RuleConfig(
      key: key,
      id: id,
      label: label,
      category: category,
      description: description,
      status: status,
      evidenceLevel: evidenceLevel,
      author: author,
      introducedVersion: introducedVersion,
      enabled: enabled ?? this.enabled,
      weight: weight ?? this.weight,
    );
  }

  Map<String, Object> toMap() => <String, Object>{
        'id': id,
        'label': label,
        'category': category,
        'description': description,
        'status': status,
        'evidenceLevel': evidenceLevel,
        'author': author,
        'introducedVersion': introducedVersion,
        'enabled': enabled,
        'weight': weight,
      };

  factory RuleConfig.fromMap(String key, Map<String, dynamic> map) {
    return RuleConfig(
      key: key,
      id: map['id'] as String? ?? 'PIT-${key.toUpperCase()}',
      label: map['label'] as String? ?? key,
      category: map['category'] as String? ?? 'Estadística',
      description: map['description'] as String? ??
          'Regla estadística utilizada por el Motor Fortuna.',
      status: map['status'] as String? ?? 'Experimental',
      evidenceLevel:
          (map['evidenceLevel'] as num? ?? 1).toInt().clamp(1, 5),
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
    required this.modelVersion,
    required this.engineName,
    required this.engineVersion,
    required this.rules,
    required this.disclaimer,
    this.updatedAt,
    this.changeNote = '',
  });

  final String modelName;
  final String modelVersion;
  final String engineName;
  final String engineVersion;
  final List<RuleConfig> rules;
  final String disclaimer;
  final DateTime? updatedAt;
  final String changeNote;

  ModelConfig copyWith({
    String? modelVersion,
    List<RuleConfig>? rules,
    DateTime? updatedAt,
    String? changeNote,
  }) {
    return ModelConfig(
      modelName: modelName,
      modelVersion: modelVersion ?? this.modelVersion,
      engineName: engineName,
      engineVersion: engineVersion,
      rules: rules ?? this.rules,
      disclaimer: disclaimer,
      updatedAt: updatedAt ?? this.updatedAt,
      changeNote: changeNote ?? this.changeNote,
    );
  }

  RuleConfig rule(String key) {
    for (final RuleConfig rule in rules) {
      if (rule.key == key) return rule;
    }
    return RuleConfig(
      key: key,
      id: 'PIT-${key.toUpperCase()}',
      label: key,
      category: 'Sin clasificar',
      description: 'Regla no registrada.',
      status: 'Inactiva',
      evidenceLevel: 1,
      author: 'PRIME Innovation Thinking',
      introducedVersion: engineVersion,
      enabled: false,
      weight: 0,
    );
  }

  Map<String, Object> toMap() => <String, Object>{
        'modelName': modelName,
        'modelVersion': modelVersion,
        'engineName': engineName,
        'engineVersion': engineVersion,
        'rules': <String, Object>{
          for (final RuleConfig rule in rules) rule.key: rule.toMap(),
        },
        'disclaimer': disclaimer,
        if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
        'changeNote': changeNote,
      };

  factory ModelConfig.fromMap(Map<String, dynamic> map) {
    final Map<String, dynamic> rawRules =
        Map<String, dynamic>.from(map['rules'] as Map? ?? <String, dynamic>{});
    return ModelConfig(
      modelName: map['modelName'] as String? ?? 'Modelo Oficial PIT',
      modelVersion: map['modelVersion'] as String? ?? '1.0.0',
      engineName: map['engineName'] as String? ?? 'Motor Fortuna',
      engineVersion: map['engineVersion'] as String? ?? '4.0.0',
      rules: rawRules.entries
          .map((entry) => RuleConfig.fromMap(
                entry.key,
                Map<String, dynamic>.from(entry.value as Map),
              ))
          .toList(growable: false),
      disclaimer: map['disclaimer'] as String? ??
          'El índice de ajuste no representa una probabilidad de ganar.',
      updatedAt: DateTime.tryParse(map['updatedAt'] as String? ?? ''),
      changeNote: map['changeNote'] as String? ?? '',
    );
  }
}
