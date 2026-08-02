import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import '../../core/models/model_config.dart';
import '../../core/models/professional_report_data.dart';
import '../../core/models/ranked_combination.dart';
import '../../core/services/professional_report_service.dart';

class ProfessionalReportScreen extends StatefulWidget {
  const ProfessionalReportScreen({
    required this.model,
    required this.historyCount,
    required this.ranking,
    super.key,
  });

  final ModelConfig model;
  final int historyCount;
  final List<RankedCombination> ranking;

  @override
  State<ProfessionalReportScreen> createState() =>
      _ProfessionalReportScreenState();
}

class _ProfessionalReportScreenState
    extends State<ProfessionalReportScreen> {
  static const Color gold = Color(0xFFE8B85A);
  static const Color panel = Color(0xFF1A1022);

  final ProfessionalReportService _service =
      const ProfessionalReportService();
  final TextEditingController _observationsController =
      TextEditingController();

  bool _includeAllRanking = true;

  @override
  void dispose() {
    _observationsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final List<RankedCombination> selectedRanking =
        _includeAllRanking
            ? widget.ranking
            : widget.ranking.take(10).toList(growable: false);

    final ProfessionalReportData data = ProfessionalReportData(
      generatedAt: DateTime.now(),
      softwareVersion: '4.4.0',
      model: widget.model,
      historyCount: widget.historyCount,
      ranking: selectedRanking,
      observations: _observationsController.text,
    );

    return ListView(
      padding: const EdgeInsets.all(24),
      children: <Widget>[
        Text(
          'Reportes Profesionales',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: gold,
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Genera, revisa, imprime o comparte un reporte ejecutivo en PDF.',
        ),
        const SizedBox(height: 20),
        Card(
          color: panel,
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Text(
                  'CONFIGURACIÓN DEL REPORTE',
                  style: TextStyle(
                    color: gold,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 14),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _includeAllRanking,
                  activeThumbColor: gold,
                  title: const Text('Incluir ranking completo'),
                  subtitle: Text(
                    _includeAllRanking
                        ? '${widget.ranking.length} combinaciones'
                        : 'Solo las primeras 10 combinaciones',
                  ),
                  onChanged: (bool value) {
                    setState(() => _includeAllRanking = value);
                  },
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _observationsController,
                  maxLines: 4,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                    labelText: 'Observaciones',
                    hintText:
                        'Agrega comentarios para el expediente o análisis.',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 18),
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: <Widget>[
            _MetricCard(
              icon: Icons.description_outlined,
              title: 'Formato',
              value: 'PDF',
              caption: 'reporte ejecutivo',
            ),
            _MetricCard(
              icon: Icons.analytics_outlined,
              title: 'Ranking',
              value: '${selectedRanking.length}',
              caption: 'combinaciones',
            ),
            _MetricCard(
              icon: Icons.rule_outlined,
              title: 'Reglas',
              value: '${widget.model.activeRuleCount}',
              caption: 'activas',
            ),
            _MetricCard(
              icon: Icons.storage_outlined,
              title: 'Histórico',
              value: '${widget.historyCount}',
              caption: 'sorteos',
            ),
          ],
        ),
        const SizedBox(height: 18),
        SizedBox(
          height: 720,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: PdfPreview(
              build: (format) => _service.buildPdf(data, format),
              canChangePageFormat: true,
              canChangeOrientation: false,
              allowPrinting: true,
              allowSharing: true,
              pdfFileName:
                  'Oraculo_Diosa_Fortuna_${widget.model.modelVersion}.pdf',
              loadingWidget: const Center(
                child: CircularProgressIndicator(),
              ),
              onError: (BuildContext context, Object error) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text(
                      'No se pudo generar la vista previa: $error',
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 14),
        const Card(
          color: panel,
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'El reporte incorpora el Modelo PIT activo, el ranking actual, '
              'el Score Breakdown del primer lugar y la firma institucional '
              'de PRIME Innovation Thinking.',
              style: TextStyle(
                color: Colors.white60,
                fontSize: 12,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.caption,
  });

  static const Color gold = Color(0xFFE8B85A);
  static const Color panel = Color(0xFF1A1022);

  final IconData icon;
  final String title;
  final String value;
  final String caption;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: panel,
      child: SizedBox(
        width: 210,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: <Widget>[
              Icon(icon, color: gold, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      title,
                      style: const TextStyle(color: Colors.white60),
                    ),
                    Text(
                      value,
                      style: const TextStyle(
                        color: gold,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(caption),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
