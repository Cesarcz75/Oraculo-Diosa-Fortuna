import 'dart:math';
import '../models/model_config.dart';
import '../models/pit_metrics.dart';
import '../models/ranked_combination.dart';

class PitMetricsEngine {
  const PitMetricsEngine();

  PitMetrics calculate({
    required ModelConfig model,
    required List<ModelConfig> modelHistory,
    required List<List<int>> drawHistory,
    required List<RankedCombination> ranking,
  }) {
    final List<RuleConfig> activeRules = model.rules
        .where((RuleConfig rule) => rule.enabled)
        .toList(growable: false);

    final double coverage = model.rules.isEmpty
        ? 0
        : 100 * activeRules.length / model.rules.length;

    final double evidence = activeRules.isEmpty
        ? 0
        : 100 *
            activeRules.fold<double>(
              0,
              (double total, RuleConfig rule) =>
                  total + rule.evidenceLevel / 5,
            ) /
            activeRules.length;

    final List<PitRuleInfluence> influences = _influences(
      activeRules: activeRules,
      ranking: ranking,
    );

    final double scoreBalance = ranking.isEmpty
        ? _entropyScore(
            activeRules
                .map((RuleConfig rule) => rule.weight.abs())
                .toList(growable: false),
          )
        : ranking.fold<double>(
              0,
              (double total, RankedCombination item) =>
                  total + item.pitIndex,
            ) /
            ranking.length;

    final double weightRobustness = _weightRobustness(activeRules);
    final double historicalDepth =
        (100 * drawHistory.length / 1200).clamp(0, 100).toDouble();
    final double versionMaturity =
        (45 + min(modelHistory.length, 11) * 5).clamp(0, 100).toDouble();

    final double overallHealth = (
      evidence * 0.24 +
      coverage * 0.16 +
      scoreBalance * 0.22 +
      weightRobustness * 0.20 +
      historicalDepth * 0.12 +
      versionMaturity * 0.06
    ).clamp(0, 100).toDouble();

    final List<String> alerts = _alerts(
      model: model,
      activeRules: activeRules,
      drawHistory: drawHistory,
      ranking: ranking,
      influences: influences,
      coverage: coverage,
      evidence: evidence,
      weightRobustness: weightRobustness,
    );

    return PitMetrics(
      overallHealth: overallHealth,
      coverage: coverage,
      evidence: evidence,
      scoreBalance: scoreBalance,
      weightRobustness: weightRobustness,
      historicalDepth: historicalDepth,
      versionMaturity: versionMaturity,
      healthLabel: _healthLabel(overallHealth),
      influences: List<PitRuleInfluence>.unmodifiable(influences),
      alerts: List<String>.unmodifiable(alerts),
    );
  }

  List<PitRuleInfluence> _influences({
    required List<RuleConfig> activeRules,
    required List<RankedCombination> ranking,
  }) {
    final Map<String, double> totals = <String, double>{};

    if (ranking.isNotEmpty) {
      for (final RankedCombination item in ranking) {
        for (final entry in item.contributions.entries) {
          totals.update(
            entry.key,
            (double value) => value + entry.value.abs(),
            ifAbsent: () => entry.value.abs(),
          );
        }
      }
    } else {
      for (final RuleConfig rule in activeRules) {
        totals[rule.label] = rule.weight.abs();
      }
    }

    final double magnitude = totals.values.fold<double>(
      0,
      (double total, double value) => total + value,
    );

    final List<PitRuleInfluence> result = totals.entries
        .map(
          (entry) => PitRuleInfluence(
            label: entry.key,
            value: entry.value,
            share: magnitude == 0 ? 0 : entry.value / magnitude,
          ),
        )
        .toList(growable: false)
      ..sort(
        (PitRuleInfluence a, PitRuleInfluence b) =>
            b.share.compareTo(a.share),
      );

    return result;
  }

  double _weightRobustness(List<RuleConfig> activeRules) {
    if (activeRules.isEmpty) return 0;
    if (activeRules.length == 1) return 35;

    final List<double> weights = activeRules
        .map((RuleConfig rule) => rule.weight.abs())
        .toList(growable: false);

    final double entropy = _entropyScore(weights);
    final double average = weights.fold<double>(
          0,
          (double total, double value) => total + value,
        ) /
        weights.length;

    final double variance = weights.fold<double>(
          0,
          (double total, double value) =>
              total + pow(value - average, 2).toDouble(),
        ) /
        weights.length;

    final double dispersionPenalty = average == 0
        ? 100
        : (100 * sqrt(variance) / average).clamp(0, 100).toDouble();

    return (entropy * 0.75 + (100 - dispersionPenalty) * 0.25)
        .clamp(0, 100)
        .toDouble();
  }

  double _entropyScore(List<double> values) {
    final List<double> positive = values
        .where((double value) => value > 0)
        .toList(growable: false);

    if (positive.isEmpty) return 0;
    if (positive.length == 1) return 50;

    final double total = positive.fold<double>(
      0,
      (double sum, double value) => sum + value,
    );

    final List<double> shares =
        positive.map((double value) => value / total).toList();

    final double entropy = shares.fold<double>(
      0,
      (double sum, double share) => sum - share * log(share),
    );

    return (100 * entropy / log(shares.length))
        .clamp(0, 100)
        .toDouble();
  }

  List<String> _alerts({
    required ModelConfig model,
    required List<RuleConfig> activeRules,
    required List<List<int>> drawHistory,
    required List<RankedCombination> ranking,
    required List<PitRuleInfluence> influences,
    required double coverage,
    required double evidence,
    required double weightRobustness,
  }) {
    final List<String> alerts = <String>[];

    if (ranking.isEmpty) {
      alerts.add(
        'Genera un ranking para calcular influencia real y balance del Score.',
      );
    }

    if (activeRules.length < 3) {
      alerts.add(
        'El modelo tiene menos de tres reglas activas; su diversidad es limitada.',
      );
    }

    if (coverage < 70) {
      alerts.add(
        'La cobertura de reglas es menor a 70%; revisa reglas desactivadas.',
      );
    }

    if (evidence < 65) {
      alerts.add(
        'La evidencia promedio es baja; prioriza reglas con validación pendiente.',
      );
    }

    if (weightRobustness < 60) {
      alerts.add(
        'Los pesos están concentrados o dispersos; conviene revisar su equilibrio.',
      );
    }

    if (drawHistory.length < 300) {
      alerts.add(
        'El histórico es corto para análisis comparativos robustos.',
      );
    }

    final RuleConfig? extreme = activeRules.cast<RuleConfig?>().firstWhere(
          (RuleConfig? rule) => rule != null && rule.weight > 2.5,
          orElse: () => null,
        );
    if (extreme != null) {
      alerts.add(
        '${extreme.id} · ${extreme.label} tiene un peso alto '
        '(${extreme.weight.toStringAsFixed(2)}).',
      );
    }

    if (influences.isNotEmpty && influences.first.share > 0.45) {
      alerts.add(
        '${influences.first.label} concentra '
        '${(influences.first.share * 100).toStringAsFixed(1)}% '
        'de la influencia observada.',
      );
    }

    if (alerts.isEmpty) {
      alerts.add(
        'No se detectaron alertas metodológicas relevantes en el estado actual.',
      );
    }

    return alerts;
  }

  String _healthLabel(double value) {
    if (value >= 90) return 'Excelente';
    if (value >= 80) return 'Muy saludable';
    if (value >= 70) return 'Saludable';
    if (value >= 55) return 'En observación';
    return 'Requiere atención';
  }
}
