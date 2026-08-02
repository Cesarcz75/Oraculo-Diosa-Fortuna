import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/model_config.dart';

class ModelConfigRepository {
  const ModelConfigRepository();

  static const String _activeKey = 'pit_active_model_config_v1';
  static const String _historyKey = 'pit_model_history_v1';

  Future<ModelConfig> load() async {
    final SharedPreferences preferences =
        await SharedPreferences.getInstance();
    final String? saved = preferences.getString(_activeKey);
    if (saved != null && saved.trim().isNotEmpty) {
      final Object? decoded = jsonDecode(saved);
      if (decoded is Map) {
        return ModelConfig.fromMap(Map<String, dynamic>.from(decoded));
      }
    }
    return loadFactoryDefault();
  }

  Future<ModelConfig> loadFactoryDefault() async {
    final String raw =
        await rootBundle.loadString('assets/config/model_config.json');
    final Object? decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('La configuración del modelo no es válida.');
    }
    return ModelConfig.fromMap(decoded);
  }

  Future<void> saveVersion(ModelConfig config) async {
    final SharedPreferences preferences =
        await SharedPreferences.getInstance();
    await preferences.setString(_activeKey, jsonEncode(config.toMap()));

    final List<ModelConfig> history = await loadHistory();
    final List<ModelConfig> updated = <ModelConfig>[
      config,
      ...history.where(
        (item) => item.modelVersion != config.modelVersion,
      ),
    ].take(25).toList(growable: false);

    await preferences.setString(
      _historyKey,
      jsonEncode(updated.map((item) => item.toMap()).toList()),
    );
  }

  Future<List<ModelConfig>> loadHistory() async {
    final SharedPreferences preferences =
        await SharedPreferences.getInstance();
    final String? raw = preferences.getString(_historyKey);
    if (raw == null || raw.isEmpty) return <ModelConfig>[];
    final Object? decoded = jsonDecode(raw);
    if (decoded is! List) return <ModelConfig>[];
    return decoded
        .whereType<Map>()
        .map((item) => ModelConfig.fromMap(
              Map<String, dynamic>.from(item),
            ))
        .toList(growable: false);
  }

  Future<void> restore(ModelConfig config) async {
    await saveVersion(
      config.copyWith(
        updatedAt: DateTime.now(),
        changeNote: 'Versión restaurada desde el historial.',
      ),
    );
  }

  Future<void> reset() async {
    final SharedPreferences preferences =
        await SharedPreferences.getInstance();
    await preferences.remove(_activeKey);
  }
}
