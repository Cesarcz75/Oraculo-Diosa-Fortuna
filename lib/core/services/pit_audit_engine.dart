import '../models/model_config.dart';
import '../models/pit_audit.dart';
import '../models/ranked_combination.dart';

class PitAuditEngine {
  const PitAuditEngine();

  PitAuditReport audit({
    required ModelConfig model,
    required List<List<int>> drawHistory,
    required List<RankedCombination> ranking,
  }) {
    final List<PitAuditFinding> findings = <PitAuditFinding>[];
    final List<RuleConfig> activeRules = model.rules
        .where((RuleConfig rule) => rule.enabled)
        .toList(growable: false);

    _checkActiveRuleCount(activeRules, findings);
    _checkEvidence(activeRules, findings);
    _checkWeights(activeRules, findings);
    _checkDuplicateLabels(model.rules, findings);
    _checkRankingInfluence(activeRules, ranking, findings);
    _checkHistory(drawHistory, findings);

    final double penalty = findings.fold<double>(
      0,
      (double total, PitAuditFinding finding) {
        switch (finding.severity) {
          case PitAuditSeverity.info:
            return total + 2;
          case PitAuditSeverity.warning:
            return total + 7;
          case PitAuditSeverity.critical:
            return total + 15;
        }
      },
    );

    final double score = (100 - penalty).clamp(0, 100).toDouble();

    return PitAuditReport(
      generatedAt: DateTime.now(),
      score: score,
      status: _status(score),
      findings: List<PitAuditFinding>.unmodifiable(findings),
    );
  }

  void _checkActiveRuleCount(
    List<RuleConfig> activeRules,
    List<PitAuditFinding> findings,
  ) {
    if (activeRules.isEmpty) {
      findings.add(
        const PitAuditFinding(
          code: 'AUD-001',
          title: 'Modelo sin reglas activas',
          description:
              'El Modelo PIT no tiene reglas activas para generar puntuaciones.',
          recommendation:
              'Activa al menos tres reglas antes de generar un ranking.',
          severity: PitAuditSeverity.critical,
        ),
      );
    } else if (activeRules.length < 3) {
      findings.add(
        PitAuditFinding(
          code: 'AUD-002',
          title: 'Diversidad limitada',
          description:
              'Solo hay ${activeRules.length} regla(s) activa(s).',
          recommendation:
              'Mantén al menos tres reglas activas para evitar dependencia excesiva.',
          severity: PitAuditSeverity.warning,
        ),
      );
    }
  }

  void _checkEvidence(
    List<RuleConfig> activeRules,
    List<PitAuditFinding> findings,
  ) {
    for (final RuleConfig rule in activeRules) {
      if (rule.evidenceLevel <= 1) {
        findings.add(
          PitAuditFinding(
            code: 'AUD-101',
            title: 'Evidencia insuficiente',
            description:
                '${rule.id} · ${rule.label} está activa con evidencia '
                '${rule.evidenceLevel}/5.',
            recommendation:
                'Valida la regla mediante laboratorio y backtesting antes de mantenerla activa.',
            severity: PitAuditSeverity.critical,
            ruleId: rule.id,
            ruleLabel: rule.label,
          ),
        );
      } else if (rule.evidenceLevel == 2) {
        findings.add(
          PitAuditFinding(
            code: 'AUD-102',
            title: 'Evidencia baja',
            description:
                '${rule.id} · ${rule.label} tiene evidencia 2/5.',
            recommendation:
                'Mantén la regla en observación y documenta pruebas adicionales.',
            severity: PitAuditSeverity.warning,
            ruleId: rule.id,
            ruleLabel: rule.label,
          ),
        );
      }
    }
  }

  void _checkWeights(
    List<RuleConfig> activeRules,
    List<PitAuditFinding> findings,
  ) {
    for (final RuleConfig rule in activeRules) {
      if (rule.weight <= 0) {
        findings.add(
          PitAuditFinding(
            code: 'AUD-201',
            title: 'Peso no positivo',
            description:
                '${rule.id} · ${rule.label} está activa con peso '
                '${rule.weight.toStringAsFixed(2)}.',
            recommendation:
                'Asigna un peso positivo o desactiva la regla.',
            severity: PitAuditSeverity.critical,
            ruleId: rule.id,
            ruleLabel: rule.label,
          ),
        );
      } else if (rule.weight > 2.5) {
        findings.add(
          PitAuditFinding(
            code: 'AUD-202',
            title: 'Peso elevado',
            description:
                '${rule.id} · ${rule.label} tiene peso '
                '${rule.weight.toStringAsFixed(2)}.',
            recommendation:
                'Prueba un peso menor y compara el impacto en el ranking.',
            severity: PitAuditSeverity.warning,
            ruleId: rule.id,
            ruleLabel: rule.label,
          ),
        );
      } else if (rule.weight < 0.10) {
        findings.add(
          PitAuditFinding(
            code: 'AUD-203',
            title: 'Peso casi nulo',
            description:
                '${rule.id} · ${rule.label} tiene peso '
                '${rule.weight.toStringAsFixed(2)}.',
            recommendation:
                'Evalúa si la regla aporta valor o conviene desactivarla.',
            severity: PitAuditSeverity.info,
            ruleId: rule.id,
            ruleLabel: rule.label,
          ),
        );
      }
    }
  }

