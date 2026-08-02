import 'package:csv/csv.dart';
import 'package:flutter/services.dart';

class HistoryRepository {
  const HistoryRepository();

  Future<List<List<int>>> load() async {
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
      if (row.length < 6) {
        continue;
      }

      final List<int> draw = row
          .take(6)
          .map((dynamic value) => int.parse(value.toString().trim()))
          .toList()
        ..sort();

      if (draw.length == 6 && draw.toSet().length == 6) {
        history.add(draw);
      }
    }

    if (history.length < 20) {
      throw StateError('El histórico no contiene suficientes sorteos.');
    }

    return history;
  }
}
