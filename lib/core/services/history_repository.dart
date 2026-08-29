import 'package:csv/csv.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HistoryRepository {
  const HistoryRepository();

  static const String _savedDrawsKey = 'historico_retro_saved_draws_v1';

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

      // IMPORTANTE: NO eliminar combinaciones repetidas del histórico.
      // En un sorteo real una combinación puede volver a ocurrir años después.
      if (_isValidDraw(draw)) {
        history.add(draw);
      }
    }

    final SharedPreferences preferences =
        await SharedPreferences.getInstance();
    final List<String> saved =
        preferences.getStringList(_savedDrawsKey) ?? <String>[];

    for (final String encoded in saved) {
      final List<int>? draw = _decodeDraw(encoded);
      if (draw != null) {
        history.add(draw);
      }
    }

    if (history.length < 20) {
      throw StateError('El histórico no contiene suficientes sorteos.');
    }

    return history;
  }

  Future<bool> addDraw(List<int> values) async {
    final List<int> draw = List<int>.from(values)..sort();

    if (!_isValidDraw(draw)) {
      throw ArgumentError(
        'El sorteo debe contener seis números distintos entre 1 y 39.',
      );
    }

    final SharedPreferences preferences =
        await SharedPreferences.getInstance();
    final List<String> saved = List<String>.from(
      preferences.getStringList(_savedDrawsKey) ?? <String>[],
    );

    // Evita guardar dos veces seguidas el mismo resultado por volver a
    // pulsar GENERAR con los mismos números, sin borrar repeticiones
    // históricas legítimas.
    if (saved.isNotEmpty) {
      final List<int>? lastSaved = _decodeDraw(saved.last);
      if (lastSaved != null && _sameDraw(lastSaved, draw)) {
        return false;
      }
    }

    // Si aún no hay sorteos locales guardados, evita duplicar el último
    // sorteo que ya viene incluido en el CSV base.
    if (saved.isEmpty) {
      final List<List<int>> baseHistory = await _loadBaseHistory();
      if (baseHistory.isNotEmpty && _sameDraw(baseHistory.last, draw)) {
        return false;
      }
    }

    saved.add(draw.join(','));
    await preferences.setStringList(_savedDrawsKey, saved);
    return true;
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
      if (row.length < 6) {
        continue;
      }

      final List<int> draw = row
          .take(6)
          .map((dynamic value) => int.parse(value.toString().trim()))
          .toList()
        ..sort();

      if (_isValidDraw(draw)) {
        history.add(draw);
      }
    }
    return history;
  }

  bool _isValidDraw(List<int> draw) {
    return draw.length == 6 &&
        draw.toSet().length == 6 &&
        draw.every((int value) => value >= 1 && value <= 39);
  }

  bool _sameDraw(List<int> a, List<int> b) {
    if (a.length != b.length) {
      return false;
    }
    for (int index = 0; index < a.length; index++) {
      if (a[index] != b[index]) {
        return false;
      }
    }
    return true;
  }

  List<int>? _decodeDraw(String encoded) {
    try {
      final List<int> draw = encoded
          .split(',')
          .map((String value) => int.parse(value.trim()))
          .toList()
        ..sort();

      return _isValidDraw(draw) ? draw : null;
    } catch (_) {
      return null;
    }
  }
}
