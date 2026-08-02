import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:oraculo_diosa_fortuna/core/models/model_config.dart';
import 'package:oraculo_diosa_fortuna/core/services/model_config_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test('guarda y recupera una versión editable del Modelo PIT', () async {
    const ModelConfigRepository repository = ModelConfigRepository();

    final ModelConfig config = ModelConfig(
      modelName: 'Modelo Oficial PIT',
      modelVersion: '1.0.1',
      engineName: 'Motor Fortuna',
      engineVersion: '4.0.0',
      rules: const <RuleConfig>[
        RuleConfig(
          key: 'sum',
          id: 'PIT-001',
          label: 'Suma',
          category: 'Distribución',
          description: 'Prueba',
          status: 'Oficial',
          evidenceLevel: 5,
          author: 'PIT',
          introducedVersion: '1.0.0',
          enabled: true,
          weight: 1.75,
        ),
      ],
      disclaimer: '',
      updatedAt: DateTime(2026, 8, 2),
      changeNote: 'Ajuste de suma',
    );

    await repository.saveVersion(config);

    final ModelConfig restored = await repository.load();
    final List<ModelConfig> history = await repository.loadHistory();

    expect(restored.modelVersion, '1.0.1');
    expect(restored.rule('sum').weight, 1.75);
    expect(history, hasLength(1));
    expect(history.single.changeNote, 'Ajuste de suma');
  });
}
