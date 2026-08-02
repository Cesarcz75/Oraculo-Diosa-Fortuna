import 'package:flutter/material.dart';
import '../../core/models/model_config.dart';

class ResearchCenterScreen extends StatefulWidget {
  const ResearchCenterScreen({
    required this.config,
    super.key,
  });

  final ModelConfig config;

  @override
  State<ResearchCenterScreen> createState() => _ResearchCenterScreenState();
}

class _ResearchCenterScreenState extends State<ResearchCenterScreen> {
  static const Color gold = Color(0xFFE8B85A);
  static const Color panel = Color(0xFF1A1022);

  String _query = '';
  String _statusFilter = 'Todas';

  List<RuleConfig> get _filteredRules {
    final String normalizedQuery = _query.trim().toLowerCase();

    return widget.config.rules.where((RuleConfig rule) {
      final bool matchesStatus =
          _statusFilter == 'Todas' || rule.status == _statusFilter;
      final bool matchesQuery = normalizedQuery.isEmpty ||
          rule.id.toLowerCase().contains(normalizedQuery) ||
          rule.label.toLowerCase().contains(normalizedQuery) ||
          rule.category.toLowerCase().contains(normalizedQuery);

      return matchesStatus && matchesQuery;
    }).toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final int activeRules = widget.config.rules
        .where((RuleConfig rule) => rule.enabled)
        .length;
    final double averageEvidence = widget.config.rules.isEmpty
        ? 0
        : widget.config.rules
                .fold<int>(
                  0,
                  (int total, RuleConfig rule) =>
                      total + rule.evidenceLevel,
                ) /
            widget.config.rules.length;

    return ListView(
      padding: const EdgeInsets.all(24),
      children: <Widget>[
        Text(
          'Centro de Investigación PIT',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: gold,
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 6),
        Text(
          'Biblioteca técnica del ${widget.config.modelName}',
        ),
        const SizedBox(height: 20),
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: <Widget>[
            _MetricCard(
              icon: Icons.rule_folder_outlined,
              title: 'Reglas registradas',
              value: '${widget.config.rules.length}',
              caption: 'biblioteca PIT',
            ),
            _MetricCard(
              icon: Icons.check_circle_outline,
              title: 'Reglas activas',
              value: '$activeRules',
              caption: widget.config.engineName,
            ),
            _MetricCard(
              icon: Icons.verified_outlined,
              title: 'Evidencia promedio',
              value: averageEvidence.toStringAsFixed(1),
              caption: 'de 5 niveles',
            ),
            _MetricCard(
              icon: Icons.memory_outlined,
              title: 'Versión del modelo',
              value: widget.config.engineVersion,
              caption: widget.config.modelName,
            ),
          ],
        ),
        const SizedBox(height: 20),
        Card(
          color: panel,
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: <Widget>[
                SizedBox(
                  width: 320,
                  child: TextField(
                    onChanged: (String value) {
                      setState(() => _query = value);
                    },
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.search),
                      labelText: 'Buscar regla, categoría o ID',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                DropdownButton<String>(
                  value: _statusFilter,
                  items: const <String>[
                    'Todas',
                    'Oficial',
                    'Validada',
                    'En validación',
                    'Experimental',
                  ].map((String status) {
                    return DropdownMenuItem<String>(
                      value: status,
                      child: Text(status),
                    );
                  }).toList(),
                  onChanged: (String? value) {
                    if (value != null) {
                      setState(() => _statusFilter = value);
                    }
                  },
                ),
                Text(
                  '${_filteredRules.length} resultado(s)',
                  style: const TextStyle(color: Colors.white60),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 18),
        ..._filteredRules.map(
          (RuleConfig rule) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _RuleCard(
              rule: rule,
              onOpen: () => _openRule(rule),
            ),
          ),
        ),
        if (_filteredRules.isEmpty)
          const Card(
            color: panel,
            child: Padding(
              padding: EdgeInsets.all(28),
              child: Center(
                child: Text('No se encontraron reglas con esos filtros.'),
              ),
            ),
          ),
      ],
    );
  }

  void _openRule(RuleConfig rule) {
    showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text('${rule.id} · ${rule.label}'),
          content: SizedBox(
            width: 620,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  _DetailRow(label: 'Categoría', value: rule.category),
                  _DetailRow(label: 'Estado', value: rule.status),
                  _DetailRow(
                    label: 'Activa',
                    value: rule.enabled ? 'Sí' : 'No',
                  ),
                  _DetailRow(
                    label: 'Peso',
                    value: rule.weight.toStringAsFixed(2),
                  ),
                  _DetailRow(
                    label: 'Nivel de evidencia',
                    value: '${rule.evidenceLevel} de 5',
                  ),
                  _DetailRow(label: 'Autor', value: rule.author),
                  _DetailRow(
                    label: 'Incorporada en',
                    value: 'v${rule.introducedVersion}',
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Descripción',
                    style: TextStyle(
                      color: gold,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(rule.description),
                  const SizedBox(height: 20),
                  _EvidenceStars(level: rule.evidenceLevel),
                  const SizedBox(height: 18),
                  const Text(
                    'El nivel de evidencia es una clasificación interna del '
                    'proyecto. No constituye una probabilidad de acierto.',
                    style: TextStyle(
                      color: Colors.white60,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cerrar'),
            ),
          ],
        );
      },
    );
  }
}

class _RuleCard extends StatelessWidget {
  const _RuleCard({
    required this.rule,
    required this.onOpen,
  });

  static const Color gold = Color(0xFFE8B85A);
  static const Color panel = Color(0xFF1A1022);

  final RuleConfig rule;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: panel,
      child: InkWell(
        onTap: onOpen,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: <Widget>[
              CircleAvatar(
                backgroundColor: rule.enabled
                    ? const Color(0xFF5B1FA3)
                    : Colors.white12,
                child: Icon(
                  rule.enabled ? Icons.check : Icons.pause,
                  color: rule.enabled ? gold : Colors.white54,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      '${rule.id} · ${rule.label}',
                      style: const TextStyle(
                        color: gold,
                        fontWeight: FontWeight.bold,
                        fontSize: 17,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      rule.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: <Widget>[
                        _Tag(text: rule.category),
                        _Tag(text: rule.status),
                        _Tag(text: 'Peso ${rule.weight.toStringAsFixed(2)}'),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: <Widget>[
                  _EvidenceStars(level: rule.evidenceLevel),
                  const SizedBox(height: 8),
                  const Icon(Icons.chevron_right),
                ],
              ),
            ],
          ),
        ),
      ),
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
        width: 215,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: <Widget>[
              Icon(icon, color: gold, size: 30),
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
                        fontSize: 24,
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

class _EvidenceStars extends StatelessWidget {
  const _EvidenceStars({required this.level});

  static const Color gold = Color(0xFFE8B85A);

  final int level;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List<Widget>.generate(
        5,
        (int index) => Icon(
          index < level ? Icons.star : Icons.star_border,
          color: gold,
          size: 18,
        ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFF2A103A),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        text,
        style: const TextStyle(fontSize: 12),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.value,
  });

  static const Color gold = Color(0xFFE8B85A);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 11),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: 155,
            child: Text(
              label,
              style: const TextStyle(
                color: gold,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
