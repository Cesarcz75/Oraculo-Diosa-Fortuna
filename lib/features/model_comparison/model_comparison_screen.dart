import 'package:flutter/material.dart';
import '../../core/models/model_comparison.dart';
import '../../core/models/model_config.dart';
import '../../core/services/model_comparison_engine.dart';

class ModelComparisonScreen extends StatefulWidget {
  const ModelComparisonScreen({
    required this.activeModel,
    required this.history,
    super.key,
  });

  final ModelConfig activeModel;
  final List<ModelConfig> history;

  @override
  State<ModelComparisonScreen> createState() =>
      _ModelComparisonScreenState();
}

class _ModelComparisonScreenState extends State<ModelComparisonScreen> {
  static const Color gold = Color(0xFFE8B85A);
  static const Color panel = Color(0xFF1A1022);
  final ModelComparisonEngine _engine = const ModelComparisonEngine();

  ModelConfig? _first;
  ModelConfig? _second;
  bool _showOnlyChanges = true;

  List<ModelConfig> get _models {
    final List<ModelConfig> models = <ModelConfig>[widget.activeModel];
    for (final ModelConfig version in widget.history) {
      final bool duplicate = models.any((ModelConfig item) =>
          item.modelVersion == version.modelVersion &&
          item.updatedAt == version.updatedAt);
      if (!duplicate) models.add(version);
    }
    return models;
  }

  @override
  void initState() {
    super.initState();
    final List<ModelConfig> models = _models;
    _first = models.length > 1 ? models[1] : models.first;
    _second = models.first;
  }

  @override
  void didUpdateWidget(covariant ModelComparisonScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.activeModel.modelVersion !=
        widget.activeModel.modelVersion) {
      _second = widget.activeModel;
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<ModelConfig> models = _models;
    final ModelConfig first = _first ?? models.first;
    final ModelConfig second = _second ?? models.first;
    final ModelComparisonReport report = _engine.compare(
      first: first,
      second: second,
    );
    final List<RuleComparison> rows =
        _showOnlyChanges ? report.onlyChanges : report.rules;

    return ListView(
      padding: const EdgeInsets.all(24),
      children: <Widget>[
        Text(
          'Comparador de Modelos PIT',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: gold,
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Compara reglas, pesos e indicadores internos entre dos versiones.',
        ),
        const SizedBox(height: 20),
        if (models.length < 2)
          const Card(
            color: panel,
            child: Padding(
              padding: EdgeInsets.all(22),
              child: Text(
                'Guarda al menos una nueva versión del Modelo PIT para '
                'compararla con la versión activa.',
              ),
            ),
          )
        else ...<Widget>[
          _buildSelectors(models),
          const SizedBox(height: 18),
          _buildSummary(report),
          const SizedBox(height: 18),
          _buildChanges(report, rows),
        ],
      ],
    );
  }

