import 'dart:isolate';
import 'package:flutter/material.dart';
import '../../core/models/model_config.dart';
import '../../core/models/ranked_combination.dart';
import '../../core/models/pit_audit.dart';
import '../../core/models/pit_metrics.dart';
import '../../core/services/history_repository.dart';
import '../../core/services/model_config_repository.dart';
import '../../core/services/ranking_worker.dart';
import '../../core/services/pit_audit_engine.dart';
import '../../core/services/pit_metrics_engine.dart';
import '../laboratory/laboratory_screen.dart';
import '../research_center/research_center_screen.dart';
import '../backtesting/backtesting_screen.dart';
import '../model_settings/model_settings_screen.dart';
import '../model_comparison/model_comparison_screen.dart';
import '../athena/athena_screen.dart';
import '../reports/professional_report_screen.dart';
import '../pit_metrics/pit_metrics_screen.dart';
import '../pit_audit/pit_audit_screen.dart';
import '../pit_simulator/pit_simulator_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const Color gold = Color(0xFFE8B85A);
  static const Color purple = Color(0xFF5B1FA3);
  static const Color panel = Color(0xFF1A1022);

  final HistoryRepository _repository = const HistoryRepository();
  final ModelConfigRepository _configRepository =
      const ModelConfigRepository();
  final List<TextEditingController> _controllers =
      List<TextEditingController>.generate(
    6,
    (_) => TextEditingController(),
  );

  List<List<int>> _history = <List<int>>[];
  List<RankedCombination> _ranking = <RankedCombination>[];
  ModelConfig? _config;
  List<ModelConfig> _modelHistory = <ModelConfig>[];
  bool _loading = true;
  bool _running = false;
  double _progress = 0;
  int _selectedIndex = 0;
  int _topN = 10;
  String _status = 'Cargando Motor Fortuna...';
  ReceivePort? _receivePort;
  Isolate? _isolate;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  @override
  void dispose() {
    _receivePort?.close();
    _isolate?.kill(priority: Isolate.immediate);
    for (final TextEditingController controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _loadHistory() async {
    try {
      final List<Object> loaded = await Future.wait<Object>(<Future<Object>>[
        _repository.load(),
        _configRepository.load(),
        _configRepository.loadHistory(),
      ]);
      final List<List<int>> history = loaded[0] as List<List<int>>;
      final ModelConfig config = loaded[1] as ModelConfig;
      final List<ModelConfig> modelHistory =
          loaded[2] as List<ModelConfig>;
      final List<int> last = history.last;

      for (int index = 0; index < 6; index++) {
        _controllers[index].text = last[index].toString();
      }

      if (!mounted) {
        return;
      }

      setState(() {
        _history = history;
        _config = config;
        _modelHistory = modelHistory;
        _loading = false;
        _status = 'Motor Fortuna listo · ${history.length} sorteos cargados.';
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _loading = false;
        _status = 'Error al iniciar: $error';
      });
    }
  }

  List<int> _readLatest() {
    final List<int?> parsed = _controllers
        .map((TextEditingController controller) =>
            int.tryParse(controller.text.trim()))
        .toList();

    if (parsed.any((int? value) => value == null || value < 1 || value > 39)) {
      throw const FormatException(
        'Ingresa seis números enteros entre 1 y 39.',
      );
    }

    final List<int> result = parsed.whereType<int>().toList()..sort();

    if (result.toSet().length != 6) {
      throw const FormatException('Los seis números deben ser distintos.');
    }

    return result;
  }

  Future<void> _generate() async {
    final ModelConfig? config = _config;
    if (config == null) {
      _showMessage('La configuración del modelo aún no está disponible.');
      return;
    }

    try {
      final List<int> latest = _readLatest();

      _receivePort?.close();
      _isolate?.kill(priority: Isolate.immediate);

      final ReceivePort port = ReceivePort();
      _receivePort = port;

      setState(() {
        _running = true;
        _progress = 0;
        _ranking = <RankedCombination>[];
        _status = 'Evaluando las 3,262,623 combinaciones...';
      });

      port.listen((dynamic rawMessage) {
        if (!mounted || rawMessage is! Map) {
          return;
        }

        final Map<Object?, Object?> message =
            Map<Object?, Object?>.from(rawMessage);
        final Object? type = message['type'];

        if (type == 'progress') {
          final Object? rawDone = message['done'];
          final Object? rawTotal = message['total'];

          if (rawDone is int && rawTotal is int) {
            setState(() {
              _progress = rawDone / rawTotal;
              _status =
                  'Analizando ${(_progress * 100).toStringAsFixed(1)}%';
            });
          }
          return;
        }

        if (type == 'result') {
          final Object? rawItems = message['items'];
          if (rawItems is List) {
            final List<RankedCombination> ranking = rawItems
                .whereType<Map>()
                .map(
                  (Map item) => RankedCombination.fromMap(
                    Map<Object?, Object?>.from(item),
                  ),
                )
                .toList(growable: false);

            setState(() {
              _ranking = ranking;
              _running = false;
              _progress = 1;
              _status = 'Análisis terminado con ${config.modelName}.';
            });
          }
          port.close();
          return;
        }

        if (type == 'error') {
          setState(() {
            _running = false;
            _status = 'Error: ${message['message']}';
          });
          port.close();
        }
      });

      _isolate = await Isolate.spawn<RankingRequest>(
        rankingWorker,
        RankingRequest(
          history: _history,
          latest: latest,
          topN: _topN,
          replyPort: port.sendPort,
          config: config,
        ),
      );
    } on FormatException catch (error) {
      _showMessage(error.message);
    } catch (error) {
      _showMessage('No se pudo iniciar el análisis: $error');
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _saveModelVersion(ModelConfig config) async {
    await _configRepository.saveVersion(config);
    final List<ModelConfig> history =
        await _configRepository.loadHistory();
    if (!mounted) return;
    setState(() {
      _config = config;
      _modelHistory = history;
      _ranking = <RankedCombination>[];
      _status =
          'Modelo PIT v${config.modelVersion} activado. Genera un nuevo ranking.';
    });
  }

  Future<void> _restoreModelVersion(ModelConfig config) async {
    await _configRepository.restore(config);
    final ModelConfig active = await _configRepository.load();
    final List<ModelConfig> history =
        await _configRepository.loadHistory();
    if (!mounted) return;
    setState(() {
      _config = active;
      _modelHistory = history;
      _ranking = <RankedCombination>[];
      _status = 'Modelo PIT v${active.modelVersion} restaurado.';
    });
  }

  Future<void> _resetModelConfiguration() async {
    await _configRepository.reset();
    final ModelConfig factory =
        await _configRepository.loadFactoryDefault();
    if (!mounted) return;
    setState(() {
      _config = factory;
      _ranking = <RankedCombination>[];
      _status = 'Configuración de fábrica activada.';
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final ModelConfig config = _config ??
        const ModelConfig(
          modelName: 'Modelo Oficial PIT',
          modelVersion: '1.0.0',
          engineName: 'Motor Fortuna',
          engineVersion: '5.4.0',
          rules: <RuleConfig>[],
          disclaimer: '',
        );

    final List<Widget> pages = <Widget>[
      _buildDashboard(config),
      PitMetricsScreen(
        model: config,
        modelHistory: _modelHistory,
        drawHistory: _history,
        ranking: _ranking,
      ),
      PitAuditScreen(
        model: config,
        drawHistory: _history,
        ranking: _ranking,
      ),
      PitSimulatorScreen(
        model: config,
        modelHistory: _modelHistory,
        drawHistory: _history,
        ranking: _ranking,
        onApply: _saveModelVersion,
      ),
      _buildStatistics(),
      _buildHistory(),
      LaboratoryScreen(history: _history),
      BacktestingScreen(history: _history),
      ResearchCenterScreen(config: config),
      ModelSettingsScreen(
        config: config,
        history: _modelHistory,
        onSave: _saveModelVersion,
        onRestore: _restoreModelVersion,
        onReset: _resetModelConfiguration,
      ),
      ModelComparisonScreen(
        activeModel: config,
        history: _modelHistory,
      ),
      AthenaScreen(
        model: config,
        modelHistory: _modelHistory,
        drawHistory: _history,
        ranking: _ranking,
      ),
      ProfessionalReportScreen(
        model: config,
        historyCount: _history.length,
        ranking: _ranking,
      ),
      _buildAbout(config),
    ];

    return Scaffold(
      body: SafeArea(
        child: Row(
          children: <Widget>[
            _buildSidebar(),
            const VerticalDivider(width: 1),
            Expanded(
              child: IndexedStack(
                index: _selectedIndex,
                children: pages,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSidebar() {
    final bool extended = MediaQuery.sizeOf(context).width > 1020;

    return SizedBox(
      width: extended ? 230 : 90,
      child: Column(
        children: <Widget>[
          const Padding(
            padding: EdgeInsets.fromLTRB(10, 18, 10, 8),
            child: _Brand(),
          ),
          Expanded(
            child: NavigationRail(
              extended: extended,
              selectedIndex: _selectedIndex,
              onDestinationSelected: (int index) {
                setState(() => _selectedIndex = index);
              },
              destinations: const <NavigationRailDestination>[
                NavigationRailDestination(
                  icon: Icon(Icons.dashboard_outlined),
                  selectedIcon: Icon(Icons.dashboard),
                  label: Text('Dashboard'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.monitor_heart_outlined),
                  selectedIcon: Icon(Icons.monitor_heart),
                  label: Text('Métricas PIT'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.fact_check_outlined),
                  selectedIcon: Icon(Icons.fact_check),
                  label: Text('Auditor PIT'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.tune_outlined),
                  selectedIcon: Icon(Icons.tune),
                  label: Text('Simulador PIT'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.bar_chart_outlined),
                  selectedIcon: Icon(Icons.bar_chart),
                  label: Text('Estadísticas'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.history_outlined),
                  selectedIcon: Icon(Icons.history),
                  label: Text('Histórico'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.science_outlined),
                  selectedIcon: Icon(Icons.science),
                  label: Text('Laboratorio'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.analytics_outlined),
                  selectedIcon: Icon(Icons.analytics),
                  label: Text('Backtesting'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.rule_folder_outlined),
                  selectedIcon: Icon(Icons.rule_folder),
                  label: Text('Centro PIT'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.tune_outlined),
                  selectedIcon: Icon(Icons.tune),
                  label: Text('Configuración'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.compare_arrows_outlined),
                  selectedIcon: Icon(Icons.compare_arrows),
                  label: Text('Comparador'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.psychology_alt_outlined),
                  selectedIcon: Icon(Icons.psychology_alt),
                  label: Text('ATHENA'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.picture_as_pdf_outlined),
                  selectedIcon: Icon(Icons.picture_as_pdf),
                  label: Text('Reportes'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.info_outline),
                  selectedIcon: Icon(Icons.info),
                  label: Text('Acerca de'),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Image.asset(
              'assets/images/pit_powered_by.png',
              height: extended ? 52 : 34,
              fit: BoxFit.contain,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboard(ModelConfig config) {
    final PitMetrics metrics = const PitMetricsEngine().calculate(
      model: config,
      modelHistory: _modelHistory,
      drawHistory: _history,
      ranking: _ranking,
    );
    final PitAuditReport audit = const PitAuditEngine().audit(
      model: config,
      drawHistory: _history,
      ranking: _ranking,
    );

    final RankedCombination? leader =
        _ranking.isEmpty ? null : _ranking.first;
    final Color healthColor = metrics.overallHealth >= 80
        ? Colors.greenAccent
        : metrics.overallHealth >= 60
            ? Colors.amberAccent
            : Colors.orangeAccent;

    return ListView(
      padding: const EdgeInsets.all(24),
      children: <Widget>[
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: <Color>[
                Color(0xFF24132E),
                Color(0xFF120B18),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: gold.withValues(alpha: 0.28),
            ),
          ),
          child: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              final bool wide = constraints.maxWidth >= 780;
              final Widget identity = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Text(
                    'CENTRO EJECUTIVO PIT',
                    style: TextStyle(
                      color: gold,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.4,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Oráculo Diosa Fortuna Professional',
                    style:
                        Theme.of(context).textTheme.headlineMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    '${config.engineName} v${config.engineVersion} · '
                    '${config.modelName} v${config.modelVersion}',
                    style: const TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Icon(
                        Icons.circle,
                        color: healthColor,
                        size: 11,
                      ),
                      const SizedBox(width: 7),
                      Text(
                        metrics.healthLabel,
                        style: TextStyle(
                          color: healthColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              );

              final Widget health = Container(
                width: 220,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.20),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: <Widget>[
                    SizedBox(
                      width: 76,
                      height: 76,
                      child: Stack(
                        fit: StackFit.expand,
                        children: <Widget>[
                          CircularProgressIndicator(
                            value: metrics.overallHealth / 100,
                            strokeWidth: 8,
                            color: healthColor,
                            backgroundColor: const Color(0xFF382342),
                          ),
                          Center(
                            child: Text(
                              metrics.overallHealth.toStringAsFixed(0),
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
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            'SALUD PIT',
                            style: TextStyle(
                              color: Colors.white60,
                              fontSize: 11,
                              letterSpacing: 0.8,
                            ),
                          ),
                          SizedBox(height: 5),
                          Text(
                            'Índice metodológico',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );

              if (wide) {
                return Row(
                  children: <Widget>[
                    Expanded(child: identity),
                    const SizedBox(width: 20),
                    health,
                  ],
                );
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  identity,
                  const SizedBox(height: 18),
                  health,
                ],
              );
            },
          ),
        ),
        const SizedBox(height: 18),
        Wrap(
          spacing: 14,
          runSpacing: 14,
          children: <Widget>[
            _executiveKpi(
              icon: Icons.monitor_heart_outlined,
              title: 'Salud del modelo',
              value: metrics.overallHealth.toStringAsFixed(1),
              caption: metrics.healthLabel,
              accent: healthColor,
              onTap: () => setState(() => _selectedIndex = 1),
            ),
            _executiveKpi(
              icon: Icons.fact_check_outlined,
              title: 'Auditor PIT',
              value: '${audit.findings.length}',
              caption:
                  '${audit.criticalCount} críticas · ${audit.warningCount} avisos',
              accent: audit.criticalCount > 0
                  ? Colors.redAccent
                  : Colors.amberAccent,
              onTap: () => setState(() => _selectedIndex = 2),
            ),
            _executiveKpi(
              icon: Icons.workspace_premium_outlined,
              title: 'Modelo activo',
              value: config.modelVersion,
              caption: '${config.activeRuleCount} reglas activas',
              accent: gold,
              onTap: () => setState(() => _selectedIndex = 9),
            ),
            _executiveKpi(
              icon: Icons.storage_outlined,
              title: 'Histórico',
              value: '${_history.length}',
              caption: 'sorteos disponibles',
              accent: Colors.lightBlueAccent,
              onTap: () => setState(() => _selectedIndex = 5),
            ),
            _executiveKpi(
              icon: Icons.emoji_events_outlined,
              title: 'Ranking actual',
              value: leader == null ? '—' : leader.pitIndex.toStringAsFixed(1),
              caption: leader == null
                  ? 'pendiente de generación'
                  : 'Índice PIT del líder',
              accent: Colors.greenAccent,
              onTap: leader == null ? null : () {},
            ),
          ],
        ),
        const SizedBox(height: 18),
        LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final bool wide = constraints.maxWidth >= 900;
            final Widget analysis = Card(
              color: panel,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Row(
                      children: <Widget>[
                        Icon(Icons.insights_outlined, color: gold),
                        SizedBox(width: 9),
                        Text(
                          'DIAGNÓSTICO EJECUTIVO',
                          style: TextStyle(
                            color: gold,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    _dashboardStatusLine(
                      icon: Icons.shield_outlined,
                      label: 'Robustez de pesos',
                      value:
                          '${metrics.weightRobustness.toStringAsFixed(1)}/100',
                    ),
                    _dashboardStatusLine(
                      icon: Icons.verified_outlined,
                      label: 'Evidencia',
                      value: '${metrics.evidence.toStringAsFixed(1)}/100',
                    ),
                    _dashboardStatusLine(
                      icon: Icons.balance_outlined,
                      label: 'Balance del Score',
                      value:
                          '${metrics.scoreBalance.toStringAsFixed(1)}/100',
                    ),
                    _dashboardStatusLine(
                      icon: Icons.rule_outlined,
                      label: 'Cobertura',
                      value: '${metrics.coverage.toStringAsFixed(1)}%',
                    ),
                    const Divider(height: 26),
                    if (audit.findings.isEmpty)
                      const Text(
                        'No se detectaron observaciones metodológicas.',
                        style: TextStyle(color: Colors.greenAccent),
                      )
                    else
                      ...audit.findings.take(3).map(
                            (PitAuditFinding finding) => Padding(
                              padding: const EdgeInsets.only(bottom: 9),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Icon(
                                    finding.severity ==
                                            PitAuditSeverity.critical
                                        ? Icons.error_outline
                                        : finding.severity ==
                                                PitAuditSeverity.warning
                                            ? Icons.warning_amber_outlined
                                            : Icons.info_outline,
                                    size: 18,
                                    color: finding.severity ==
                                            PitAuditSeverity.critical
                                        ? Colors.redAccent
                                        : finding.severity ==
                                                PitAuditSeverity.warning
                                            ? Colors.amberAccent
                                            : Colors.lightBlueAccent,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      finding.title,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: () =>
                          setState(() => _selectedIndex = 2),
                      icon: const Icon(Icons.open_in_new),
                      label: const Text('Abrir Auditor PIT'),
                    ),
                  ],
                ),
              ),
            );

            final Widget quick = Card(
              color: panel,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Text(
                      'ACCESOS RÁPIDOS',
                      style: TextStyle(
                        color: gold,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 14),
                    _quickAction(
                      icon: Icons.psychology_alt_outlined,
                      title: 'Consultar ATHENA',
                      subtitle: 'Analiza el modelo y el ranking',
                      index: 11,
                    ),
                    _quickAction(
                      icon: Icons.tune_outlined,
                      title: 'Abrir Simulador PIT',
                      subtitle: 'Prueba cambios sin riesgo',
                      index: 3,
                    ),
                    _quickAction(
                      icon: Icons.picture_as_pdf_outlined,
                      title: 'Generar reporte',
                      subtitle: 'Vista previa y PDF ejecutivo',
                      index: 12,
                    ),
                    _quickAction(
                      icon: Icons.compare_arrows_outlined,
                      title: 'Comparar modelos',
                      subtitle: 'Revisa versiones y pesos',
                      index: 10,
                    ),
                  ],
                ),
              ),
            );

            if (wide) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(flex: 3, child: analysis),
                  const SizedBox(width: 16),
                  Expanded(flex: 2, child: quick),
                ],
              );
            }

            return Column(
              children: <Widget>[
                analysis,
                const SizedBox(height: 16),
                quick,
              ],
            );
          },
        ),
        const SizedBox(height: 18),
        LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final bool wide = constraints.maxWidth >= 850;
            if (wide) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(flex: 3, child: _buildDrawCard()),
                  const SizedBox(width: 16),
                  Expanded(flex: 2, child: _buildGenerateCard()),
                ],
              );
            }
            return Column(
              children: <Widget>[
                _buildDrawCard(),
                const SizedBox(height: 16),
                _buildGenerateCard(),
              ],
            );
          },
        ),
        const SizedBox(height: 18),
        Card(
          color: panel,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: _ranking.isEmpty
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      const Text(
                        'RANKING',
                        style: TextStyle(
                          color: gold,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(config.disclaimer),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      const Text(
                        'ÚLTIMO RANKING',
                        style: TextStyle(
                          color: gold,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      _RankingTable(
                        ranking: _ranking,
                        onInspect: _showCombinationExplanation,
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  Widget _executiveKpi({
    required IconData icon,
    required String title,
    required String value,
    required String caption,
    required Color accent,
    VoidCallback? onTap,
  }) {
    return SizedBox(
      width: 230,
      child: Card(
        color: panel,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(17),
            child: Row(
              children: <Widget>[
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Icon(icon, color: accent),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white60,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        value,
                        style: TextStyle(
                          color: accent,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        caption,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _dashboardStatusLine({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 11),
      child: Row(
        children: <Widget>[
          Icon(icon, color: gold, size: 19),
          const SizedBox(width: 9),
          Expanded(child: Text(label)),
          Text(
            value,
            style: const TextStyle(
              color: gold,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _quickAction({
    required IconData icon,
    required String title,
    required String subtitle,
    required int index,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 2,
        ),
        tileColor: const Color(0xFF24142C),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        leading: Icon(icon, color: gold),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => setState(() => _selectedIndex = index),
      ),
    );
  }

  Widget _buildDrawCard() {
    return Card(
      color: panel,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Text(
              'ÚLTIMO SORTEO · MELATE RETRO',
              style: TextStyle(
                color: gold,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: List<Widget>.generate(
                6,
                (int index) => SizedBox(
                  width: 74,
                  child: TextField(
                    controller: _controllers[index],
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 20),
                    decoration: InputDecoration(
                      labelText: 'R${index + 1}',
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: _progress,
              color: gold,
              backgroundColor: const Color(0xFF2A103A),
            ),
            const SizedBox(height: 8),
            Text(_status),
          ],
        ),
      ),
    );
  }

  Widget _buildGenerateCard() {
    return Card(
      color: panel,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            const Text(
              'GENERAR COMBINACIONES',
              style: TextStyle(
                color: gold,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 14),
            const Text('Cantidad de resultados en el ranking'),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <int>[10, 20, 50, 100]
                  .map(
                    (int value) => ChoiceChip(
                      label: Text('$value'),
                      selected: _topN == value,
                      onSelected: _running
                          ? null
                          : (_) => setState(() => _topN = value),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: _running ? null : _generate,
              icon: const Icon(Icons.auto_awesome),
              label: Text('GENERAR TOP $_topN'),
              style: FilledButton.styleFrom(
                backgroundColor: gold,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }



  void _showCombinationExplanation(RankedCombination item) {
    showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Score Breakdown'),
          content: SizedBox(
            width: 600,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    item.label,
                    style: const TextStyle(
                      color: gold,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 22,
                    runSpacing: 8,
                    children: <Widget>[
                      Text('Puntaje: ${item.score.toStringAsFixed(3)}'),
                      Text('Índice PIT: ${item.pitIndex.toStringAsFixed(1)}'),
                      Text(
                        'Suma ${item.sum} · ${item.evens}P / '
                        '${item.odds}I · ${item.repeated} repetidos',
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  ...item.breakdown.rules.map((rule) {
                    final bool positive = rule.weightedValue >= 0;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Row(
                            children: <Widget>[
                              Icon(
                                positive
                                    ? Icons.add_circle_outline
                                    : Icons.remove_circle_outline,
                                color: positive
                                    ? Colors.greenAccent
                                    : Colors.orangeAccent,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(child: Text(rule.label)),
                              Text(
                                rule.weightedValue.toStringAsFixed(3),
                                style: TextStyle(
                                  color: positive
                                      ? Colors.greenAccent
                                      : Colors.orangeAccent,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          LinearProgressIndicator(
                            value: rule.influence,
                            color: positive
                                ? Colors.greenAccent
                                : Colors.orangeAccent,
                            backgroundColor: const Color(0xFF2A103A),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '${(rule.influence * 100).toStringAsFixed(1)}% '
                            'de influencia relativa',
                            style: const TextStyle(
                              color: Colors.white60,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: 4),
                  const Text(
                    'El Índice PIT mide qué tan distribuido está el puntaje '
                    'entre las reglas activas. No representa probabilidad de ganar.',
                    style: TextStyle(color: Colors.white60, fontSize: 12),
                  ),
                ],
              ),
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

  Widget _buildStatistics() {
    final List<int> counts = List<int>.filled(40, 0);
    for (final List<int> draw in _history) {
      for (final int number in draw) {
        counts[number]++;
      }
    }

    final List<MapEntry<int, int>> ranked = List<MapEntry<int, int>>.generate(
      39,
      (int index) => MapEntry<int, int>(index + 1, counts[index + 1]),
    )..sort(
        (MapEntry<int, int> a, MapEntry<int, int> b) =>
            b.value.compareTo(a.value),
      );

    return ListView(
      padding: const EdgeInsets.all(24),
      children: <Widget>[
        Text('Estadísticas', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 18),
        Card(
          color: panel,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: ranked
                  .take(20)
                  .map(
                    (MapEntry<int, int> item) => ListTile(
                      leading: CircleAvatar(
                        backgroundColor: purple,
                        child: Text('${item.key}'),
                      ),
                      title: LinearProgressIndicator(
                        value: item.value / ranked.first.value,
                        color: gold,
                        backgroundColor: const Color(0xFF2A103A),
                      ),
                      trailing: Text('${item.value}'),
                    ),
                  )
                  .toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHistory() {
    final List<List<int>> recent = _history.reversed.take(50).toList();

    return ListView(
      padding: const EdgeInsets.all(24),
      children: <Widget>[
        Text('Histórico', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 18),
        Card(
          color: panel,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columns: const <DataColumn>[
                DataColumn(label: Text('#')),
                DataColumn(label: Text('Combinación')),
                DataColumn(label: Text('Suma')),
              ],
              rows: List<DataRow>.generate(
                recent.length,
                (int index) {
                  final List<int> draw = recent[index];
                  return DataRow(
                    cells: <DataCell>[
                      DataCell(Text('${_history.length - index}')),
                      DataCell(Text(draw.join(' - '))),
                      DataCell(Text('${draw.reduce((int a, int b) => a + b)}')),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAbout(ModelConfig config) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: <Widget>[
        Center(
          child: Image.asset(
            'assets/images/oraculo_logo.png',
            height: 190,
          ),
        ),
        const SizedBox(height: 14),
        const Center(
          child: Text(
            'ORÁCULO DIOSA FORTUNA PROFESSIONAL',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: gold,
              fontSize: 24,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Center(
          child: Text(
            '${config.engineName} v${config.engineVersion}',
            style: const TextStyle(color: Colors.white60),
          ),
        ),
        const SizedBox(height: 20),
        const Card(
          color: panel,
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Text(
              'Plataforma de investigación estadística para Melate Retro. '
              'No garantiza premios ni modifica las probabilidades '
              'matemáticas de una combinación en un sorteo justo.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
        const SizedBox(height: 20),
        Center(
          child: Image.asset(
            'assets/images/pit_powered_by.png',
            height: 90,
          ),
        ),
      ],
    );
  }
}

class _Brand extends StatelessWidget {
  const _Brand();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Image.asset(
          'assets/images/oraculo_logo.png',
          height: 80,
          width: 96,
          fit: BoxFit.contain,
        ),
        const SizedBox(height: 4),
        const Text(
          'Diosa Fortuna',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Color(0xFFE8B85A),
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

class _RankingTable extends StatelessWidget {
  const _RankingTable({
    required this.ranking,
    required this.onInspect,
  });

  final List<RankedCombination> ranking;
  final ValueChanged<RankedCombination> onInspect;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: const <DataColumn>[
          DataColumn(label: Text('#')),
          DataColumn(label: Text('Combinación')),
          DataColumn(label: Text('Suma')),
          DataColumn(label: Text('Paridad')),
          DataColumn(label: Text('Repite')),
          DataColumn(label: Text('Puntaje')),
          DataColumn(label: Text('Índice PIT')),
          DataColumn(label: Text('Explicación')),
        ],
        rows: List<DataRow>.generate(
          ranking.length,
          (int index) {
            final RankedCombination item = ranking[index];
            return DataRow(
              cells: <DataCell>[
                DataCell(Text('${index + 1}')),
                DataCell(
                  Text(
                    item.label,
                    style: const TextStyle(
                      color: Color(0xFFE8B85A),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                DataCell(Text('${item.sum}')),
                DataCell(Text('${item.evens}P / ${item.odds}I')),
                DataCell(Text('${item.repeated}')),
                DataCell(Text(item.score.toStringAsFixed(3))),
                DataCell(Text(item.pitIndex.toStringAsFixed(1))),
                DataCell(
                  IconButton(
                    tooltip: 'Ver contribución de reglas',
                    onPressed: () => onInspect(item),
                    icon: const Icon(Icons.analytics_outlined),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
