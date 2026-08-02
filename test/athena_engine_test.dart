import 'package:flutter_test/flutter_test.dart';
import 'package:oraculo_diosa_fortuna/core/models/model_config.dart';
import 'package:oraculo_diosa_fortuna/core/services/athena_engine.dart';

void main() {
  const ModelConfig model = ModelConfig(
    modelName: 'Modelo Oficial PIT',
    modelVersion: '1.0.0',
    engineName: 'Motor Fortuna',
    engineVersion: '4.3.0',
    rules: <RuleConfig>[
      RuleConfig(
        key: 'sum',
        id: 'PIT-001',
        label: 'Suma histórica',
        category: 'Distribución',
        description: 'Prueba',
        status: 'Oficial',
        evidenceLevel: 5,
        author: 'PIT',
        introducedVersion: '1.0.0',
        enabled: true,
        weight: 2.0,
      ),
      RuleConfig(
        key: 'parity',
        id: 'PIT-002',
        label: 'Paridad',
        category: 'Composición',
        description: 'Prueba',
        status: 'Validada',
        evidenceLevel: 4,
        author: 'PIT',
        introducedVersion: '1.0.0',
        enabled: true,
        weight: 0.8,
      ),
    ],
    disclaimer: '',
  );

  final List<List<int>> history = <List<int>>[
    <int>[1, 7, 13, 19, 25, 31],
    <int>[2, 8, 14, 20, 26, 32],
    <int>[1, 8, 15, 22, 29, 36],
  ];

  test('identifica la regla activa con mayor peso', () {
    const AthenaEngine engine = AthenaEngine();

    final response = engine.answer(
      question: '¿Cuál regla tiene mayor peso?',
      model: model,
      modelHistory: const <ModelConfig>[],
      drawHistory: history,
      ranking: const [],
    );

    expect(response.title, 'Regla con mayor peso');
    expect(response.summary, contains('Suma histórica'));
    expect(response.details, isNotEmpty);
  });

  test('resume la salud del modelo con datos locales', () {
    const AthenaEngine engine = AthenaEngine();

    final response = engine.answer(
      question: '¿Cómo está la salud del modelo?',
      model: model,
      modelHistory: const <ModelConfig>[],
      drawHistory: history,
      ranking: const [],
    );

    expect(response.title, 'Salud del Modelo PIT');
    expect(response.details, isNotEmpty);
    expect(response.details.join(' '), contains('Reglas activas'));
  });

  test('orienta al usuario cuando no reconoce la consulta', () {
    const AthenaEngine engine = AthenaEngine();

    final response = engine.answer(
      question: 'Pregunta totalmente desconocida',
      model: model,
      modelHistory: const <ModelConfig>[],
      drawHistory: history,
      ranking: const [],
    );

    expect(response.title, 'Consulta no reconocida');
    expect(response.details.length, greaterThan(2));
  });
}
