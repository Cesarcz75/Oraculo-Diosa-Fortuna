
import 'package:csv/csv.dart';
import 'package:flutter/services.dart';

class HistoryRepository {
  Future<List<List<int>>> load() async {
    final raw = await rootBundle.loadString(
      'assets/data/historico_retro.csv',
    );
    final rows = const CsvToListConverter(
      shouldParseNumbers: false,
      eol: '\n',
    ).convert(raw);

    final history = <List<int>>[];
    for (var i = 1; i < rows.length; i++) {
      final row = rows[i];
      if (row.length < 6) continue;
      final draw = row.take(6).map((value) {
        return int.parse(value.toString().trim());
      }).toList()
        ..sort();
      if (draw.length == 6 && draw.toSet().length == 6) {
        history.add(draw);
      }
    }
    return history;
  }
}
