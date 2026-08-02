import 'package:flutter/material.dart';
import '../../core/models/laboratory_experiment.dart';
import '../../core/services/laboratory_engine.dart';

class LaboratoryScreen extends StatefulWidget {
  const LaboratoryScreen({
    required this.history,
    super.key,
  });

  final List<List<int>> history;

  @override
  State<LaboratoryScreen> createState() => _LaboratoryScreenState();
}

class _LaboratoryScreenState extends State<LaboratoryScreen> {
  static const Color gold = Color(0xFFE8B85A);
  static const Color panel = Color(0xFF1A1022);

  final LaboratoryEngine _engine = const LaboratoryEngine();
  final List<ExperimentResult> _results = <ExperimentResult>[];

  ExperimentRuleType _ruleType = ExperimentRuleType.sumRange;
  final TextEditingController _nameController =
      TextEditingController(text: 'Rango de suma experimental');
  final TextEditingController _descriptionController = TextEditingController(
    text: 'Comprueba la estabilidad temporal de un rango de suma.',
  );
  final TextEditingController _minimumController =
      TextEditingController(text: '103');
  final TextEditingController _maximumController =
      TextEditingController(text: '136');

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _minimumController.dispose();
    _maximumController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final int stableExperiments = _results
        .where((ExperimentResult result) => result.stabilityScore >= 75)
        .length;

    return ListView(
      padding: const EdgeInsets.all(24),
      children: <Widget>[
        Text(
          'Laboratorio PIT',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: gold,
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Crea hipótesis estructurales y evalúa su estabilidad fuera de muestra.',
        ),
        const SizedBox(height: 20),
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: <Widget>[
            _MetricCard(
              title: 'Histórico',
              value: '${widget.history.length}',
              caption: 'sorteos disponibles',
              icon: Icons.storage_outlined,
            ),
            _MetricCard(
              title: 'Experimentos',
              value: '${_results.length}',
              caption: 'ejecutados en sesión',
              icon: Icons.science_outlined,
            ),
            _MetricCard(
              title: 'Estables',
              value: '$stableExperiments',
              caption: 'puntaje ≥ 75',
              icon: Icons.verified_outlined,
            ),
          ],
        ),
        const SizedBox(height: 20),
        Card(
          color: panel,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Text(
                  'NUEVO EXPERIMENTO',
                  style: TextStyle(
                    color: gold,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nombre',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _descriptionController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Descripción',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<ExperimentRuleType>(
                  initialValue: _ruleType,
                  decoration: const InputDecoration(
                    labelText: 'Tipo de regla',
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
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: _runExperiment,
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('PROBAR CONTRA HISTÓRICO'),
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
          ),
        ),
        const SizedBox(height: 20),
        if (_results.isEmpty)
          const Card(
            color: panel,
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'Todavía no se ha ejecutado ningún experimento. '
                'Los resultados medirán estabilidad temporal, no probabilidad de ganar.',
              ),
            ),
          )
        else
          ..._results.reversed.map(
            (ExperimentResult result) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _ExperimentResultCard(result: result),
            ),
          ),
      ],
    );
  }

  void _applySuggestedValues(ExperimentRuleType type) {
    switch (type) {
      case ExperimentRuleType.sumRange:
        _nameController.text = 'Rango de suma experimental';
        _minimumController.text = '103';
        _maximumController.text = '136';
      case ExperimentRuleType.exactEvenCount:
        _nameController.text = 'Paridad 3 pares / 3 impares';
        _minimumController.text = '3';
        _maximumController.text = '3';
      case ExperimentRuleType.maximumConsecutivePairs:
        _nameController.text = 'Máximo una pareja consecutiva';
        _minimumController.text = '0';
        _maximumController.text = '1';
      case ExperimentRuleType.exactRepeatCount:
        _nameController.text = 'Repetición respecto al sorteo anterior';
        _minimumController.text = '0';
        _maximumController.text = '1';
    }
  }

  void _runExperiment() {
    final int? minimum = int.tryParse(_minimumController.text.trim());
    final int? maximum = int.tryParse(_maximumController.text.trim());

    if (_nameController.text.trim().isEmpty ||
        minimum == null ||
        maximum == null ||
        minimum > maximum) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Revisa el nombre y el rango del experimento.'),
        ),
      );
      return;
    }

    final LaboratoryExperiment experiment = LaboratoryExperiment(
      id: 'EXP-${DateTime.now().millisecondsSinceEpoch}',
      name: _nameController.text.trim(),
      description: _descriptionController.text.trim(),
      ruleType: _ruleType,
      minimum: minimum,
      maximum: maximum,
      createdAt: DateTime.now(),
    );

    try {
      final ExperimentResult result = _engine.evaluate(
        experiment: experiment,
        history: widget.history,
      );

      setState(() {
        _results.add(result);
      });
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo ejecutar: $error')),
      );
    }
  }
}

class _ExperimentResultCard extends StatelessWidget {
  const _ExperimentResultCard({required this.result});

  static const Color gold = Color(0xFFE8B85A);
  static const Color panel = Color(0xFF1A1022);

  final ExperimentResult result;

  @override
  Widget build(BuildContext context) {
    final Color statusColor = result.stabilityScore >= 75
        ? Colors.greenAccent
        : result.stabilityScore >= 55
            ? Colors.amberAccent
            : Colors.orangeAccent;

    return Card(
      color: panel,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    result.experiment.name,
                    style: const TextStyle(
                      color: gold,
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Text(
                  result.conclusion,
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(result.experiment.description),
            const SizedBox(height: 14),
            Wrap(
              spacing: 28,
              runSpacing: 12,
              children: <Widget>[
                _Value(
                  label: 'Entrenamiento',
                  value:
                      '${(result.trainingRate * 100).toStringAsFixed(1)}%',
                  caption:
                      '${result.trainingMatches}/${result.trainingSamples}',
                ),
                _Value(
                  label: 'Validación',
                  value:
                      '${(result.validationRate * 100).toStringAsFixed(1)}%',
                  caption:
                      '${result.validationMatches}/${result.validationSamples}',
                ),
                _Value(
                  label: 'Diferencia',
                  value:
                      '${(result.absoluteGap * 100).toStringAsFixed(1)} pp',
                  caption: 'entre periodos',
                ),
                _Value(
                  label: 'Estabilidad',
                  value: result.stabilityScore.toStringAsFixed(1),
                  caption: 'de 100',
                ),
              ],
            ),
            const SizedBox(height: 14),
            LinearProgressIndicator(
              value: result.stabilityScore / 100,
              color: statusColor,
              backgroundColor: const Color(0xFF2A103A),
            ),
            const SizedBox(height: 8),
            const Text(
              'La prueba divide el histórico en 70% entrenamiento y '
              '30% validación. Evalúa consistencia temporal, no capacidad predictiva.',
              style: TextStyle(color: Colors.white60, fontSize: 12),
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

class _Value extends StatelessWidget {
  const _Value({
    required this.label,
    required this.value,
    required this.caption,
  });

  static const Color gold = Color(0xFFE8B85A);

  final String label;
  final String value;
  final String caption;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 145,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(label, style: const TextStyle(color: Colors.white60)),
          Text(
            value,
            style: const TextStyle(
              color: gold,
              fontSize: 21,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(caption),
        ],
      ),
    );
  }
}
