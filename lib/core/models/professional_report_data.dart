import 'model_config.dart';
import 'ranked_combination.dart';

class ProfessionalReportData {
  const ProfessionalReportData({
    required this.generatedAt,
    required this.softwareVersion,
    required this.model,
    required this.historyCount,
    required this.ranking,
    required this.observations,
  });

  final DateTime generatedAt;
  final String softwareVersion;
  final ModelConfig model;
  final int historyCount;
  final List<RankedCombination> ranking;
  final String observations;

  RankedCombination? get leader =>
      ranking.isEmpty ? null : ranking.first;

  int get activeRuleCount => model.rules
      .where((RuleConfig rule) => rule.enabled)
      .length;

  double get activeWeightTotal => model.rules
      .where((RuleConfig rule) => rule.enabled)
      .fold<double>(
        0,
        (double total, RuleConfig rule) => total + rule.weight,
      );
}
