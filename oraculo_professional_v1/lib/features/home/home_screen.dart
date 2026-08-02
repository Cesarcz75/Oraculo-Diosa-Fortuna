import 'dart:isolate';
import 'package:flutter/material.dart';
import '../../core/models/ranked_combination.dart';
import '../../core/services/history_repository.dart';
import '../../core/services/ranking_worker.dart';
import '../laboratory/laboratory_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final HistoryRepository _repository = const HistoryRepository();
  final List<TextEditingController> _controllers =
      List<TextEditingController>.generate(
    6,
    (_) => TextEditingController(),
  );

  List<List<int>> _history = <List<int>>[];
  List<RankedCombination> _ranking = <RankedCombination>[];
  bool _loading = true;
  bool _running = false;
  double _progress = 0;
  int _selectedIndex = 0;
  String _status = 'Cargando histórico...';
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
      final List<List<int>> history = await _repository.load();
      final List<int> last = history.last;

      for (int index = 0; index < 6; index++) {
        _controllers[index].text = last[index].toString();
      }

      setState(() {
        _history = history;
        _loading = false;
        _status = 'Histórico cargado: ${history.length} sorteos.';
      });
    } catch (error) {
      setState(() {
        _loading = false;
        _status = 'Error al cargar histórico: $error';
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

    final List<int> result = parsed.cast<int>()..sort();

    if (result.toSet().length != 6) {
      throw const FormatException('Los seis números deben ser distintos.');
    }

    return result;
  }

  Future<void> _generate() async {
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

      port.listen((dynamic message) {
        if (!mounted || message is! Map<Object?, Object?>) {
          return;
        }

        final Object? type = message['type'];

        if (type == 'progress') {
          final int done = message['done']! as int;
          final int total = message['total']! as int;
          setState(() {
            _progress = done / total;
            _status = 'Evaluadas $done de $total combinaciones.';
          });
          return;
        }

        if (type == 'result') {
          final List<Object?> rawItems = message['items']! as List<Object?>;
          final List<RankedCombination> ranking = rawItems
              .map(
                (Object? item) => RankedCombination.fromMap(
                  item! as Map<Object?, Object?>,
                ),
              )
              .toList(growable: false);

          setState(() {
            _ranking = ranking;
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

      _isolate = await Isolate.spawn<RankingRequest>(
        rankingWorker,
        RankingRequest(
          history: _history,
          latest: latest,
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

    final List<Widget> pages = <Widget>[
      _buildHome(),
      _buildStatistics(),
      _buildHistory(),
      LaboratoryScreen(history: _history),
    ];

    return Scaffold(
      body: SafeArea(
        child: Row(
          children: <Widget>[
            NavigationRail(
              extended: MediaQuery.sizeOf(context).width > 900,
              selectedIndex: _selectedIndex,
              onDestinationSelected: (int index) {
                setState(() => _selectedIndex = index);
              },
              leading: const Padding(
                padding: EdgeInsets.symmetric(vertical: 18),
                child: _Brand(),
              ),
              destinations: const <NavigationRailDestination>[
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
              ],
            ),
            const VerticalDivider(width: 1),
            Expanded(child: IndexedStack(index: _selectedIndex, children: pages)),
          ],
        ),
      ),
    );
  }

  Widget _buildHome() {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: <Widget>[
        Text(
          'Oráculo Diosa Fortuna Professional',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: const Color(0xFFE8B85A),
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 6),
        const Text('Plataforma de investigación estadística · Melate Retro'),
        const SizedBox(height: 20),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Último resultado',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: List<Widget>.generate(
                    6,
                    (int index) => SizedBox(
                      width: 82,
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
    final List<int> counts = List<int>.filled(40, 0);
    for (final List<int> draw in _history) {
      for (final int number in draw) {
        counts[number]++;
      }
    }

    final List<({int number, int count})> ranked =
        List<({int number, int count})>.generate(
      39,
      (int index) => (number: index + 1, count: counts[index + 1]),
    )..sort(
            (({int number, int count}) a, ({int number, int count}) b) =>
                b.count.compareTo(a.count),
          );

    return ListView(
      padding: const EdgeInsets.all(24),
      children: <Widget>[
        Text('Estadísticas', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 18),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: ranked
                  .take(15)
                  .map(
                    (({int number, int count}) item) => ListTile(
                      leading: CircleAvatar(child: Text('${item.number}')),
                      title: LinearProgressIndicator(
                        value: item.count / ranked.first.count,
                      ),
                      trailing: Text('${item.count}'),
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
    final List<List<int>> recent = _history.reversed.take(30).toList();

    return ListView(
      padding: const EdgeInsets.all(24),
      children: <Widget>[
        Text('Histórico', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 18),
        Card(
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
}

class _Brand extends StatelessWidget {
  const _Brand();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: <Widget>[
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
        columns: const <DataColumn>[
          DataColumn(label: Text('#')),
          DataColumn(label: Text('Combinación')),
          DataColumn(label: Text('Suma')),
          DataColumn(label: Text('Paridad')),
          DataColumn(label: Text('Repite')),
        ],
        rows: List<DataRow>.generate(
          ranking.length,
          (int index) {
            final RankedCombination item = ranking[index];
            return DataRow(
              cells: <DataCell>[
                DataCell(Text('${index + 1}')),
                DataCell(Text(item.label)),
                DataCell(Text('${item.sum}')),
                DataCell(Text('${item.evens}P / ${item.odds}I')),
                DataCell(Text('${item.repeated}')),
              ],
            );
          },
        ),
      ),
    );
  }
}
