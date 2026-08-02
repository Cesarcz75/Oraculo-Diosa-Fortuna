import 'package:flutter/material.dart';
import '../../core/models/laboratory_experiment.dart';
import '../../core/services/laboratory_engine.dart';
import '../../core/services/experiment_repository.dart';

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
  final ExperimentRepository _repository = const ExperimentRepository();
  final List<ManagedExperiment> _experiments = <ManagedExperiment>[];
  final Set<String> _selectedIds = <String>{};

  ExperimentRuleType _ruleType = ExperimentRuleType.sumRange;
  bool _showArchived = false;
  bool _loadingSavedExperiments = true;
  bool _savingExperiments = false;
  String _persistenceStatus = 'Cargando expedientes guardados...';

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
  void initState() {
    super.initState();
    _loadSavedExperiments();
  }

  Future<void> _loadSavedExperiments() async {
    try {
      final List<ManagedExperiment> saved = await _repository.load();
      if (!mounted) {
        return;
      }
      setState(() {
        _experiments
          ..clear()
          ..addAll(saved);
        _loadingSavedExperiments = false;
        _persistenceStatus = saved.isEmpty
            ? 'No hay expedientes guardados todavía.'
            : '${saved.length} expediente(s) recuperado(s).';
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _loadingSavedExperiments = false;
        _persistenceStatus = 'No se pudieron cargar: $error';
      });
    }
  }

  Future<void> _saveExperiments() async {
    if (mounted) {
      setState(() {
        _savingExperiments = true;
        _persistenceStatus = 'Guardando expedientes...';
      });
    }

    try {
      await _repository.save(_experiments);
      if (!mounted) {
        return;
      }
      setState(() {
        _savingExperiments = false;
        _persistenceStatus =
            '${_experiments.length} expediente(s) guardado(s) localmente.';
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _savingExperiments = false;
        _persistenceStatus = 'Error al guardar: $error';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudieron guardar: $error')),
      );
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _minimumController.dispose();
    _maximumController.dispose();
    super.dispose();
  }

  List<ManagedExperiment> get _visibleExperiments {
    return _experiments
        .where((ManagedExperiment item) => _showArchived || !item.archived)
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final int activeCount =
        _experiments.where((ManagedExperiment item) => !item.archived).length;
    final int archivedCount =
        _experiments.where((ManagedExperiment item) => item.archived).length;
    final int stableCount = _experiments.where((ManagedExperiment item) {
      return !item.archived && item.result.stabilityScore >= 75;
    }).length;

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
          'Crea, administra, duplica y compara hipótesis estructurales.',
        ),
        const SizedBox(height: 14),
        Card(
          color: panel,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: <Widget>[
                Icon(
                  _loadingSavedExperiments
                      ? Icons.sync
                      : Icons.save_outlined,
                  color: gold,
                ),
                const SizedBox(width: 10),
                Expanded(child: Text(_persistenceStatus)),
                if (_loadingSavedExperiments || _savingExperiments)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
          ),
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
              title: 'Activos',
              value: '$activeCount',
              caption: 'experimentos',
              icon: Icons.science_outlined,
            ),
            _MetricCard(
              title: 'Estables',
              value: '$stableCount',
              caption: 'puntaje ≥ 75',
              icon: Icons.verified_outlined,
            ),
            _MetricCard(
              title: 'Archivados',
              value: '$archivedCount',
              caption: 'experimentos',
              icon: Icons.archive_outlined,
            ),
          ],
        ),
        const SizedBox(height: 20),
        _buildExperimentForm(),
        const SizedBox(height: 20),
        _buildToolbar(),
        const SizedBox(height: 12),
        if (_visibleExperiments.isEmpty)
          const Card(
            color: panel,
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'Todavía no hay experimentos visibles. '
                'Los resultados medirán estabilidad temporal, no probabilidad de ganar.',
              ),
            ),
          )
        else
          ..._visibleExperiments.reversed.map(
            (ManagedExperiment item) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _ExperimentResultCard(
                item: item,
                selected: _selectedIds.contains(
                  item.result.experiment.id,
                ),
                onSelected: (bool selected) {
                  setState(() {
                    if (selected) {
                      if (_selectedIds.length < 2) {
                        _selectedIds.add(item.result.experiment.id);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Selecciona como máximo dos experimentos.',
                            ),
                          ),
                        );
                      }
                    } else {
                      _selectedIds.remove(item.result.experiment.id);
                    }
                  });
                },
                onDuplicate: () => _duplicate(item),
                onArchive: () => _toggleArchive(item),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildExperimentForm() {
    return Card(
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
    );
  }

  Widget _buildToolbar() {
    return Card(
      color: panel,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Wrap(
          spacing: 10,
          runSpacing: 10,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: <Widget>[
            FilterChip(
              label: const Text('Mostrar archivados'),
              selected: _showArchived,
              onSelected: (bool value) {
                setState(() => _showArchived = value);
              },
            ),
            OutlinedButton.icon(
              onPressed: _selectedIds.length == 2 ? _compareSelected : null,
              icon: const Icon(Icons.compare_arrows),
              label: const Text('Comparar seleccionados'),
            ),
            TextButton.icon(
              onPressed: _selectedIds.isEmpty
                  ? null
                  : () => setState(_selectedIds.clear),
              icon: const Icon(Icons.clear_all),
              label: const Text('Limpiar selección'),
            ),
            Text(
              '${_selectedIds.length}/2 seleccionados',
              style: const TextStyle(color: Colors.white60),
            ),
          ],
        ),
      ),
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
        _experiments.add(ManagedExperiment(result: result));
      });
      _saveExperiments();
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo ejecutar: $error')),
      );
    }
  }

  void _duplicate(ManagedExperiment item) {
    final LaboratoryExperiment source = item.result.experiment;
    setState(() {
      _ruleType = source.ruleType;
      _nameController.text = '${source.name} copia';
      _descriptionController.text = source.description;
      _minimumController.text = '${source.minimum}';
      _maximumController.text = '${source.maximum}';
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Los datos fueron copiados al formulario. Ajusta y vuelve a probar.',
        ),
      ),
    );
  }

  void _toggleArchive(ManagedExperiment item) {
    final int index = _experiments.indexWhere(
      (ManagedExperiment candidate) =>
          candidate.result.experiment.id ==
          item.result.experiment.id,
    );

    if (index == -1) {
      return;
    }

    setState(() {
      _experiments[index] = item.copyWith(archived: !item.archived);
      _selectedIds.remove(item.result.experiment.id);
    });
    _saveExperiments();
  }

  void _compareSelected() {
    final List<ManagedExperiment> selected = _experiments.where(
      (ManagedExperiment item) {
        return _selectedIds.contains(item.result.experiment.id);
      },
    ).toList(growable: false);

    if (selected.length != 2) {
      return;
    }

    showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Comparador de experimentos'),
          content: SizedBox(
            width: 720,
            child: _ComparisonView(
              first: selected[0].result,
              second: selected[1].result,
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cerrar'),
            ),
          ],
        );
      },
    );
  }
}

