import '../models/athena_response.dart';
import '../models/model_config.dart';
import '../models/ranked_combination.dart';

class AthenaEngine {
  const AthenaEngine();

  AthenaResponse answer({
    required String question,
    required ModelConfig model,
    required List<ModelConfig> modelHistory,
    required List<List<int>> drawHistory,
    required List<RankedCombination> ranking,
  }) {
    final String normalized = _normalize(question);

    if (_containsAny(normalized, <String>[
      'regla mayor peso',
      'regla mas peso',
      'peso mayor',
      'mayor peso',
    ])) {
      return _highestWeight(model);
    }

    if (_containsAny(normalized, <String>[
      'mayor evidencia',
      'regla mas evidencia',
      'evidencia mayor',
    ])) {
      return _highestEvidence(model);
    }

    if (_containsAny(normalized, <String>[
      'cambio',
      'version',
      'historial modelo',
      'ultima version',
    ])) {
      return _modelChanges(model, modelHistory);
    }

    if (_containsAny(normalized, <String>[
      'numero frecuente',
      'numeros frecuentes',
      'mas frecuente',
      'calientes',
    ])) {
      return _numberFrequency(drawHistory, hottest: true);
    }

    if (_containsAny(normalized, <String>[
      'numero menos frecuente',
      'numeros menos frecuentes',
      'frios',
      'menos frecuente',
    ])) {
      return _numberFrequency(drawHistory, hottest: false);
    }

    if (_containsAny(normalized, <String>[
      'ranking',
      'primer lugar',
      'mejor combinacion',
      'top 1',
    ])) {
      return _rankingLeader(ranking);
    }

    if (_containsAny(normalized, <String>[
      'salud',
      'estado modelo',
      'resumen modelo',
      'como esta el modelo',
    ])) {
      return _modelHealth(model, modelHistory, drawHistory);
    }

    if (_containsAny(normalized, <String>[
      'suma promedio',
      'promedio suma',
      'paridad promedio',
      'resumen historico',
    ])) {
      return _historicalSummary(drawHistory);
    }

    return AthenaResponse(
      title: 'Consulta no reconocida',
      summary:
          'ATHENA trabaja con preguntas concretas sobre el Modelo PIT, '
          'el histórico y el ranking actual.',
      details: const <String>[
        'Prueba: ¿Cuál regla tiene mayor peso?',
        'Prueba: ¿Qué cambió en la última versión?',
        'Prueba: ¿Cuáles son los números más frecuentes?',
        'Prueba: ¿Cómo está la salud del modelo?',
        'Prueba: Explícame el primer lugar del ranking.',
      ],
      category: 'Ayuda',
    );
  }

  List<String> suggestions() => const <String>[
        '¿Cómo está la salud del modelo?',
        '¿Cuál regla tiene mayor peso?',
        '¿Cuál regla tiene mayor evidencia?',
        '¿Qué cambió en la última versión?',
        '¿Cuáles son los números más frecuentes?',
        '¿Cuáles son los números menos frecuentes?',
        'Explícame el primer lugar del ranking.',
        'Dame un resumen histórico.',
      ];

  AthenaResponse _highestWeight(ModelConfig model) {
    final List<RuleConfig> active = model.rules
        .where((RuleConfig rule) => rule.enabled)
        .toList(growable: false);

    if (active.isEmpty) {
      return const AthenaResponse(
        title: 'Reglas sin activar',
        summary: 'El Modelo PIT no tiene reglas activas.',
        details: <String>[
          'Activa al menos una regla desde Configuración.',
        ],
        category: 'Modelo PIT',
      );
    }

    final RuleConfig winner = active.reduce(
      (RuleConfig a, RuleConfig b) => a.weight >= b.weight ? a : b,
    );

    final List<RuleConfig> ordered = List<RuleConfig>.from(active)
      ..sort(
        (RuleConfig a, RuleConfig b) => b.weight.compareTo(a.weight),
      );

    return AthenaResponse(
      title: 'Regla con mayor peso',
      summary:
          '${winner.id} · ${winner.label} lidera con peso '
          '${winner.weight.toStringAsFixed(2)}.',
      details: ordered
          .take(5)
          .map(
            (RuleConfig rule) =>
                '${rule.id} · ${rule.label}: '
                '${rule.weight.toStringAsFixed(2)}',
          )
          .toList(growable: false),
      category: 'Modelo PIT',
    );
  }

