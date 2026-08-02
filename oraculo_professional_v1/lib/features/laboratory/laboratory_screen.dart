import 'package:flutter/material.dart';

class LaboratoryScreen extends StatelessWidget {
  const LaboratoryScreen({
    required this.history,
    super.key,
  });

  final List<List<int>> history;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: <Widget>[
        Text(
          'Laboratorio',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 18),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              'Histórico disponible: ${history.length} sorteos.\n\n'
              'La siguiente fase incorporará backtesting fuera de muestra, '
              'comparación contra azar y optimización de pesos. Ninguna regla '
              'se marcará como predictiva sin validación temporal.',
            ),
          ),
        ),
      ],
    );
  }
}
