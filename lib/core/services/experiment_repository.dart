import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/laboratory_experiment.dart';

class ExperimentRepository {
  const ExperimentRepository();

  static const String _storageKey = 'pit_laboratory_experiments_v1';

  Future<List<ManagedExperiment>> load() async {
    final SharedPreferences preferences =
        await SharedPreferences.getInstance();
    final String? raw = preferences.getString(_storageKey);

    if (raw == null || raw.trim().isEmpty) {
      return <ManagedExperiment>[];
    }

    final Object? decoded = jsonDecode(raw);
    if (decoded is! List) {
      throw const FormatException(
        'El archivo local de experimentos no es válido.',
      );
    }

    return decoded
        .whereType<Map>()
        .map(
          (Map item) => ManagedExperiment.fromMap(
            Map<String, dynamic>.from(item),
          ),
        )
        .toList(growable: true);
  }

  Future<void> save(List<ManagedExperiment> experiments) async {
    final SharedPreferences preferences =
        await SharedPreferences.getInstance();
    final String raw = jsonEncode(
      experiments
          .map((ManagedExperiment experiment) => experiment.toMap())
          .toList(growable: false),
    );

    final bool saved = await preferences.setString(_storageKey, raw);
    if (!saved) {
      throw StateError('No se pudieron guardar los experimentos.');
    }
  }

  Future<void> clear() async {
    final SharedPreferences preferences =
        await SharedPreferences.getInstance();
    await preferences.remove(_storageKey);
  }
}
