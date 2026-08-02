import 'dart:isolate';
import 'package:flutter/material.dart';
import '../../core/models/model_config.dart';
import '../../core/models/ranked_combination.dart';
import '../../core/services/history_repository.dart';
import '../../core/services/model_config_repository.dart';
import '../../core/services/ranking_worker.dart';
import '../laboratory/laboratory_screen.dart';
import '../research_center/research_center_screen.dart';
import '../backtesting/backtesting_screen.dart';

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
      ]);
      final List<List<int>> history = loaded[0] as List<List<int>>;
      final ModelConfig config = loaded[1] as ModelConfig;
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
          engineName: 'Motor Fortuna',
          engineVersion: '3.9.0',
          rules: <RuleConfig>[],
          disclaimer: '',
        );

    final List<Widget> pages = <Widget>[
      _buildDashboard(config),
      _buildStatistics(),
      _buildHistory(),
      LaboratoryScreen(history: _history),
      BacktestingScreen(history: _history),
      ResearchCenterScreen(config: config),
      _buildSettings(config),
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
    final int activeRules =
        config.rules.where((RuleConfig rule) => rule.enabled).length;

    return ListView(
      padding: const EdgeInsets.all(24),
      children: <Widget>[
        Text(
          'Oráculo Diosa Fortuna Professional',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: gold,
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 6),
        Text(
          '${config.engineName} v${config.engineVersion} · ${config.modelName}',
        ),
        const SizedBox(height: 20),
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
            child: Wrap(
              spacing: 36,
              runSpacing: 18,
              children: <Widget>[
                _metric(
                  icon: Icons.storage_outlined,
                  title: 'Histórico',
                  value: '${_history.length}',
                  caption: 'sorteos cargados',
                ),
                _metric(
                  icon: Icons.rule_outlined,
                  title: 'Reglas activas',
                  value: '$activeRules',
                  caption: 'configurables',
                ),
                _metric(
                  icon: Icons.check_circle_outline,
                  title: 'Estado',
                  value: 'LISTO',
                  caption: config.engineName,
                ),
                _metric(
                  icon: Icons.memory_outlined,
                  title: 'Modelo',
                  value: config.engineVersion,
                  caption: config.modelName,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 18),
        Card(
          color: panel,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: _ranking.isEmpty
                ? Text(config.disclaimer)
                : _RankingTable(
                    ranking: _ranking,
                    onInspect: _showCombinationExplanation,
                  ),
          ),
        ),
      ],
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

  Widget _metric({
    required IconData icon,
    required String title,
    required String value,
    required String caption,
  }) {
    return SizedBox(
      width: 190,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(icon, color: gold, size: 28),
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
    );
  }

  void _showCombinationExplanation(RankedCombination item) {
    final List<MapEntry<String, double>> entries =
        item.contributions.entries.toList()
          ..sort(
            (MapEntry<String, double> a, MapEntry<String, double> b) =>
                b.value.abs().compareTo(a.value.abs()),
          );

    final double magnitude = entries.fold<double>(
      0,
      (double total, MapEntry<String, double> entry) =>
          total + entry.value.abs(),
    );

    showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Explicación del ranking'),
          content: SizedBox(
            width: 560,
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
                  Text(
                    'Puntaje total: ${item.score.toStringAsFixed(3)}',
                  ),
                  Text(
                    'Suma ${item.sum} · '
                    '${item.evens} pares / ${item.odds} impares · '
                    '${item.repeated} repetidos',
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Contribución de las reglas',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  ...entries.map((MapEntry<String, double> entry) {
                    final double share = magnitude == 0
                        ? 0
                        : entry.value.abs() / magnitude;
                    final bool positive = entry.value >= 0;

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
                              Expanded(child: Text(entry.key)),
                              Text(
                                entry.value.toStringAsFixed(3),
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
                            value: share,
                            color: positive
                                ? Colors.greenAccent
                                : Colors.orangeAccent,
                            backgroundColor: const Color(0xFF2A103A),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '${(share * 100).toStringAsFixed(1)}% '
                            'de la magnitud total del puntaje',
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
                    'Esta explicación describe cómo el modelo construyó '
                    'el puntaje. No representa una probabilidad de ganar.',
                    style: TextStyle(
                      color: Colors.white60,
                      fontSize: 12,
                    ),
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

  Widget _buildSettings(ModelConfig config) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: <Widget>[
        Text(
          'Configuración del modelo',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 8),
        Text(config.disclaimer),
        const SizedBox(height: 18),
        ...config.rules.map(
          (RuleConfig rule) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Card(
              color: panel,
              child: ListTile(
                leading: Icon(
                  rule.enabled ? Icons.check_circle : Icons.cancel_outlined,
                  color: rule.enabled ? Colors.greenAccent : Colors.white38,
                ),
                title: Text(rule.label),
                subtitle: Text('Clave técnica: ${rule.key}'),
                trailing: Text(
                  'Peso ${rule.weight.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: gold,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Los valores se leen desde assets/config/model_config.json. '
          'El editor visual de pesos se incorporará en la siguiente versión.',
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
