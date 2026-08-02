import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/model_config.dart';

class ModelConfigRepository {
  const ModelConfigRepository();

  Future<ModelConfig> load() async {
    final String raw = await rootBundle.loadString(
      'assets/config/model_config.json',
    );
    final Object? decoded = jsonDecode(raw);

    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('La configuración del modelo no es válida.');
    }

    return ModelConfig.fromMap(decoded);
  }
}