  Widget _buildSelectors(List<ModelConfig> models) {
    return Card(
      color: panel,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final bool wide = constraints.maxWidth > 720;
            final Widget first = _selector(
              label: 'Modelo A',
              value: _first ?? models.first,
              models: models,
              onChanged: (ModelConfig value) =>
                  setState(() => _first = value),
            );
            final Widget second = _selector(
              label: 'Modelo B',
              value: _second ?? models.first,
              models: models,
              onChanged: (ModelConfig value) =>
                  setState(() => _second = value),
            );
            if (wide) {
              return Row(
                children: <Widget>[
                  Expanded(child: first),
                  const SizedBox(width: 14),
                  const Icon(Icons.compare_arrows, color: gold),
                  const SizedBox(width: 14),
                  Expanded(child: second),
                ],
              );
            }
            return Column(
              children: <Widget>[
                first,
                const SizedBox(height: 12),
                second,
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _selector({
    required String label,
    required ModelConfig value,
    required List<ModelConfig> models,
    required ValueChanged<ModelConfig> onChanged,
  }) {
    return DropdownButtonFormField<ModelConfig>(
      initialValue: value,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      items: models.map((ModelConfig model) {
        return DropdownMenuItem<ModelConfig>(
          value: model,
          child: Text(
            'v${model.modelVersion} · ${model.changeNote.isEmpty ? 'Sin nota' : model.changeNote}',
            overflow: TextOverflow.ellipsis,
          ),
        );
      }).toList(growable: false),
      onChanged: (ModelConfig? model) {
        if (model != null) onChanged(model);
      },
    );
  }

  Widget _buildSummary(ModelComparisonReport report) {
    return Column(
      children: <Widget>[
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: <Widget>[
            _HealthCard(
              title: 'Modelo A · v${report.first.modelVersion}',
              health: report.firstHealth,
            ),
            _HealthCard(
              title: 'Modelo B · v${report.second.modelVersion}',
              health: report.secondHealth,
            ),
            _DeltaCard(report: report),
          ],
        ),
        const SizedBox(height: 12),
        Card(
          color: panel,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: <Widget>[
                const Icon(Icons.info_outline, color: gold),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '${report.changedRules} regla(s) cambiaron entre ambas '
                    'versiones. El Índice PIT es una métrica interna de '
                    'estructura del modelo, no una probabilidad de ganar.',
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildChanges(
    ModelComparisonReport report,
    List<RuleComparison> rows,
  ) {
    return Card(
      color: panel,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                const Expanded(
                  child: Text(
                    'CAMBIOS POR REGLA',
                    style: TextStyle(
                      color: gold,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                FilterChip(
                  label: const Text('Solo cambios'),
                  selected: _showOnlyChanges,
                  onSelected: (bool value) =>
                      setState(() => _showOnlyChanges = value),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (rows.isEmpty)
              const Padding(
                padding: EdgeInsets.all(18),
                child: Text('Las versiones seleccionadas son equivalentes.'),
              )
            else
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columns: const <DataColumn>[
                    DataColumn(label: Text('Regla')),
                    DataColumn(label: Text('Cambio')),
                    DataColumn(label: Text('Modelo A')),
                    DataColumn(label: Text('Modelo B')),
                    DataColumn(label: Text('Diferencia')),
                  ],
                  rows: rows.map((RuleComparison rule) {
                    return DataRow(
                      cells: <DataCell>[
                        DataCell(Text(rule.label)),
                        DataCell(_ChangeChip(type: rule.changeType)),
                        DataCell(Text(
                          rule.firstEnabled
                              ? rule.firstWeight.toStringAsFixed(2)
                              : 'Inactiva',
                        )),
                        DataCell(Text(
                          rule.secondEnabled
                              ? rule.secondWeight.toStringAsFixed(2)
                              : 'Inactiva',
                        )),
                        DataCell(Text(
                          rule.weightDelta == 0
                              ? '—'
                              : '${rule.weightDelta > 0 ? '+' : ''}${rule.weightDelta.toStringAsFixed(2)}',
                        )),
                      ],
                    );
                  }).toList(growable: false),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _HealthCard extends StatelessWidget {
  const _HealthCard({required this.title, required this.health});
  static const Color gold = Color(0xFFE8B85A);
  static const Color panel = Color(0xFF1A1022);
  final String title;
  final ModelHealthSnapshot health;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: panel,
      child: SizedBox(
        width: 260,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(title, style: const TextStyle(color: gold)),
              const SizedBox(height: 12),
              Text(
                health.pitIndex.toStringAsFixed(1),
                style: const TextStyle(
                  color: gold,
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Text('Índice PIT interno'),
              const SizedBox(height: 10),
              LinearProgressIndicator(
                value: health.pitIndex / 100,
                color: gold,
                backgroundColor: const Color(0xFF2A103A),
              ),
              const SizedBox(height: 12),
              Text('Reglas activas: ${health.activeRules}/${health.totalRules}'),
              Text('Peso total: ${health.totalWeight.toStringAsFixed(2)}'),
              Text('Evidencia: ${health.averageEvidence.toStringAsFixed(1)}/5'),
            ],
          ),
        ),
      ),
    );
  }
}

class _DeltaCard extends StatelessWidget {
  const _DeltaCard({required this.report});
  static const Color gold = Color(0xFFE8B85A);
  static const Color panel = Color(0xFF1A1022);
  final ModelComparisonReport report;

  @override
  Widget build(BuildContext context) {
    final double delta = report.pitIndexDelta;
    final Color color = delta > 0
        ? Colors.greenAccent
        : delta < 0
            ? Colors.orangeAccent
            : Colors.white70;
    return Card(
      color: panel,
      child: SizedBox(
        width: 240,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Text('DIFERENCIA', style: TextStyle(color: gold)),
              const SizedBox(height: 12),
              Text(
                '${delta > 0 ? '+' : ''}${delta.toStringAsFixed(1)}',
                style: TextStyle(
                  color: color,
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Text('puntos de Índice PIT'),
              const SizedBox(height: 12),
              Text('${report.changedRules} reglas modificadas'),
              Text(
                'Peso: ${report.firstHealth.totalWeight.toStringAsFixed(2)} → '
                '${report.secondHealth.totalWeight.toStringAsFixed(2)}',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChangeChip extends StatelessWidget {
  const _ChangeChip({required this.type});
  final RuleChangeType type;

  @override
  Widget build(BuildContext context) {
    final String label;
    final Color color;
    switch (type) {
      case RuleChangeType.added:
        label = 'Agregada';
        color = Colors.greenAccent;
      case RuleChangeType.removed:
        label = 'Eliminada';
        color = Colors.redAccent;
      case RuleChangeType.activated:
        label = 'Activada';
        color = Colors.greenAccent;
      case RuleChangeType.deactivated:
        label = 'Desactivada';
        color = Colors.orangeAccent;
      case RuleChangeType.weightChanged:
        label = 'Peso modificado';
        color = Colors.amberAccent;
      case RuleChangeType.unchanged:
        label = 'Sin cambios';
        color = Colors.white54;
    }
    return Chip(
      label: Text(label),
      side: BorderSide(color: color),
      backgroundColor: color.withValues(alpha: 0.08),
    );
  }
}
