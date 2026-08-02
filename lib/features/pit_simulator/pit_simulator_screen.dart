import 'package:flutter/material.dart';
import '../../core/models/model_config.dart';
import '../../core/models/pit_simulation.dart';
import '../../core/models/ranked_combination.dart';
import '../../core/services/pit_simulation_engine.dart';

class PitSimulatorScreen extends StatefulWidget {
  const PitSimulatorScreen({
    required this.model,
    required this.modelHistory,
    required this.drawHistory,
    required this.ranking,
    required this.onApply,
    super.key,
  });

  final ModelConfig model;
  final List<ModelConfig> modelHistory;
  final List<List<int>> drawHistory;
  final List<RankedCombination> ranking;
  final Future<void> Function(ModelConfig config) onApply;

  @override
  State<PitSimulatorScreen> createState() => _PitSimulatorScreenState();
}

class _PitSimulatorScreenState extends State<PitSimulatorScreen> {
  static const Color gold = Color(0xFFE8B85A);
  static const Color panel = Color(0xFF1A1022);

  late List<RuleConfig> _draftRules;
  PitSimulationResult? _result;
  bool _running = false;
  bool _applying = false;

  @override
  void initState() {
    super.initState();
    _resetDraft();
  }

  @override
  void didUpdateWidget(covariant PitSimulatorScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.model.modelVersion != widget.model.modelVersion) {
      _resetDraft();
      _result = null;
    }
  }

  void _resetDraft() {
    _draftRules = List<RuleConfig>.from(widget.model.rules);
  }

  ModelConfig get _experimentalModel => widget.model.copyWith(
        modelVersion: _nextPatch(widget.model.modelVersion),
        rules: List<RuleConfig>.unmodifiable(_draftRules),
        updatedAt: DateTime.now(),
        changeNote: 'Cambios aplicados desde Simulador PIT.',
      );

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
                    'Simulador PIT',
                    style:
                        Theme.of(context).textTheme.headlineMedium?.copyWith(
                              color: gold,
                              fontWeight: FontWeight.bold,
                            ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Prueba cambios sin modificar el Modelo PIT '
                    'v${widget.model.modelVersion}.',
                  ),
                ],
              ),
            ),
            OutlinedButton.icon(
              onPressed: _running || _applying
                  ? null
                  : () {
                      setState(() {
                        _resetDraft();
                        _result = null;
                      });
                    },
              icon: const Icon(Icons.restart_alt),
              label: const Text('DESCARTAR CAMBIOS'),
            ),
          ],
        ),
        const SizedBox(height: 18),
        if (widget.ranking.isEmpty)
          const Card(
            color: panel,
            child: Padding(
              padding: EdgeInsets.all(22),
              child: Text(
                'Genera primero un ranking desde el Dashboard. '
                'El simulador compara el modelo experimental sobre las '
                'combinaciones del ranking actual.',
              ),
            ),
          ),
        const SizedBox(height: 8),
        _buildEditor(),
        const SizedBox(height: 18),
        FilledButton.icon(
          onPressed:
              widget.ranking.isEmpty || _running ? null : _simulate,
          icon: _running
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.science_outlined),
          label: Text(
            _running ? 'SIMULANDO...' : 'EJECUTAR SIMULACIÓN',
          ),
          style: FilledButton.styleFrom(
            backgroundColor: gold,
            foregroundColor: Colors.black,
            padding: const EdgeInsets.symmetric(
              horizontal: 22,
              vertical: 16,
            ),
          ),
        ),
        if (_result != null) ...<Widget>[
          const SizedBox(height: 20),
          _buildSummary(_result!),
          const SizedBox(height: 18),
          _buildRankingComparison(_result!),
          const SizedBox(height: 18),
          _buildDecisionPanel(_result!),
        ],
      ],
    );
  }

  Widget _buildEditor() {
    return Card(
      color: panel,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Text(
              'MODELO EXPERIMENTAL',
              style: TextStyle(
                color: gold,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 14),
            ...List<Widget>.generate(_draftRules.length, (int index) {
              final RuleConfig rule = _draftRules[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF24142C),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    children: <Widget>[
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        value: rule.enabled,
                        activeThumbColor: gold,
                        title: Text(
                          '${rule.id} · ${rule.label}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Text(
                          '${rule.category} · Evidencia '
                          '${rule.evidenceLevel}/5',
                        ),
                        onChanged: (bool value) {
                          setState(() {
                            _draftRules[index] =
                                rule.copyWith(enabled: value);
                            _result = null;
                          });
                        },
                      ),
                      Row(
                        children: <Widget>[
                          const SizedBox(
                            width: 80,
                            child: Text('Peso'),
                          ),
                          Expanded(
                            child: Slider(
                              value: rule.weight
                                  .clamp(0.0, 3.0)
                                  .toDouble(),
                              min: 0,
                              max: 3,
                              divisions: 60,
                              label: rule.weight.toStringAsFixed(2),
                              onChanged: rule.enabled
                                  ? (double value) {
                                      setState(() {
                                        _draftRules[index] = rule.copyWith(
                                          weight: double.parse(
                                            value.toStringAsFixed(2),
                                          ),
                                        );
                                        _result = null;
                                      });
                                    }
                                  : null,
                            ),
                          ),
                          SizedBox(
                            width: 60,
                            child: Text(
                              rule.weight.toStringAsFixed(2),
                              textAlign: TextAlign.end,
                              style: const TextStyle(
                                color: gold,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildSummary(PitSimulationResult result) {
    return Column(
      children: <Widget>[
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: <Widget>[
            _DeltaCard(
              title: 'Salud del modelo',
              before: result.officialMetrics.overallHealth,
              after: result.experimentalMetrics.overallHealth,
              suffix: '',
            ),
            _DeltaCard(
              title: 'Puntuación de auditoría',
              before: result.officialAudit.score,
              after: result.experimentalAudit.score,
              suffix: '',
            ),
            _DeltaCard(
              title: 'Índice PIT líder',
              before: result.officialRanking.isEmpty
                  ? 0
                  : result.officialRanking.first.pitIndex,
              after: result.experimentalRanking.isEmpty
                  ? 0
                  : result.experimentalRanking.first.pitIndex,
              suffix: '',
            ),
            _DeltaCard(
              title: 'Score líder',
              before: result.officialRanking.isEmpty
                  ? 0
                  : result.officialRanking.first.score,
              after: result.experimentalRanking.isEmpty
                  ? 0
                  : result.experimentalRanking.first.score,
              suffix: '',
            ),
          ],
        ),
        const SizedBox(height: 16),
        Card(
          color: panel,
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: <Widget>[
                const Icon(Icons.swap_vert, color: gold, size: 30),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '${result.changedPositions} de '
                    '${result.experimentalRanking.length} posiciones '
                    'cambiaron dentro del ranking actual.',
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRankingComparison(PitSimulationResult result) {
    final int count = result.officialRanking.length <
            result.experimentalRanking.length
        ? result.officialRanking.length
        : result.experimentalRanking.length;

    return Card(
      color: panel,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Text(
              'COMPARACIÓN DEL RANKING ACTUAL',
              style: TextStyle(
                color: gold,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: const <DataColumn>[
                  DataColumn(label: Text('#')),
                  DataColumn(label: Text('Modelo oficial')),
                  DataColumn(label: Text('Score')),
                  DataColumn(label: Text('Modelo experimental')),
                  DataColumn(label: Text('Score')),
                  DataColumn(label: Text('Cambio')),
                ],
                rows: List<DataRow>.generate(count, (int index) {
                  final RankedCombination official =
                      result.officialRanking[index];
                  final RankedCombination experimental =
                      result.experimentalRanking[index];
                  final bool changed =
                      official.label != experimental.label;

                  return DataRow(
                    cells: <DataCell>[
                      DataCell(Text('${index + 1}')),
                      DataCell(Text(official.label)),
                      DataCell(
                        Text(official.score.toStringAsFixed(3)),
                      ),
                      DataCell(Text(experimental.label)),
                      DataCell(
                        Text(experimental.score.toStringAsFixed(3)),
                      ),
                      DataCell(
                        Icon(
                          changed
                              ? Icons.swap_vert
                              : Icons.remove,
                          color: changed ? gold : Colors.white38,
                        ),
                      ),
                    ],
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDecisionPanel(PitSimulationResult result) {
    final bool recommendationPositive =
        result.healthDelta >= 0 &&
        result.auditDelta >= 0 &&
        result.experimentalAudit.criticalCount <=
            result.officialAudit.criticalCount;

    return Card(
      color: panel,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(
                  recommendationPositive
                      ? Icons.thumb_up_alt_outlined
                      : Icons.warning_amber_outlined,
                  color: recommendationPositive
                      ? Colors.greenAccent
                      : Colors.amberAccent,
                  size: 30,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    recommendationPositive
                        ? 'La simulación no deteriora los indicadores principales.'
                        : 'La simulación requiere revisión antes de aplicarse.',
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              'Salud: ${_signed(result.healthDelta)} · '
              'Auditoría: ${_signed(result.auditDelta)} · '
              'Alertas críticas: '
              '${result.officialAudit.criticalCount} → '
              '${result.experimentalAudit.criticalCount}',
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: _applying ? null : _applySimulation,
              icon: _applying
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save_outlined),
              label: Text(
                _applying
                    ? 'APLICANDO...'
                    : 'APLICAR COMO NUEVA VERSIÓN',
              ),
              style: FilledButton.styleFrom(
                backgroundColor: gold,
                foregroundColor: Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _simulate() async {
    setState(() => _running = true);

    try {
      final PitSimulationResult result =
          const PitSimulationEngine().simulate(
        officialModel: widget.model,
        experimentalModel: _experimentalModel,
        modelHistory: widget.modelHistory,
        drawHistory: widget.drawHistory,
        officialRanking: widget.ranking,
      );

      if (mounted) {
        setState(() => _result = result);
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo simular: $error')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _running = false);
      }
    }
  }

  Future<void> _applySimulation() async {
    setState(() => _applying = true);

    try {
      await widget.onApply(_experimentalModel);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Modelo PIT v${_experimentalModel.modelVersion} aplicado.',
            ),
          ),
        );
        setState(() => _result = null);
      }
    } finally {
      if (mounted) {
        setState(() => _applying = false);
      }
    }
  }

  static String _signed(double value) {
    final String sign = value > 0 ? '+' : '';
    return '$sign${value.toStringAsFixed(1)}';
  }

  static String _nextPatch(String current) {
    final List<int?> parts =
        current.split('.').map(int.tryParse).toList(growable: false);

    if (parts.length != 3 || parts.any((int? part) => part == null)) {
      return '1.0.1';
    }

    return '${parts[0]}.${parts[1]}.${parts[2]! + 1}';
  }
}

class _DeltaCard extends StatelessWidget {
  const _DeltaCard({
    required this.title,
    required this.before,
    required this.after,
    required this.suffix,
  });

  static const Color gold = Color(0xFFE8B85A);
  static const Color panel = Color(0xFF1A1022);

  final String title;
  final double before;
  final double after;
  final String suffix;

  @override
  Widget build(BuildContext context) {
    final double delta = after - before;
    final Color color = delta > 0
        ? Colors.greenAccent
        : delta < 0
            ? Colors.orangeAccent
            : Colors.white60;

    return Card(
      color: panel,
      child: SizedBox(
        width: 245,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                title,
                style: const TextStyle(color: Colors.white60),
              ),
              const SizedBox(height: 10),
              Text(
                '${before.toStringAsFixed(1)}$suffix → '
                '${after.toStringAsFixed(1)}$suffix',
                style: const TextStyle(
                  color: gold,
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                '${delta > 0 ? '+' : ''}${delta.toStringAsFixed(1)}$suffix',
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
