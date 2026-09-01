import 'package:csv/csv.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HistoryRepository {
  const HistoryRepository();

  SupabaseClient get _client => Supabase.instance.client;

  Future<List<List<int>>> load() async {
    final List<List<int>> history = await _loadBaseHistory();
    final List<dynamic> remote = await _client
        .from('retro_draws')
        .select('n1,n2,n3,n4,n5,n6')
        .order('contest_number');

    for (final dynamic raw in remote) {
      final Map<String, dynamic> row = Map<String, dynamic>.from(raw as Map);
      final List<int> draw = <int>[
        row['n1'] as int,
        row['n2'] as int,
        row['n3'] as int,
        row['n4'] as int,
        row['n5'] as int,
        row['n6'] as int,
      ];
      if (_isValidDraw(draw)) history.add(draw);
    }

    if (history.length < 20) {
      throw StateError('El histórico no contiene suficientes sorteos.');
    }
    return history;
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
