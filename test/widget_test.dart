import 'package:flutter_test/flutter_test.dart';
import 'package:oraculo_diosa_fortuna/app/oraculo_app.dart';

void main() {
  testWidgets('la aplicación inicia correctamente', (WidgetTester tester) async {
    await tester.pumpWidget(const OraculoApp());
    expect(find.text('Oráculo Diosa Fortuna Professional'), findsOneWidget);
  });
}
