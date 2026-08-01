
import 'dart:async';
import 'dart:isolate';
import 'package:flutter/material.dart';
import '../core/history_repository.dart';
import '../core/models.dart';
import '../core/quick_backtester.dart';
import '../core/ranking_worker.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _controllers = List.generate(6, (_) => TextEditingController());
  final _repo = HistoryRepository();

  List<List<int>> _history = [];
  List<RankedCombination> _ranking = [];
  bool _loadingHistory = true;
  bool _running = false;
  bool _runningBacktest = false;
  double _progress = 0;
  int _selectedIndex = 0;
  String _status = 'Cargando histórico...';
  String _labStatus = 'Laboratorio listo.';
  ReceivePort? _rankingPort;
  Isolate? _rankingIsolate;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  @override
  void dispose() {
    _rankingPort?.close();
    _rankingIsolate?.kill(priority: Isolate.immediate);
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _loadHistory() async {
    try {
      final history = await _repo.load();
      final last = history.last;
      for (var i = 0; i < 6; i++) {
        _controllers[i].text = last[i].toString();
      }
      setState(() {
        _history = history;
        _loadingHistory = false;
        _status = 'Histórico cargado: ${history.length} sorteos.';
      });
    } catch (error) {
      setState(() {
        _loadingHistory = false;
        _status = 'Error al cargar histórico: $error';
      });
    }
  }

  List<int> _readDraw() {
    final values = _controllers.map((c) => int.tryParse(c.text)).toList();
    if (values.any((v) => v == null || v! < 1 || v > 39)) {
      throw const FormatException('Ingresa seis números entre 1 y 39.');
    }
    final draw = values.cast<int>()..sort();
    if (draw.toSet().length != 6) {
      throw const FormatException('Los seis números deben ser distintos.');
    }
    return draw;
  }

  Future<void> _generate() async {
    try {
      final latest = _readDraw();

      _rankingPort?.close();
      _rankingIsolate?.kill(priority: Isolate.immediate);
      final port = ReceivePort();
      _rankingPort = port;

      setState(() {
        _running = true;
        _progress = 0;
        _ranking = [];
        _status = 'Evaluando las 3,262,623 combinaciones...';
      });

      port.listen((dynamic message) {
        if (!mounted || message is! Map) return;
        final type = message['type'];

        if (type == 'progress') {
          final done = message['done'] as int;
          final total = message['total'] as int;
          setState(() {
            _progress = done / total;
            _status =
                'Evaluadas ${_formatInteger(done)} de ${_formatInteger(total)} combinaciones.';
          });
          return;
        }

        if (type == 'result') {
          final rawItems = message['items'] as List;
          setState(() {
            _ranking = rawItems
                .map((item) => rankedCombinationFromMap(item as Map))
                .toList();
            _running = false;
            _progress = 1;
            _status = 'Análisis terminado.';
          });
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

      _rankingIsolate = await Isolate.spawn(
        rankingWorker,
        RankingRequest(
          history: _history,
          latestDraw: latest,
          topN: 10,
          replyPort: port.sendPort,
        ),
      );
    } on FormatException catch (error) {
      _showMessage(error.message);
    } catch (error) {
      _showMessage('No se pudo iniciar el análisis: $error');
    }
  }

  Future<void> _runQuickBacktest() async {
    if (_runningBacktest) return;
    setState(() {
      _runningBacktest = true;
      _labStatus = 'Ejecutando validación temporal rápida...';
    });

    try {
      final result = await Future<QuickBacktestResult>(() {
        return const QuickBacktester().run(
          _history,
          drawsToTest: 30,
          randomCandidates: 25000,
        );
      });

      setState(() {
        _labStatus = [
          'Sorteos evaluados: ${result.drawsTested}',
          'Promedio de aciertos del modelo: '
              '${result.averageHitsModel.toStringAsFixed(3)}',
          'Promedio de una combinación aleatoria: '
              '${result.averageHitsRandom.toStringAsFixed(3)}',
          'Sorteos con 3+ aciertos (modelo): ${result.modelThreePlus}',
          'Sorteos con 3+ aciertos (azar): ${result.randomThreePlus}',
          '',
          'Esta prueba es exploratoria: usa una muestra de candidatos, no el '
              'universo completo, y no demuestra capacidad predictiva.',
        ].join('\n');
      });
    } catch (error) {
      setState(() => _labStatus = 'Error en validación: $error');
    } finally {
      setState(() => _runningBacktest = false);
    }
  }

  String _formatInteger(int value) {
    final raw = value.toString();
    final out = StringBuffer();
    for (var i = 0; i < raw.length; i++) {
      if (i > 0 && (raw.length - i) % 3 == 0) out.write(',');
      out.write(raw[i]);
    }
    return out.toString();
  }

  void _showMessage(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final destinations = const [
      NavigationRailDestination(
        icon: Icon(Icons.auto_awesome_outlined),
        selectedIcon: Icon(Icons.auto_awesome),
        label: Text('Inicio'),
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
    ];

    return Scaffold(
      body: SafeArea(
        child: Row(
          children: [
            NavigationRail(
              extended: MediaQuery.sizeOf(context).width > 900,
              selectedIndex: _selectedIndex,
              onDestinationSelected: (index) {
                setState(() => _selectedIndex = index);
              },
              leading: const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: _Brand(),
              ),
              destinations: destinations,
            ),
            const VerticalDivider(width: 1),
            Expanded(
              child: _loadingHistory
                  ? const Center(child: CircularProgressIndicator())
                  : IndexedStack(
                      index: _selectedIndex,
                      children: [
                        _buildHome(),
                        _buildStatistics(),
                        _buildHistory(),
                        _buildLab(),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHome() {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(
          'Oráculo Diosa Fortuna',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: const Color(0xFFE8B85A),
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 6),
        const Text('Motor estadístico multiplataforma · Melate Retro'),
        const SizedBox(height: 22),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Último resultado',
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: List.generate(
                    6,
                    (index) => SizedBox(
                      width: 80,
                      child: TextField(
                        controller: _controllers[index],
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        decoration: InputDecoration(
                          labelText: 'R${index + 1}',
                          border: const OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: _running ? null : _generate,
                  icon: const Icon(Icons.auto_awesome),
                  label: const Text('Generar Top 10'),
                ),
                const SizedBox(height: 14),
                LinearProgressIndicator(value: _progress),
                const SizedBox(height: 8),
                Text(_status),
              ],
            ),
          ),
        ),
        const SizedBox(height: 18),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: _ranking.isEmpty
                ? const Text('Todavía no se ha generado un ranking.')
                : _RankingTable(ranking: _ranking),
          ),
        ),
      ],
    );
  }

  Widget _buildStatistics() {
    final counts = List<int>.filled(40, 0);
    for (final draw in _history) {
      for (final n in draw) counts[n]++;
    }
    final ranked = List.generate(39, (i) => (number: i + 1, count: counts[i + 1]))
      ..sort((a, b) => b.count.compareTo(a.count));

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text('Estadísticas', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 18),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Números más frecuentes',
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 12),
                ...ranked.take(15).map(
                      (item) => ListTile(
                        leading: CircleAvatar(child: Text('${item.number}')),
                        title: LinearProgressIndicator(
                          value: item.count / ranked.first.count,
                        ),
                        trailing: Text('${item.count}'),
                      ),
                    ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHistory() {
    final recent = _history.reversed.take(30).toList();
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text('Histórico', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 18),
        Card(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columns: const [
                DataColumn(label: Text('#')),
                DataColumn(label: Text('Combinación')),
                DataColumn(label: Text('Suma')),
              ],
              rows: List.generate(recent.length, (index) {
                final draw = recent[index];
                return DataRow(
                  cells: [
                    DataCell(Text('${_history.length - index}')),
                    DataCell(Text(draw.join(' - '))),
                    DataCell(Text('${draw.reduce((a, b) => a + b)}')),
                  ],
                );
              }),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLab() {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text('Laboratorio', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 18),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'La validación temporal compara el modelo contra una '
                  'combinación aleatoria usando únicamente sorteos anteriores.',
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: _runningBacktest ? null : _runQuickBacktest,
                  icon: const Icon(Icons.science),
                  label: const Text('Ejecutar validación rápida'),
                ),
                const SizedBox(height: 18),
                if (_runningBacktest) const LinearProgressIndicator(),
                const SizedBox(height: 12),
                SelectableText(_labStatus),
              ],
            ),
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
    return const Column(
      children: [
        CircleAvatar(
          radius: 30,
          backgroundColor: Color(0xFF8F4DFF),
          child: Icon(Icons.auto_awesome, size: 30),
        ),
        SizedBox(height: 8),
        Text(
          'Diosa Fortuna',
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
  const _RankingTable({required this.ranking});

  final List<RankedCombination> ranking;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: const [
          DataColumn(label: Text('#')),
          DataColumn(label: Text('Combinación')),
          DataColumn(label: Text('Suma')),
          DataColumn(label: Text('Paridad')),
          DataColumn(label: Text('Repite')),
        ],
        rows: List.generate(ranking.length, (index) {
          final item = ranking[index];
          return DataRow(
            cells: [
              DataCell(Text('${index + 1}')),
              DataCell(Text(item.label)),
              DataCell(Text('${item.sum}')),
              DataCell(Text('${item.evens}P / ${item.odds}I')),
              DataCell(Text('${item.repeated}')),
            ],
          );
        }),
      ),
    );
  }
}
