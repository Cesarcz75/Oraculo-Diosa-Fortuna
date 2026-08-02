import 'package:flutter/material.dart';
import '../../core/models/backtesting_result.dart';
import '../../core/models/laboratory_experiment.dart';
import '../../core/services/backtesting_engine.dart';

class BacktestingScreen extends StatefulWidget {
  const BacktestingScreen({
    required this.history,
    super.key,
  });

  final List<List<int>> history;

  @override
  State<BacktestingScreen> createState() => _BacktestingScreenState();
}

class _BacktestingScreenState extends State<BacktestingScreen> {
  static const Color gold = Color(0xFFE8B85A);
  static const Color panel = Color(0xFF1A1022);

  final BacktestingEngine _engine = const BacktestingEngine();

  ExperimentRuleType _ruleType = ExperimentRuleType.sumRange;
  int _windowSize = 200;
  int _step = 50;
  final TextEditingController _minimumController =
      TextEditingController(text: '103');
  final TextEditingController _maximumController =
      TextEditingController(text: '136');

  BacktestingReport? _report;
  String _status = 'Configura una prueba y ejecútala.';

  @override
  void dispose() {
    _minimumController.dispose();
    _maximumController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: <Widget>[
        Text(
          'Backtesting Profesional',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: gold,
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Evalúa una hipótesis en múltiples ventanas móviles del histórico.',
        ),
        const SizedBox(height: 20),
        _buildConfigurationCard(),
        const SizedBox(height: 18),
        if (_report == null)
          Card(
            color: panel,
            child: Padding(
              padding: const EdgeInsets.all(22),
              child: Text(_status),
            ),
          )
        else ...<Widget>[
          _buildSummary(_report!),
          const SizedBox(height: 18),
          _buildWindowTable(_report!),
        ],
      ],
    );
  }

  Widget _buildConfigurationCard() {
    return Card(
      color: panel,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Text(
              'CONFIGURACIÓN',
              style: TextStyle(
                color: gold,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<ExperimentRuleType>(
              initialValue: _ruleType,
              decoration: const InputDecoration(
                labelText: 'Hipótesis',
                border: OutlineInputBorder(),
              ),
              items: ExperimentRuleType.values
                  .map(
                    (ExperimentRuleType type) =>
                        DropdownMenuItem<ExperimentRuleType>(
                      value: type,
                      child: Text(type.label),
                    ),
                  )
                  .toList(),
              onChanged: (ExperimentRuleType? value) {
                if (value != null) {
                  setState(() {
                    _ruleType = value;
                    _applySuggestedValues(value);
                  });
                }
              },
            ),
            const SizedBox(height: 12),
            Row(
              children: <Widget>[
                Expanded(
                  child: TextField(
                    controller: _minimumController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Valor mínimo',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _maximumController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Valor máximo',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 16,
              runSpacing: 12,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: <Widget>[
                DropdownButton<int>(
                  value: _windowSize,
                  items: <int>[100, 200, 300, 500]
                      .where((int value) => value <= widget.history.length)
                      .map(
                        (int value) => DropdownMenuItem<int>(
                          value: value,
                          child: Text('Ventana: $value'),
                        ),
                      )
                      .toList(),
                  onChanged: (int? value) {
                    if (value != null) {
                      setState(() => _windowSize = value);
                    }
                  },
                ),
                DropdownButton<int>(
                  value: _step,
                  items: <int>[25, 50, 100, 200]
                      .where((int value) => value <= _windowSize)
                      .map(
                        (int value) => DropdownMenuItem<int>(
                          value: value,
                          child: Text('Paso: $value'),
                        ),
                      )
                      .toList(),
                  onChanged: (int? value) {
                    if (value != null) {
                      setState(() => _step = value);
                    }
                  },
                ),
                FilledButton.icon(
                  onPressed: _runBacktesting,
                  icon: const Icon(Icons.analytics_outlined),
                  label: const Text('EJECUTAR BACKTESTING'),
                  style: FilledButton.styleFrom(
                    backgroundColor: gold,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 15,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummary(BacktestingReport report) {
    return Column(
      children: <Widget>[
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: <Widget>[
            _MetricCard(
              title: 'Ventanas',
              value: '${report.windows.length}',
              caption: '${report.windowSize} sorteos',
              icon: Icons.view_week_outlined,
            ),
            _MetricCard(
              title: 'Promedio',
              value: '${(report.averageRate * 100).toStringAsFixed(1)}%',
              caption: 'cumplimiento',
              icon: Icons.functions_outlined,
            ),
            _MetricCard(
              title: 'Desviación',
              value:
                  '${(report.standardDeviation * 100).toStringAsFixed(2)} pp',
              caption: 'entre ventanas',
              icon: Icons.show_chart,
            ),
            _MetricCard(
              title: 'Consistencia',
              value: report.consistencyScore.toStringAsFixed(1),
              caption: 'de 100',
              icon: Icons.verified_outlined,
            ),
          ],
        ),
        const SizedBox(height: 16),
        Card(
          color: panel,
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    const Icon(Icons.insights, color: gold),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        report.conclusion,
                        style: const TextStyle(
                          color: gold,
                          fontWeight: FontWeight.bold,
                          fontSize: 17,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                LinearProgressIndicator(
                  value: report.consistencyScore / 100,
                  color: gold,
                  backgroundColor: const Color(0xFF2A103A),
                ),
                const SizedBox(height: 10),
                Text(
                  'Rango observado: '
                  '${(report.minimumRate * 100).toStringAsFixed(1)}% – '
                  '${(report.maximumRate * 100).toStringAsFixed(1)}%',
                ),
                const SizedBox(height: 8),
                const Text(
                  'La consistencia mide variación histórica entre ventanas. '
                  'No es una probabilidad de ganar.',
                  style: TextStyle(color: Colors.white60, fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWindowTable(BacktestingReport report) {
    return Card(
      color: panel,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            columns: const <DataColumn>[
              DataColumn(label: Text('Ventana')),
              DataColumn(label: Text('Sorteos')),
              DataColumn(label: Text('Coincidencias')),
              DataColumn(label: Text('Tasa')),
              DataColumn(label: Text('Gráfico')),
            ],
            rows: report.windows.map((BacktestingWindowResult result) {
              return DataRow(
                cells: <DataCell>[
                  DataCell(Text('${result.windowNumber}')),
                  DataCell(
                    Text('${result.startIndex} – ${result.endIndex}'),
                  ),
                  DataCell(Text('${result.matches}/${result.samples}')),
                  DataCell(
                    Text(
                      '${(result.matchRate * 100).toStringAsFixed(1)}%',
                    ),
                  ),
                  DataCell(
                    SizedBox(
                      width: 150,
                      child: LinearProgressIndicator(
                        value: result.matchRate,
                        color: gold,
                        backgroundColor: const Color(0xFF2A103A),
                      ),
                    ),
                  ),
                ],
              );
            }).toList(growable: false),
          ),
        ),
      ),
    );
  }

  void _applySuggestedValues(ExperimentRuleType type) {
    switch (type) {
      case ExperimentRuleType.sumRange:
        _minimumController.text = '103';
        _maximumController.text = '136';
      case ExperimentRuleType.exactEvenCount:
        _minimumController.text = '3';
        _maximumController.text = '3';
      case ExperimentRuleType.maximumConsecutivePairs:
        _minimumController.text = '0';
        _maximumController.text = '1';
      case ExperimentRuleType.exactRepeatCount:
        _minimumController.text = '0';
        _maximumController.text = '1';
    }
  }

  void _runBacktesting() {
    final int? minimum = int.tryParse(_minimumController.text.trim());
    final int? maximum = int.tryParse(_maximumController.text.trim());

    if (minimum == null || maximum == null || minimum > maximum) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Revisa los valores mínimo y máximo.'),
        ),
      );
      return;
    }

    final LaboratoryExperiment experiment = LaboratoryExperiment(
      id: 'BT-${DateTime.now().millisecondsSinceEpoch}',
      name: _ruleType.label,
      description: 'Backtesting de ventanas móviles',
      ruleType: _ruleType,
      minimum: minimum,
      maximum: maximum,
      createdAt: DateTime.now(),
    );

    try {
      final BacktestingReport report = _engine.run(
        experiment: experiment,
        history: widget.history,
        windowSize: _windowSize,
        step: _step,
      );

      setState(() {
        _report = report;
        _status = 'Backtesting completado.';
      });
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo ejecutar: $error')),
      );
    }
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
  final String value;
  final String caption;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: panel,
      child: SizedBox(
        width: 220,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: <Widget>[
              Icon(icon, color: gold, size: 30),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(title, style: const TextStyle(color: Colors.white60)),
                    Text(
                      value,
                      style: const TextStyle(
                        color: gold,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(caption),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
