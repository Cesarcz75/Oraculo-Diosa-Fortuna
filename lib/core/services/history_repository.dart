import 'package:csv/csv.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class OfficialRetroDraw {
  const OfficialRetroDraw({
    required this.contestNumber,
    required this.drawDate,
    required this.numbers,
  });

  final int contestNumber;
  final DateTime drawDate;
  final List<int> numbers;
}

class HistoryRepository {
  const HistoryRepository();

  // El CSV incluido contiene los concursos históricos hasta el 1661.
  // Sus primeras cuatro ediciones no están en el archivo, por lo que el
  // número de concurso no coincide con la cantidad física de filas.
  static const int baseLastContestNumber = 1661;

  SupabaseClient get _client => Supabase.instance.client;

  Future<List<List<int>>> load() async {
    final List<List<int>> history = await _loadBaseHistory();
    final List<OfficialRetroDraw> officialDraws = await loadOfficialDraws();

    for (final OfficialRetroDraw draw in officialDraws) {
      if (_isValidDraw(draw.numbers)) history.add(draw.numbers);
    }

    if (history.length < 20) {
      throw StateError('El histórico no contiene suficientes sorteos.');
    }
    return history;
  }

  Future<List<OfficialRetroDraw>> loadOfficialDraws() async {
    final List<dynamic> remote = await _client
        .from('retro_draws')
        .select('contest_number,draw_date,n1,n2,n3,n4,n5,n6')
        .gt('contest_number', baseLastContestNumber)
        .order('contest_number', ascending: true);

    final List<OfficialRetroDraw> draws = <OfficialRetroDraw>[];
    for (final dynamic raw in remote) {
      final Map<String, dynamic> row = Map<String, dynamic>.from(raw as Map);
      final List<int> numbers = <int>[
        (row['n1'] as num).toInt(),
        (row['n2'] as num).toInt(),
        (row['n3'] as num).toInt(),
        (row['n4'] as num).toInt(),
        (row['n5'] as num).toInt(),
        (row['n6'] as num).toInt(),
      ];
      if (_isValidDraw(numbers)) {
        draws.add(
          OfficialRetroDraw(
            contestNumber: (row['contest_number'] as num).toInt(),
            drawDate: DateTime.parse(row['draw_date'] as String),
            numbers: numbers,
          ),
        );
      }
    }
    return draws;
  }

  Future<bool> isCurrentUserAdmin() async {
    final String? userId = _client.auth.currentUser?.id;
    if (userId == null) return false;
    final Map<String, dynamic>? profile = await _client
        .from('profiles')
        .select('role,active')
        .eq('id', userId)
        .maybeSingle();
    return profile?['role'] == 'admin' && profile?['active'] == true;
  }

  Future<void> addOfficialDraw({
    required int contestNumber,
    required DateTime drawDate,
    required List<int> values,
  }) async {
    final List<int> draw = List<int>.from(values)..sort();
    if (contestNumber <= 0) {
      throw ArgumentError('El número de concurso debe ser mayor que cero.');
    }
    if (!_isValidDraw(draw)) {
      throw ArgumentError(
        'El sorteo debe contener seis números distintos entre 1 y 39.',
      );
    }
    await _client.rpc(
      'add_retro_official_draw',
      params: <String, dynamic>{
        'p_contest_number': contestNumber,
        'p_draw_date': drawDate.toIso8601String().split('T').first,
        'p_numbers': draw,
      },
    );
  }

  Future<List<List<int>>> _loadBaseHistory() async {
    final String raw = await rootBundle.loadString(
      'assets/data/historico_retro.csv',
    );
    final List<List<dynamic>> rows = const CsvToListConverter(
      shouldParseNumbers: false,
      eol: '\n',
    ).convert(raw);
    final List<List<int>> history = <List<int>>[];
    for (int index = 1; index < rows.length; index++) {
      final List<dynamic> row = rows[index];
      if (row.length < 6) continue;
      final List<int> draw = row
          .take(6)
          .map((dynamic value) => int.parse(value.toString().trim()))
          .toList()
        ..sort();
      if (_isValidDraw(draw)) history.add(draw);
    }
    return history;
  }

  bool _isValidDraw(List<int> draw) {
    return draw.length == 6 &&
        draw.toSet().length == 6 &&
        draw.every((int value) => value >= 1 && value <= 39);
  }
}
