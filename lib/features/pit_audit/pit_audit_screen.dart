import 'package:flutter/material.dart';
import '../../core/models/model_config.dart';
import '../../core/models/pit_audit.dart';
import '../../core/models/ranked_combination.dart';
import '../../core/services/pit_audit_engine.dart';

class PitAuditScreen extends StatefulWidget {
  const PitAuditScreen({
    required this.model,
    required this.drawHistory,
    required this.ranking,
    super.key,
  });

  final ModelConfig model;
  final List<List<int>> drawHistory;
  final List<RankedCombination> ranking;

  @override
  State<PitAuditScreen> createState() => _PitAuditScreenState();
}

class _PitAuditScreenState extends State<PitAuditScreen> {
  static const Color gold = Color(0xFFE8B85A);
  static const Color panel = Color(0xFF1A1022);

  PitAuditSeverity? _filter;
  late PitAuditReport _report;

  @override
  void initState() {
    super.initState();
    _runAudit();
  }

  @override
  void didUpdateWidget(covariant PitAuditScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.model.modelVersion != widget.model.modelVersion ||
        oldWidget.ranking.length != widget.ranking.length ||
        oldWidget.drawHistory.length != widget.drawHistory.length) {
      _runAudit();
    }
  }

  void _runAudit() {
    _report = const PitAuditEngine().audit(
      model: widget.model,
      drawHistory: widget.drawHistory,
      ranking: widget.ranking,
    );
  }

  List<PitAuditFinding> get _visibleFindings {
    if (_filter == null) {
      return _report.findings;
    }
    return _report.findings
        .where((PitAuditFinding item) => item.severity == _filter)
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'Auditor PIT',
                    style:
                        Theme.of(context).textTheme.headlineMedium?.copyWith(
                              color: gold,
                              fontWeight: FontWeight.bold,
                            ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Revisión automática del Modelo PIT '
                    'v${widget.model.modelVersion}.',
                  ),
                ],
              ),
            ),
            FilledButton.icon(
              onPressed: () {
                setState(_runAudit);
              },
              icon: const Icon(Icons.refresh),
              label: const Text('VOLVER A AUDITAR'),
              style: FilledButton.styleFrom(
                backgroundColor: gold,
                foregroundColor: Colors.black,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        _AuditBanner(report: _report),
        const SizedBox(height: 18),
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: <Widget>[
            _CounterCard(
              title: 'Críticas',
              value: _report.criticalCount,
              icon: Icons.error_outline,
              accent: Colors.redAccent,
            ),
            _CounterCard(
              title: 'Advertencias',
              value: _report.warningCount,
              icon: Icons.warning_amber_outlined,
              accent: Colors.amberAccent,
            ),
            _CounterCard(
              title: 'Informativas',
              value: _report.infoCount,
              icon: Icons.info_outline,
              accent: Colors.lightBlueAccent,
            ),
            _CounterCard(
              title: 'Total',
              value: _report.findings.length,
              icon: Icons.fact_check_outlined,
              accent: gold,
            ),
          ],
        ),
        const SizedBox(height: 18),
        Card(
          color: panel,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: <Widget>[
                ChoiceChip(
                  label: const Text('Todas'),
                  selected: _filter == null,
                  onSelected: (_) => setState(() => _filter = null),
                ),
                ChoiceChip(
                  label: const Text('Críticas'),
                  selected: _filter == PitAuditSeverity.critical,
                  onSelected: (_) => setState(
                    () => _filter = PitAuditSeverity.critical,
                  ),
                ),
                ChoiceChip(
                  label: const Text('Advertencias'),
                  selected: _filter == PitAuditSeverity.warning,
                  onSelected: (_) => setState(
                    () => _filter = PitAuditSeverity.warning,
                  ),
                ),
                ChoiceChip(
                  label: const Text('Informativas'),
                  selected: _filter == PitAuditSeverity.info,
                  onSelected: (_) => setState(
                    () => _filter = PitAuditSeverity.info,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${_visibleFindings.length} resultado(s)',
                  style: const TextStyle(color: Colors.white60),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        if (_visibleFindings.isEmpty)
          const Card(
            color: panel,
            child: Padding(
              padding: EdgeInsets.all(22),
              child: Text(
                'No se encontraron observaciones con el filtro seleccionado.',
              ),
            ),
          )
        else
          ..._visibleFindings.map(
            (PitAuditFinding finding) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _FindingCard(finding: finding),
            ),
          ),
        const SizedBox(height: 10),
        const Card(
          color: panel,
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'El Auditor PIT identifica riesgos metodológicos y de '
              'configuración. Sus observaciones no son predicciones ni '
              'garantías de resultados.',
              style: TextStyle(
                color: Colors.white60,
                fontSize: 12,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _AuditBanner extends StatelessWidget {
  const _AuditBanner({required this.report});

  static const Color gold = Color(0xFFE8B85A);
  static const Color panel = Color(0xFF1A1022);

  final PitAuditReport report;

  @override
  Widget build(BuildContext context) {
    final Color color = report.score >= 90
        ? Colors.greenAccent
        : report.score >= 75
            ? Colors.amberAccent
            : report.score >= 55
                ? Colors.orangeAccent
                : Colors.redAccent;

    return Card(
      color: panel,
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Row(
          children: <Widget>[
            SizedBox(
              width: 92,
              height: 92,
              child: Stack(
                fit: StackFit.expand,
                children: <Widget>[
                  CircularProgressIndicator(
                    value: report.score / 100,
                    strokeWidth: 9,
                    color: color,
                    backgroundColor: const Color(0xFF2A103A),
                  ),
                  Center(
                    child: Text(
                      report.score.toStringAsFixed(0),
                      style: const TextStyle(
                        color: gold,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Text(
                    'PUNTUACIÓN DE AUDITORÍA',
                    style: TextStyle(
                      color: Colors.white60,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    report.status,
                    style: TextStyle(
                      color: color,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${report.findings.length} observación(es) detectada(s).',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CounterCard extends StatelessWidget {
  const _CounterCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.accent,
  });

  static const Color panel = Color(0xFF1A1022);

  final String title;
  final int value;
  final IconData icon;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: panel,
      child: SizedBox(
        width: 205,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: <Widget>[
              Icon(icon, color: accent, size: 30),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    '$value',
                    style: TextStyle(
                      color: accent,
                      fontSize: 25,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(title),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FindingCard extends StatelessWidget {
  const _FindingCard({required this.finding});

  static const Color panel = Color(0xFF1A1022);

  final PitAuditFinding finding;

  @override
  Widget build(BuildContext context) {
    final Color color;
    final IconData icon;

    switch (finding.severity) {
      case PitAuditSeverity.critical:
        color = Colors.redAccent;
        icon = Icons.error_outline;
      case PitAuditSeverity.warning:
        color = Colors.amberAccent;
        icon = Icons.warning_amber_outlined;
      case PitAuditSeverity.info:
        color = Colors.lightBlueAccent;
        icon = Icons.info_outline;
    }

    return Card(
      color: panel,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Icon(icon, color: color, size: 28),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          finding.title,
                          style: TextStyle(
                            color: color,
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Text(
                        finding.code,
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  if (finding.ruleId != null) ...<Widget>[
                    const SizedBox(height: 5),
                    Text(
                      '${finding.ruleId} · ${finding.ruleLabel ?? ''}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Text(finding.description),
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF26172E),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Recomendación: ${finding.recommendation}',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
