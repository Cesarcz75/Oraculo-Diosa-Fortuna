import 'package:flutter_test/flutter_test.dart';
import 'package:oraculo_diosa_fortuna/core/models/model_config.dart';

void main() {
  test('la biblioteca PIT carga los metadatos de una regla', () {
    final ModelConfig config = ModelConfig.fromMap(<String, dynamic>{
      'modelName': 'Modelo Oficial PIT',
      'engineName': 'Motor Fortuna',
      'engineVersion': '3.5.0',
      'rules': <String, dynamic>{
        'sum': <String, dynamic>{
          'id': 'PIT-001',
          'label': 'Suma histórica',
          'category': 'Distribución',
          'description': 'Descripción de prueba',
          'status': 'Oficial',
          'evidenceLevel': 5,
          'author': 'PRIME Innovation Thinking',
          'introducedVersion': '2.0.0',
          'enabled': true,
          'weight': 2.0,
        },
      },
    });

    final RuleConfig rule = config.rule('sum');

    expect(rule.id, 'PIT-001');
    expect(rule.status, 'Oficial');
    expect(rule.evidenceLevel, 5);
    expect(rule.description, isNotEmpty);
    expect(rule.weight, 2.0);
  });

  test('una regla desconocida se devuelve inactiva', () {
    const ModelConfig config = ModelConfig(
      modelName: 'Modelo',
      engineName: 'Motor',
      engineVersion: '3.5.0',
      rules: <RuleConfig>[],
      disclaimer: '',
    );

    final RuleConfig rule = config.rule('desconocida');

    expect(rule.enabled, isFalse);
    expect(rule.weight, 0);
    expect(rule.status, 'Inactiva');
  });
}