  void _checkDuplicateLabels(
    List<RuleConfig> rules,
    List<PitAuditFinding> findings,
  ) {
    final Map<String, List<RuleConfig>> groups =
        <String, List<RuleConfig>>{};

    for (final RuleConfig rule in rules) {
      final String key = rule.label.trim().toLowerCase();
      groups.putIfAbsent(key, () => <RuleConfig>[]).add(rule);
    }

    for (final List<RuleConfig> group in groups.values) {
      if (group.length > 1) {
        findings.add(
          PitAuditFinding(
            code: 'AUD-301',
            title: 'Nombre de regla duplicado',
            description:
                'Las reglas ${group.map((RuleConfig item) => item.id).join(', ')} '
                'comparten el nombre "${group.first.label}".',
            recommendation:
                'Diferencia los nombres o consolida las reglas duplicadas.',
            severity: PitAuditSeverity.warning,
          ),
        );
      }
    }
  }

  void _checkRankingInfluence(
    List<RuleConfig> activeRules,
    List<RankedCombination> ranking,
    List<PitAuditFinding> findings,
  ) {
    if (ranking.isEmpty) {
      findings.add(
        const PitAuditFinding(
          code: 'AUD-401',
          title: 'Ranking no disponible',
          description:
              'No hay un ranking actual para medir la influencia real de las reglas.',
          recommendation:
              'Genera un ranking antes de ejecutar la auditoría final.',
          severity: PitAuditSeverity.info,
        ),
      );
      return;
    }

    final Map<String, double> contributionTotals = <String, double>{};
    for (final RankedCombination item in ranking) {
      for (final MapEntry<String, double> entry
          in item.contributions.entries) {
        contributionTotals.update(
          entry.key,
          (double value) => value + entry.value.abs(),
          ifAbsent: () => entry.value.abs(),
        );
      }
    }

    final double total = contributionTotals.values.fold<double>(
      0,
      (double sum, double value) => sum + value,
    );

    if (total == 0) return;

    for (final MapEntry<String, double> entry
        in contributionTotals.entries) {
      final double share = entry.value / total;
      if (share > 0.45) {
        findings.add(
          PitAuditFinding(
            code: 'AUD-402',
            title: 'Influencia concentrada',
            description:
                '${entry.key} explica '
                '${(share * 100).toStringAsFixed(1)}% '
                'de la influencia observada.',
            recommendation:
                'Revisa el peso de esta regla y prueba un modelo más balanceado.',
            severity: PitAuditSeverity.warning,
          ),
        );
      }
    }

    final Set<String> usedLabels = contributionTotals.keys.toSet();
    for (final RuleConfig rule in activeRules) {
      if (!usedLabels.contains(rule.label)) {
        findings.add(
          PitAuditFinding(
            code: 'AUD-403',
            title: 'Regla activa sin influencia',
            description:
                '${rule.id} · ${rule.label} no aparece en el Score Breakdown.',
            recommendation:
                'Revisa su implementación o desactívala hasta corregirla.',
            severity: PitAuditSeverity.critical,
            ruleId: rule.id,
            ruleLabel: rule.label,
          ),
        );
      }
    }
  }

  void _checkHistory(
    List<List<int>> drawHistory,
    List<PitAuditFinding> findings,
  ) {
    if (drawHistory.length < 100) {
      findings.add(
        PitAuditFinding(
          code: 'AUD-501',
          title: 'Histórico insuficiente',
          description:
              'Solo hay ${drawHistory.length} sorteos cargados.',
          recommendation:
              'Carga al menos 100 sorteos antes de validar el modelo.',
          severity: PitAuditSeverity.critical,
        ),
      );
    } else if (drawHistory.length < 500) {
      findings.add(
        PitAuditFinding(
          code: 'AUD-502',
          title: 'Profundidad histórica limitada',
          description:
              'El histórico contiene ${drawHistory.length} sorteos.',
          recommendation:
              'Amplía el histórico para comparaciones más robustas.',
          severity: PitAuditSeverity.warning,
        ),
      );
    }
  }

  String _status(double score) {
    if (score >= 90) return 'Auditoría satisfactoria';
    if (score >= 75) return 'Observaciones menores';
    if (score >= 55) return 'Revisión recomendada';
    return 'Corrección prioritaria';
  }
}