  AthenaResponse _highestEvidence(ModelConfig model) {
    if (model.rules.isEmpty) {
      return const AthenaResponse(
        title: 'Sin reglas registradas',
        summary: 'No hay reglas para evaluar.',
        details: <String>[],
        category: 'Centro PIT',
      );
    }

    final List<RuleConfig> ordered = List<RuleConfig>.from(model.rules)
      ..sort((RuleConfig a, RuleConfig b) {
        final int evidence =
            b.evidenceLevel.compareTo(a.evidenceLevel);
        if (evidence != 0) return evidence;
        return b.weight.compareTo(a.weight);
      });

    final RuleConfig winner = ordered.first;

    return AthenaResponse(
      title: 'Mayor evidencia registrada',
      summary:
          '${winner.id} · ${winner.label} tiene nivel '
          '${winner.evidenceLevel} de 5.',
      details: ordered
          .take(5)
          .map(
            (RuleConfig rule) =>
                '${rule.id} · ${rule.label}: '
                '${rule.evidenceLevel}/5 · ${rule.status}',
          )
          .toList(growable: false),
      category: 'Centro PIT',
    );
  }

  AthenaResponse _modelChanges(
    ModelConfig active,
    List<ModelConfig> history,
  ) {
    if (history.isEmpty) {
      return AthenaResponse(
        title: 'Sin historial de versiones',
        summary:
            'El modelo activo es v${active.modelVersion}, pero todavía '
            'no existen versiones guardadas para comparar.',
        details: <String>[
          'Motor: ${active.engineName} v${active.engineVersion}',
          'Reglas activas: ${active.activeRuleCount}',
        ],
        category: 'Versionado',
      );
    }

    final ModelConfig previous = history.firstWhere(
      (ModelConfig item) =>
          item.modelVersion != active.modelVersion,
      orElse: () => history.first,
    );

    final Map<String, RuleConfig> activeRules = <String, RuleConfig>{
      for (final RuleConfig rule in active.rules) rule.key: rule,
    };
    final Map<String, RuleConfig> previousRules = <String, RuleConfig>{
      for (final RuleConfig rule in previous.rules) rule.key: rule,
    };

    final List<String> changes = <String>[];
    final Set<String> keys = <String>{
      ...activeRules.keys,
      ...previousRules.keys,
    };

    for (final String key in keys) {
      final RuleConfig? current = activeRules[key];
      final RuleConfig? old = previousRules[key];

      if (old == null && current != null) {
        changes.add('${current.label}: agregada.');
        continue;
      }
      if (current == null && old != null) {
        changes.add('${old.label}: eliminada.');
        continue;
      }
      if (current == null || old == null) continue;

      if (current.enabled != old.enabled) {
        changes.add(
          '${current.label}: '
          '${current.enabled ? 'activada' : 'desactivada'}.',
        );
      }
      if ((current.weight - old.weight).abs() >= 0.001) {
        changes.add(
          '${current.label}: peso '
          '${old.weight.toStringAsFixed(2)} → '
          '${current.weight.toStringAsFixed(2)}.',
        );
      }
    }

    return AthenaResponse(
      title: 'Cambios del Modelo PIT',
      summary:
          'Comparación v${previous.modelVersion} → '
          'v${active.modelVersion}.',
      details: changes.isEmpty
          ? <String>[
              'No se detectaron diferencias en reglas o pesos.',
              if (active.changeNote.isNotEmpty)
                'Nota actual: ${active.changeNote}',
            ]
          : changes,
      category: 'Versionado',
    );
  }

  AthenaResponse _numberFrequency(
    List<List<int>> history, {
    required bool hottest,
  }) {
    if (history.isEmpty) {
      return const AthenaResponse(
        title: 'Histórico vacío',
        summary: 'No hay sorteos cargados.',
        details: <String>[],
        category: 'Histórico',
      );
    }

    final List<int> counts = List<int>.filled(40, 0);
    for (final List<int> draw in history) {
      for (final int number in draw) {
        if (number >= 1 && number <= 39) counts[number]++;
      }
    }

    final List<MapEntry<int, int>> ordered =
        List<MapEntry<int, int>>.generate(
      39,
      (int index) => MapEntry<int, int>(index + 1, counts[index + 1]),
    )..sort(
            (MapEntry<int, int> a, MapEntry<int, int> b) => hottest
                ? b.value.compareTo(a.value)
                : a.value.compareTo(b.value),
          );

    final List<MapEntry<int, int>> selected = ordered.take(8).toList();

    return AthenaResponse(
      title: hottest
          ? 'Números más frecuentes'
          : 'Números menos frecuentes',
      summary:
          'Análisis descriptivo de ${history.length} sorteos cargados.',
      details: selected
          .map(
            (MapEntry<int, int> item) =>
                'Número ${item.key}: ${item.value} apariciones.',
          )
          .toList(growable: false),
      category: 'Histórico',
    );
  }