class _ExperimentResultCard extends StatelessWidget {
  const _ExperimentResultCard({
    required this.item,
    required this.selected,
    required this.onSelected,
    required this.onDuplicate,
    required this.onArchive,
  });

  static const Color gold = Color(0xFFE8B85A);
  static const Color panel = Color(0xFF1A1022);

  final ManagedExperiment item;
  final bool selected;
  final ValueChanged<bool> onSelected;
  final VoidCallback onDuplicate;
  final VoidCallback onArchive;

  @override
  Widget build(BuildContext context) {
    final ExperimentResult result = item.result;
    final Color statusColor = result.stabilityScore >= 75
        ? Colors.greenAccent
        : result.stabilityScore >= 55
            ? Colors.amberAccent
            : Colors.orangeAccent;

    return Card(
      color: panel,
      child: Opacity(
        opacity: item.archived ? 0.58 : 1,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Checkbox(
                    value: selected,
                    onChanged: item.archived
                        ? null
                        : (bool? value) => onSelected(value ?? false),
                  ),
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
                  if (item.archived)
                    const Padding(
                      padding: EdgeInsets.only(right: 10),
                      child: Chip(label: Text('Archivado')),
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
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: <Widget>[
                  OutlinedButton.icon(
                    onPressed: onDuplicate,
                    icon: const Icon(Icons.copy_outlined),
                    label: const Text('Duplicar'),
                  ),
                  OutlinedButton.icon(
                    onPressed: onArchive,
                    icon: Icon(
                      item.archived
                          ? Icons.unarchive_outlined
                          : Icons.archive_outlined,
                    ),
                    label: Text(item.archived ? 'Restaurar' : 'Archivar'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'La prueba evalúa consistencia temporal, no capacidad predictiva.',
                style: TextStyle(color: Colors.white60, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ComparisonView extends StatelessWidget {
  const _ComparisonView({
    required this.first,
    required this.second,
  });

  static const Color gold = Color(0xFFE8B85A);

  final ExperimentResult first;
  final ExperimentResult second;

  @override
  Widget build(BuildContext context) {
    final ExperimentResult winner =
        first.stabilityScore >= second.stabilityScore ? first : second;
    final double difference =
        (first.stabilityScore - second.stabilityScore).abs();

    return SingleChildScrollView(
      child: Column(
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(child: _ComparisonColumn(result: first)),
              const SizedBox(width: 16),
              Expanded(child: _ComparisonColumn(result: second)),
            ],
          ),
          const SizedBox(height: 20),
          Card(
            color: const Color(0xFF1A1022),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                children: <Widget>[
                  const Text(
                    'Mayor estabilidad temporal',
                    style: TextStyle(color: Colors.white60),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    winner.experiment.name,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: gold,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Diferencia: ${difference.toStringAsFixed(1)} puntos',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'El comparador usa estabilidad histórica, no probabilidad de ganar.',
            style: TextStyle(color: Colors.white60, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _ComparisonColumn extends StatelessWidget {
  const _ComparisonColumn({required this.result});

  static const Color gold = Color(0xFFE8B85A);

  final ExperimentResult result;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFF1A1022),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              result.experiment.name,
              style: const TextStyle(
                color: gold,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _ComparisonRow(
              label: 'Entrenamiento',
              value: '${(result.trainingRate * 100).toStringAsFixed(1)}%',
            ),
            _ComparisonRow(
              label: 'Validación',
              value: '${(result.validationRate * 100).toStringAsFixed(1)}%',
            ),
            _ComparisonRow(
              label: 'Diferencia',
              value: '${(result.absoluteGap * 100).toStringAsFixed(1)} pp',
            ),
            _ComparisonRow(
              label: 'Estabilidad',
              value: result.stabilityScore.toStringAsFixed(1),
            ),
            const SizedBox(height: 10),
            LinearProgressIndicator(
              value: result.stabilityScore / 100,
              color: gold,
              backgroundColor: const Color(0xFF2A103A),
            ),
          ],
        ),
      ),
    );
  }
}

class _ComparisonRow extends StatelessWidget {
  const _ComparisonRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: <Widget>[
          Expanded(child: Text(label)),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
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
