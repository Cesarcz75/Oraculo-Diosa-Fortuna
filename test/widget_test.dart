import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oraculo_diosa_fortuna/app/oraculo_app.dart';

void main() {
  testWidgets('la aplicación inicia correctamente', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const OraculoApp());
    await tester.pump();

    expect(find.byType(MaterialApp), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}