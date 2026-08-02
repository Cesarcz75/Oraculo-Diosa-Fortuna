import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../models/professional_report_data.dart';
import '../models/ranked_combination.dart';
import '../models/model_config.dart';

class ProfessionalReportService {
  const ProfessionalReportService();

  Future<Uint8List> buildPdf(
    ProfessionalReportData data,
    PdfPageFormat format,
  ) async {
    final pw.Document document = pw.Document(
      title: 'Reporte Oráculo Diosa Fortuna',
      author: 'PRIME Innovation Thinking',
      subject: 'Reporte estadístico del Modelo PIT',
      creator: 'Oráculo Diosa Fortuna Professional',
    );

    final ByteData logoData =
        await rootBundle.load('assets/images/oraculo_logo.png');
    final ByteData pitData =
        await rootBundle.load('assets/images/pit_powered_by.png');
    final pw.MemoryImage logo = pw.MemoryImage(
      logoData.buffer.asUint8List(),
    );
    final pw.MemoryImage pitSignature = pw.MemoryImage(
      pitData.buffer.asUint8List(),
    );

    document.addPage(
      pw.MultiPage(
        pageFormat: format,
        margin: const pw.EdgeInsets.all(34),
        header: (pw.Context context) => _header(
          context,
          data,
          logo,
        ),
        footer: (pw.Context context) => _footer(
          context,
          pitSignature,
        ),
        build: (pw.Context context) => <pw.Widget>[
          _executiveSummary(data),
          pw.SizedBox(height: 18),
          _rankingSection(data),
          pw.SizedBox(height: 18),
          _leaderBreakdown(data),
          pw.SizedBox(height: 18),
          _modelSection(data),
          pw.SizedBox(height: 18),
          _observations(data),
          pw.SizedBox(height: 12),
          pw.Text(
            'Nota metodológica: las puntuaciones, el Índice PIT y los '
            'análisis históricos describen el ajuste interno al Modelo PIT. '
            'No representan una probabilidad de ganar ni garantizan premios.',
            style: const pw.TextStyle(
              fontSize: 8,
              color: PdfColors.grey700,
            ),
          ),
        ],
      ),
    );

    return document.save();
  }