  AthenaResponse _rankingLeader(List<RankedCombination> ranking) {
    if (ranking.isEmpty) {
      return const AthenaResponse(
        title: 'Ranking no generado',
        summary:
            'Genera un Top desde el Dashboard para analizar su primer lugar.',
        details: <String>[],
        category: 'Ranking',
      );
    }

    final RankedCombination leader = ranking.first;
    final List<MapEntry<String, double>> contributions =
        leader.contributions.entries.toList()
          ..sort(
            (MapEntry<String, double> a, MapEntry<String, double> b) =>
                b.value.abs().compareTo(a.value.abs()),
          );

    return AthenaResponse(
      title: 'Primer lugar del ranking',
      summary:
          '${leader.label} · Score ${leader.score.toStringAsFixed(3)} · '
          'Índice PIT ${leader.pitIndex.toStringAsFixed(1)}.',
      details: <String>[
        'Suma: ${leader.sum}.',
        'Paridad: ${leader.evens} pares / ${leader.odds} impares.',
        'Repetidos: ${leader.repeated}.',
        ...contributions.take(5).map(
              (MapEntry<String, double> entry) =>
                  '${entry.key}: ${entry.value.toStringAsFixed(3)}.',
            ),
      ],
      category: 'Ranking',
    );
  }

  AthenaResponse _modelHealth(
    ModelConfig model,
    List<ModelConfig> history,
    List<List<int>> drawHistory,
  ) {
    final int active = model.activeRuleCount;
    final double evidenceAverage = model.rules.isEmpty
        ? 0
        : model.rules.fold<int>(
              0,
              (int total, RuleConfig rule) =>
                  total + rule.evidenceLevel,
            ) /
            model.rules.length;
    final double totalWeight = model.rules
        .where((RuleConfig rule) => rule.enabled)
        .fold<double>(
          0,
          (double total, RuleConfig rule) => total + rule.weight,
        );

    final String state;
    if (active >= 5 && evidenceAverage >= 3.5 && drawHistory.length >= 500) {
      state = 'Sólido para investigación descriptiva';
    } else if (active >= 3 && drawHistory.length >= 100) {
      state = 'Operativo, con áreas por fortalecer';
    } else {
      state = 'Configuración inicial o evidencia limitada';
    }

    return AthenaResponse(
      title: 'Salud del Modelo PIT',
      summary: state,
      details: <String>[
        'Modelo activo: v${model.modelVersion}.',
        'Motor: ${model.engineName} v${model.engineVersion}.',
        'Reglas activas: $active de ${model.rules.length}.',
        'Evidencia promedio: ${evidenceAverage.toStringAsFixed(1)}/5.',
        'Peso activo acumulado: ${totalWeight.toStringAsFixed(2)}.',
        'Histórico: ${drawHistory.length} sorteos.',
        'Versiones guardadas: ${history.length}.',
      ],
      category: 'Modelo PIT',
    );
  }

  AthenaResponse _historicalSummary(List<List<int>> history) {
    if (history.isEmpty) {
      return const AthenaResponse(
        title: 'Histórico vacío',
        summary: 'No hay información para resumir.',
        details: <String>[],
        category: 'Histórico',
      );
    }

    double sumTotal = 0;
    double evenTotal = 0;
    int minimumSum = 999;
    int maximumSum = 0;

    for (final List<int> draw in history) {
      final int sum = draw.fold<int>(
        0,
        (int total, int value) => total + value,
      );
      final int evens = draw.where((int value) => value.isEven).length;
      sumTotal += sum;
      evenTotal += evens;
      if (sum < minimumSum) minimumSum = sum;
      if (sum > maximumSum) maximumSum = sum;
    }

    return AthenaResponse(
      title: 'Resumen del histórico',
      summary:
          'Descripción general de ${history.length} sorteos.',
      details: <String>[
        'Suma promedio: ${(sumTotal / history.length).toStringAsFixed(1)}.',
        'Rango de sumas observado: $minimumSum – $maximumSum.',
        'Pares promedio por sorteo: '
            '${(evenTotal / history.length).toStringAsFixed(2)}.',
        'Impares promedio por sorteo: '
            '${(6 - evenTotal / history.length).toStringAsFixed(2)}.',
      ],
      category: 'Histórico',
    );
  }

  static String _normalize(String value) {
    return value
        .toLowerCase()
        .replaceAll(RegExp(r'[áàä]'), 'a')
        .replaceAll(RegExp(r'[éèë]'), 'e')
        .replaceAll(RegExp(r'[íìï]'), 'i')
        .replaceAll(RegExp(r'[óòö]'), 'o')
        .replaceAll(RegExp(r'[úùü]'), 'u')
        .replaceAll('ñ', 'n')
        .trim();
  }

  static bool _containsAny(String value, List<String> terms) {
    return terms.any(value.contains);
  }
}
