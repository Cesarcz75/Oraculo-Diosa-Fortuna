import 'package:flutter/material.dart';
import '../../core/models/model_config.dart';
import '../../core/models/pit_metrics.dart';
import '../../core/models/ranked_combination.dart';
import '../../core/services/pit_metrics_engine.dart';

class PitMetricsScreen extends StatelessWidget {
  const PitMetricsScreen({
    required this.model,
    required this.modelHistory,
    required this.drawHistory,
    required this.ranking,
    super.key,
  });

  static const Color gold = Color(0xFFE8B85A);
  static const Color panel = Color(0xFF1A1022);

  final ModelConfig model;
  final List<ModelConfig> modelHistory;
  final List<List<int>> drawHistory;
  final List<RankedCombination> ranking;

  @override
  Widget build(BuildContext context) {
    final PitMetrics metrics = const PitMetricsEngine().calculate(
      model: model,
      modelHistory: modelHistory,
      drawHistory: drawHistory,
      ranking: ranking,
    );

    return ListView(
      padding: const EdgeInsets.all(24),
      children: <Widget>[
        Text(
          'Métricas PIT',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: gold,
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 6),
        Text(
          'Salud metodológica del Modelo PIT v${model.modelVersion}.',
        ),
        const SizedBox(height: 20),
        _HealthBanner(metrics: metrics),
        const SizedBox(height: 18),
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: <Widget>[
            _MetricCard(
              title: 'Cobertura',
              value: metrics.coverage,
              caption: 'reglas activas',
              icon: Icons.rule_outlined,
            ),
            _MetricCard(
              title: 'Evidencia',
              value: metrics.evidence,
              caption: 'nivel promedio',
              icon: Icons.verified_outlined,
            ),
            _MetricCard(
              title: 'Balance del Score',
              value: metrics.scoreBalance,
              caption: ranking.isEmpty
                  ? 'estimado por pesos'
                  : 'ranking actual',
              icon: Icons.balance_outlined,
            ),
            _MetricCard(
              title: 'Robustez de pesos',
              value: metrics.weightRobustness,
              caption: 'concentración',
              icon: Icons.shield_outlined,
            ),
            _MetricCard(
              title: 'Profundidad histórica',
              value: metrics.historicalDepth,
              caption: '${drawHistory.length} sorteos',
              icon: Icons.storage_outlined,
            ),
            _MetricCard(
              title: 'Madurez de versiones',
              value: metrics.versionMaturity,
              caption: '${modelHistory.length} guardadas',
              icon: Icons.history_outlined,
            ),
          ],
        ),
        const SizedBox(height: 20),
        _InfluenceCard(influences: metrics.influences),
        const SizedBox(height: 18),
        _AlertsCard(alerts: metrics.alerts),
        const SizedBox(height: 14),
        const Card(
          color: panel,
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Las Métricas PIT evalúan cobertura, evidencia, equilibrio, '
              'profundidad histórica y concentración del modelo. '
              'No representan probabilidades de ganar.',
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

class _HealthBanner extends StatelessWidget {
  const _HealthBanner({required this.metrics});

  static const Color gold = Color(0xFFE8B85A);
  static const Color panel = Color(0xFF1A1022);

  final PitMetrics metrics;

  @override
  Widget build(BuildContext context) {
    final Color statusColor = metrics.overallHealth >= 80
        ? Colors.greenAccent
        : metrics.overallHealth >= 60
            ? Colors.amberAccent
            : Colors.orangeAccent;

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
                    value: metrics.overallHealth / 100,
                    strokeWidth: 9,
                    color: statusColor,
                    backgroundColor: const Color(0xFF2A103A),
                  ),
                  Center(
                    child: Text(
                      metrics.overallHealth.toStringAsFixed(1),
                      style: const TextStyle(
                        color: gold,
                        fontSize: 22,
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
                    'SALUD GENERAL DEL MODELO',
                    style: TextStyle(
                      color: Colors.white60,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    metrics.healthLabel,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 25,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Índice compuesto de calidad metodológica interna.',
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

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.title,
    required this.value,
    required this.caption,
    required this.icon,
  });

  static const Color gold = Color(0xFFE8B85A);
  static const Color panel = Color(0xFF1A1022);

  final String title;
  final double value;
  final String caption;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: panel,
      child: SizedBox(
        width: 245,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Icon(icon, color: gold),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                value.toStringAsFixed(1),
                style: const TextStyle(
                  color: gold,
                  fontSize: 27,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 3),
              Text(caption),
              const SizedBox(height: 10),
              LinearProgressIndicator(
                value: value / 100,
                color: gold,
                backgroundColor: const Color(0xFF2A103A),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfluenceCard extends StatelessWidget {
  const _InfluenceCard({required this.influences});

  static const Color gold = Color(0xFFE8B85A);
  static const Color panel = Color(0xFF1A1022);

  final List<PitRuleInfluence> influences;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: panel,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Text(
              'INFLUENCIA OBSERVADA DE REGLAS',
              style: TextStyle(
                color: gold,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 14),
            if (influences.isEmpty)
              const Text('No hay reglas activas para analizar.')
            else
              ...influences.take(10).map(
                (PitRuleInfluence item) => Padding(
                  padding: const EdgeInsets.only(bottom: 13),
                  child: Column(
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Expanded(child: Text(item.label)),
                          Text(
                            '${(item.share * 100).toStringAsFixed(1)}%',
                            style: const TextStyle(
                              color: gold,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      LinearProgressIndicator(
                        value: item.share.clamp(0.0, 1.0).toDouble(),
                        color: gold,
                        backgroundColor: const Color(0xFF2A103A),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _AlertsCard extends StatelessWidget {
  const _AlertsCard({required this.alerts});

  static const Color gold = Color(0xFFE8B85A);
  static const Color panel = Color(0xFF1A1022);

  final List<String> alerts;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: panel,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Text(
              'AUDITORÍA AUTOMÁTICA',
              style: TextStyle(
                color: gold,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ...alerts.map(
              (String alert) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Padding(
                      padding: EdgeInsets.only(top: 2),
                      child: Icon(
                        Icons.info_outline,
                        color: gold,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(child: Text(alert)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