  pw.Widget _header(
    pw.Context context,
    ProfessionalReportData data,
    pw.MemoryImage logo,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 12),
      margin: const pw.EdgeInsets.only(bottom: 18),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(
            color: PdfColor.fromInt(0xFFE8B85A),
            width: 1.5,
          ),
        ),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: <pw.Widget>[
          pw.Image(logo, width: 54, height: 54),
          pw.SizedBox(width: 12),
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: <pw.Widget>[
                pw.Text(
                  'ORÁCULO DIOSA FORTUNA PROFESSIONAL',
                  style: pw.TextStyle(
                    fontSize: 17,
                    fontWeight: pw.FontWeight.bold,
                    color: const PdfColor.fromInt(0xFF5B1FA3),
                  ),
                ),
                pw.SizedBox(height: 3),
                pw.Text(
                  'Reporte Ejecutivo del Modelo PIT',
                  style: const pw.TextStyle(fontSize: 10),
                ),
              ],
            ),
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: <pw.Widget>[
              pw.Text(
                _date(data.generatedAt),
                style: const pw.TextStyle(fontSize: 9),
              ),
              pw.Text(
                'Página ${context.pageNumber}',
                style: const pw.TextStyle(
                  fontSize: 8,
                  color: PdfColors.grey700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _footer(
    pw.Context context,
    pw.MemoryImage signature,
  ) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 16),
      padding: const pw.EdgeInsets.only(top: 8),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          top: pw.BorderSide(
            color: PdfColors.grey400,
            width: 0.5,
          ),
        ),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: <pw.Widget>[
          pw.Text(
            'Documento generado por Oráculo Diosa Fortuna',
            style: const pw.TextStyle(
              fontSize: 7,
              color: PdfColors.grey700,
            ),
          ),
          pw.Image(signature, height: 23),
        ],
      ),
    );
  }

  pw.Widget _executiveSummary(ProfessionalReportData data) {
    final RankedCombination? leader = data.leader;

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: <pw.Widget>[
        _sectionTitle('Resumen ejecutivo'),
        pw.Wrap(
          spacing: 10,
          runSpacing: 10,
          children: <pw.Widget>[
            _metric(
              'Software',
              data.softwareVersion,
              'versión instalada',
            ),
            _metric(
              'Modelo PIT',
              data.model.modelVersion,
              data.model.modelName,
            ),
            _metric(
              'Reglas activas',
              '${data.activeRuleCount}',
              'peso ${data.activeWeightTotal.toStringAsFixed(2)}',
            ),
            _metric(
              'Histórico',
              '${data.historyCount}',
              'sorteos analizados',
            ),
            _metric(
              'Ranking',
              '${data.ranking.length}',
              'combinaciones',
            ),
            _metric(
              'Índice PIT líder',
              leader == null
                  ? '—'
                  : leader.pitIndex.toStringAsFixed(1),
              'indicador interno',
            ),
          ],
        ),
      ],
    );
  }

  pw.Widget _rankingSection(ProfessionalReportData data) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: <pw.Widget>[
        _sectionTitle('Ranking generado'),
        if (data.ranking.isEmpty)
          pw.Text(
            'No se había generado un ranking al crear este reporte.',
            style: const pw.TextStyle(color: PdfColors.grey700),
          )
        else
          pw.TableHelper.fromTextArray(
            headers: const <String>[
              '#',
              'Combinación',
              'Suma',
              'Paridad',
              'Repite',
              'Score',
              'Índice PIT',
            ],
            data: List<List<String>>.generate(
              data.ranking.length,
              (int index) {
                final RankedCombination item = data.ranking[index];
                return <String>[
                  '${index + 1}',
                  item.label,
                  '${item.sum}',
                  '${item.evens}P/${item.odds}I',
                  '${item.repeated}',
                  item.score.toStringAsFixed(3),
                  item.pitIndex.toStringAsFixed(1),
                ];
              },
            ),
            headerStyle: pw.TextStyle(
              color: PdfColors.white,
              fontWeight: pw.FontWeight.bold,
              fontSize: 8,
            ),
            headerDecoration: const pw.BoxDecoration(
              color: PdfColor.fromInt(0xFF5B1FA3),
            ),
            cellStyle: const pw.TextStyle(fontSize: 8),
            cellAlignment: pw.Alignment.center,
            cellPadding: const pw.EdgeInsets.all(5),
            border: pw.TableBorder.all(
              color: PdfColors.grey400,
              width: 0.4,
            ),
          ),
      ],
    );
  }

  pw.Widget _leaderBreakdown(ProfessionalReportData data) {
    final RankedCombination? leader = data.leader;

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: <pw.Widget>[
        _sectionTitle('Explicación del primer lugar'),
        if (leader == null)
          pw.Text('Sin información disponible.')
        else ...<pw.Widget>[
          pw.Text(
            leader.label,
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
              color: const PdfColor.fromInt(0xFF5B1FA3),
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            'Score ${leader.score.toStringAsFixed(3)} · '
            'Índice PIT ${leader.pitIndex.toStringAsFixed(1)} · '
            'Suma ${leader.sum}',
            style: const pw.TextStyle(fontSize: 9),
          ),
          pw.SizedBox(height: 10),
          ..._orderedContributions(leader).map(
            (MapEntry<String, double> entry) {
              final double share = leader.breakdown.rules
                  .firstWhere(
                    (rule) => rule.label == entry.key,
                  )
                  .influence
                  .clamp(0.0, 1.0)
                  .toDouble();
              return pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 7),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: <pw.Widget>[
                    pw.Row(
                      children: <pw.Widget>[
                        pw.Expanded(
                          child: pw.Text(
                            entry.key,
                            style: const pw.TextStyle(fontSize: 8),
                          ),
                        ),
                        pw.Text(
                          entry.value.toStringAsFixed(3),
                          style: pw.TextStyle(
                            fontSize: 8,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    pw.SizedBox(height: 3),
					pw.Container(
						height: 6,
						decoration: pw.BoxDecoration(
						color: PdfColors.grey300,
						borderRadius: pw.BorderRadius.circular(3),
					),
					child: pw.Container(
						width: 220 * share,
						decoration: pw.BoxDecoration(
						color: const PdfColor.fromInt(0xFFE8B85A),
						borderRadius: pw.BorderRadius.circular(3),
					),
				),
				),
				],
				),
				);
            },
          ),
        ],
      ],
    );
  }

  pw.Widget _modelSection(ProfessionalReportData data) {
    final List<RuleConfig> ordered =
        List<RuleConfig>.from(data.model.rules)
          ..sort(
            (RuleConfig a, RuleConfig b) =>
                b.weight.compareTo(a.weight),
          );

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: <pw.Widget>[
        _sectionTitle('Configuración del Modelo PIT'),
        pw.TableHelper.fromTextArray(
          headers: const <String>[
            'ID',
            'Regla',
            'Estado',
            'Activa',
            'Peso',
            'Evidencia',
          ],
          data: ordered
              .map(
                (RuleConfig rule) => <String>[
                  rule.id,
                  rule.label,
                  rule.status,
                  rule.enabled ? 'Sí' : 'No',
                  rule.weight.toStringAsFixed(2),
                  '${rule.evidenceLevel}/5',
                ],
              )
              .toList(growable: false),
          headerStyle: pw.TextStyle(
            color: PdfColors.white,
            fontWeight: pw.FontWeight.bold,
            fontSize: 8,
          ),
          headerDecoration: const pw.BoxDecoration(
            color: PdfColor.fromInt(0xFF5B1FA3),
          ),
          cellStyle: const pw.TextStyle(fontSize: 8),
          cellPadding: const pw.EdgeInsets.all(5),
          border: pw.TableBorder.all(
            color: PdfColors.grey400,
            width: 0.4,
          ),
        ),
      ],
    );
  }

  pw.Widget _observations(ProfessionalReportData data) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: <pw.Widget>[
        _sectionTitle('Observaciones'),
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.all(12),
          decoration: pw.BoxDecoration(
            color: PdfColors.grey100,
            borderRadius: pw.BorderRadius.circular(6),
            border: pw.Border.all(
              color: PdfColors.grey400,
              width: 0.5,
            ),
          ),
          child: pw.Text(
            data.observations.trim().isEmpty
                ? 'Sin observaciones adicionales.'
                : data.observations.trim(),
            style: const pw.TextStyle(fontSize: 9),
          ),
        ),
      ],
    );
  }

  pw.Widget _sectionTitle(String title) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 10),
      child: pw.Text(
        title,
        style: pw.TextStyle(
          fontSize: 13,
          fontWeight: pw.FontWeight.bold,
          color: const PdfColor.fromInt(0xFF5B1FA3),
        ),
      ),
    );
  }

  pw.Widget _metric(
    String title,
    String value,
    String caption,
  ) {
    return pw.Container(
      width: 150,
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: const PdfColor.fromInt(0xFFF4EEF9),
        borderRadius: pw.BorderRadius.circular(6),
        border: pw.Border.all(
          color: const PdfColor.fromInt(0xFFD6C0E8),
          width: 0.5,
        ),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: <pw.Widget>[
          pw.Text(
            title,
            style: const pw.TextStyle(
              fontSize: 7,
              color: PdfColors.grey700,
            ),
          ),
          pw.SizedBox(height: 3),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
              color: const PdfColor.fromInt(0xFF5B1FA3),
            ),
          ),
          pw.Text(
            caption,
            style: const pw.TextStyle(
              fontSize: 7,
              color: PdfColors.grey700,
            ),
          ),
        ],
      ),
    );
  }

  List<MapEntry<String, double>> _orderedContributions(
    RankedCombination item,
  ) {
    return item.contributions.entries.toList()
      ..sort(
        (MapEntry<String, double> a, MapEntry<String, double> b) =>
            b.value.abs().compareTo(a.value.abs()),
      );
  }

  static String _date(DateTime value) {
    String two(int number) => number.toString().padLeft(2, '0');
    return '${two(value.day)}/${two(value.month)}/${value.year} '
        '${two(value.hour)}:${two(value.minute)}';
  }
}
