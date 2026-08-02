import 'package:flutter/material.dart';
import '../../core/models/model_config.dart';
import '../../core/models/ranked_combination.dart';
import '../../core/models/system_diagnostics.dart';
import '../../core/services/system_diagnostics_engine.dart';

class HelpCenterScreen extends StatefulWidget {
  const HelpCenterScreen({
    required this.model,
    required this.drawHistory,
    required this.ranking,
    required this.savedModelVersions,
    super.key,
  });

  final ModelConfig model;
  final List<List<int>> drawHistory;
  final List<RankedCombination> ranking;
  final int savedModelVersions;

  @override
  State<HelpCenterScreen> createState() => _HelpCenterScreenState();
}

class _HelpCenterScreenState extends State<HelpCenterScreen> {
  static const Color gold = Color(0xFFE8B85A);
  static const Color panel = Color(0xFF1A1022);

  final TextEditingController _searchController =
      TextEditingController();

  String _query = '';

  static const List<_HelpTopic> _topics = <_HelpTopic>[
    _HelpTopic(
      title: 'Primeros pasos',
      icon: Icons.rocket_launch_outlined,
      keywords: 'inicio histórico sorteo ranking comenzar',
      content:
          '1. Verifica o captura el último sorteo desde Dashboard.\n'
          '2. Genera el ranking.\n'
          '3. Revisa el Score Breakdown y el Índice PIT.\n'
          '4. Consulta Métricas PIT y Auditor PIT.\n'
          '5. Prueba cambios en el Simulador antes de guardarlos.\n'
          '6. Genera el reporte PDF para documentar el análisis.',
    ),
    _HelpTopic(
      title: 'Modelo PIT',
      icon: Icons.account_tree_outlined,
      keywords: 'modelo reglas pesos versión configuración',
      content:
          'El Modelo PIT contiene las reglas activas, sus pesos, evidencia '
          'y estado. Cada cambio importante debe guardarse como una nueva '
          'versión con una nota que explique el motivo.',
    ),
    _HelpTopic(
      title: 'Score e Índice PIT',
      icon: Icons.score_outlined,
      keywords: 'score indice pit puntos ranking influencia',
      content:
          'El Score combina los aportes ponderados de las reglas activas. '
          'El Índice PIT describe el equilibrio interno de esos aportes. '
          'Ninguno de los dos representa una probabilidad de ganar.',
    ),
    _HelpTopic(
      title: 'ATHENA',
      icon: Icons.psychology_alt_outlined,
      keywords: 'athena preguntas analista explicación',
      content:
          'ATHENA analiza localmente el modelo, el histórico y el ranking. '
          'Puede explicar reglas, cambios de versiones, frecuencia histórica '
          'y el primer lugar del ranking. No consulta internet.',
    ),
    _HelpTopic(
      title: 'Métricas PIT',
      icon: Icons.monitor_heart_outlined,
      keywords: 'salud cobertura evidencia robustez balance',
      content:
          'Métricas PIT evalúa cobertura, evidencia, balance del Score, '
          'robustez de pesos, profundidad histórica y madurez del versionado.',
    ),
    _HelpTopic(
      title: 'Auditor PIT',
      icon: Icons.fact_check_outlined,
      keywords: 'auditor alertas errores pesos evidencia',
      content:
          'Auditor PIT identifica riesgos de configuración: evidencia baja, '
          'pesos extremos, reglas duplicadas, influencia concentrada y '
          'profundidad histórica limitada.',
    ),
    _HelpTopic(
      title: 'Simulador PIT',
      icon: Icons.tune_outlined,
      keywords: 'simulador experimental cambios aplicar descartar',
      content:
          'El Simulador crea una copia temporal del modelo. Los cambios no '
          'afectan la versión oficial hasta seleccionar “Aplicar como nueva '
          'versión”. Después de aplicar, genera un ranking exhaustivo nuevo.',
    ),
    _HelpTopic(
      title: 'Reportes PDF',
      icon: Icons.picture_as_pdf_outlined,
      keywords: 'reporte pdf imprimir compartir guardar',
      content:
          'Reportes genera un documento ejecutivo con el Modelo PIT activo, '
          'ranking, Score Breakdown, indicadores y observaciones. Puedes '
          'revisarlo, imprimirlo, guardarlo o compartirlo.',
    ),
    _HelpTopic(
      title: 'Interpretación responsable',
      icon: Icons.info_outline,
      keywords: 'probabilidad ganar garantía metodología aviso',
      content:
          'La aplicación realiza análisis estadístico y evaluación '
          'multicriterio. Sus indicadores no alteran la probabilidad '
          'matemática del sorteo ni garantizan premios.',
    ),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<_HelpTopic> get _visibleTopics {
    final String normalized = _query.trim().toLowerCase();
    if (normalized.isEmpty) {
      return _topics;
    }

    return _topics
        .where(
          (_HelpTopic topic) =>
              topic.title.toLowerCase().contains(normalized) ||
              topic.keywords.contains(normalized) ||
              topic.content.toLowerCase().contains(normalized),
        )
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final SystemDiagnostics diagnostics =
        const SystemDiagnosticsEngine().run(
      model: widget.model,
      drawHistory: widget.drawHistory,
      ranking: widget.ranking,
      savedModelVersions: widget.savedModelVersions,
    );

    return ListView(
      padding: const EdgeInsets.all(24),
      children: <Widget>[
        Text(
          'Centro de Ayuda',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: gold,
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Guía integrada, diagnóstico de sesión y conceptos principales.',
        ),
        const SizedBox(height: 20),
        _DiagnosticsCard(diagnostics: diagnostics),
        const SizedBox(height: 18),
        TextField(
          controller: _searchController,
          onChanged: (String value) =>
              setState(() => _query = value),
          decoration: InputDecoration(
            labelText: 'Buscar en la ayuda',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: _query.isEmpty
                ? null
                : IconButton(
                    tooltip: 'Limpiar',
                    onPressed: () {
                      _searchController.clear();
                      setState(() => _query = '');
                    },
                    icon: const Icon(Icons.close),
                  ),
            border: const OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        if (_visibleTopics.isEmpty)
          const Card(
            color: panel,
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Text(
                'No se encontraron temas relacionados con la búsqueda.',
              ),
            ),
          )
        else
          ..._visibleTopics.map(
            (_HelpTopic topic) => Card(
              color: panel,
              child: ExpansionTile(
                leading: Icon(topic.icon, color: gold),
                title: Text(
                  topic.title,
                  style: const TextStyle(
                    color: gold,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                childrenPadding:
                    const EdgeInsets.fromLTRB(20, 0, 20, 20),
                children: <Widget>[
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(topic.content),
                  ),
                ],
              ),
            ),
          ),
        const SizedBox(height: 16),
        Card(
          color: panel,
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Icon(Icons.verified_user_outlined, color: gold),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Versión del software: 1.0.0\n'
                    'Modelo activo: ${widget.model.modelVersion}\n'
                    'Motor: ${widget.model.engineName} '
                    'v${widget.model.engineVersion}\n\n'
                    'Desarrollado por PRIME Innovation Thinking.',
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _DiagnosticsCard extends StatelessWidget {
  const _DiagnosticsCard({required this.diagnostics});


  static const Color panel = Color(0xFF1A1022);

  final SystemDiagnostics diagnostics;

  @override
  Widget build(BuildContext context) {
    final Color stateColor = diagnostics.unavailableCount > 0
        ? Colors.redAccent
        : diagnostics.warningCount > 0
            ? Colors.amberAccent
            : Colors.greenAccent;

    return Card(
      color: panel,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(Icons.health_and_safety_outlined, color: stateColor),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    diagnostics.overallLabel,
                    style: TextStyle(
                      color: stateColor,
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Text(
                  '${diagnostics.readyCount}/${diagnostics.checks.length} listos',
                  style: const TextStyle(color: Colors.white60),
                ),
              ],
            ),
            const SizedBox(height: 14),
            ...diagnostics.checks.map(
              (DiagnosticCheck check) {
                final IconData icon;
                final Color color;
                switch (check.status) {
                  case DiagnosticStatus.ready:
                    icon = Icons.check_circle_outline;
                    color = Colors.greenAccent;
                  case DiagnosticStatus.warning:
                    icon = Icons.warning_amber_outlined;
                    color = Colors.amberAccent;
                  case DiagnosticStatus.unavailable:
                    icon = Icons.error_outline;
                    color = Colors.redAccent;
                }

                return Padding(
                  padding: const EdgeInsets.only(bottom: 11),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Icon(icon, color: color, size: 20),
                      const SizedBox(width: 9),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              check.title,
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              check.detail,
                              style:
                                  const TextStyle(color: Colors.white60),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _HelpTopic {
  const _HelpTopic({
    required this.title,
    required this.icon,
    required this.keywords,
    required this.content,
  });

  final String title;
  final IconData icon;
  final String keywords;
  final String content;
}
