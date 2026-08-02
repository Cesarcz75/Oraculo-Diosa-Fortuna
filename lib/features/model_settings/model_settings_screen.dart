import 'package:flutter/material.dart';
import '../../core/models/model_config.dart';

class ModelSettingsScreen extends StatefulWidget {
  const ModelSettingsScreen({
    required this.config,
    required this.history,
    required this.onSave,
    required this.onRestore,
    required this.onReset,
    super.key,
  });

  final ModelConfig config;
  final List<ModelConfig> history;
  final Future<void> Function(ModelConfig config) onSave;
  final Future<void> Function(ModelConfig config) onRestore;
  final Future<void> Function() onReset;

  @override
  State<ModelSettingsScreen> createState() => _ModelSettingsScreenState();
}

class _ModelSettingsScreenState extends State<ModelSettingsScreen> {
  static const Color gold = Color(0xFFE8B85A);
  static const Color panel = Color(0xFF1A1022);

  late List<RuleConfig> _draftRules;
  late TextEditingController _versionController;
  late TextEditingController _noteController;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadDraft();
  }

  @override
  void didUpdateWidget(covariant ModelSettingsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.config.modelVersion != widget.config.modelVersion) {
      _versionController.dispose();
      _noteController.dispose();
      _loadDraft();
    }
  }

  void _loadDraft() {
    _draftRules = List<RuleConfig>.from(widget.config.rules);
    _versionController = TextEditingController(
      text: _nextPatch(widget.config.modelVersion),
    );
    _noteController = TextEditingController();
  }

  @override
  void dispose() {
    _versionController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: <Widget>[
        Text(
          'Modelo PIT',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: gold,
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 6),
        Text(
          '${widget.config.modelName} v${widget.config.modelVersion} · '
          '${widget.config.engineName} v${widget.config.engineVersion}',
        ),
        const SizedBox(height: 18),
        Card(
          color: panel,
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              children: <Widget>[
                TextField(
                  controller: _versionController,
                  decoration: const InputDecoration(
                    labelText: 'Nueva versión del Modelo PIT',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _noteController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Motivo del cambio',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        ...List<Widget>.generate(_draftRules.length, (int index) {
          final RuleConfig rule = _draftRules[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Card(
              color: panel,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: <Widget>[
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      value: rule.enabled,
                      activeThumbColor: gold,
                      title: Text(
                        '${rule.id} · ${rule.label}',
                        style: const TextStyle(
                          color: gold,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text('${rule.category} · ${rule.status}'),
                      onChanged: (bool value) {
                        setState(() {
                          _draftRules[index] =
                              rule.copyWith(enabled: value);
                        });
                      },
                    ),
                    Row(
                      children: <Widget>[
                        const SizedBox(width: 70, child: Text('Peso')),
                        Expanded(
                          child: Slider(
                            value: rule.weight.clamp(0.0, 3.0).toDouble(),
                            min: 0,
                            max: 3,
                            divisions: 60,
                            label: rule.weight.toStringAsFixed(2),
                            onChanged: rule.enabled
                                ? (double value) {
                                    setState(() {
                                      _draftRules[index] = rule.copyWith(
                                        weight: double.parse(
                                          value.toStringAsFixed(2),
                                        ),
                                      );
                                    });
                                  }
                                : null,
                          ),
                        ),
                        SizedBox(
                          width: 54,
                          child: Text(
                            rule.weight.toStringAsFixed(2),
                            textAlign: TextAlign.end,
                            style: const TextStyle(
                              color: gold,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
        const SizedBox(height: 8),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: <Widget>[
            FilledButton.icon(
              onPressed: _saving ? null : _save,
              icon: const Icon(Icons.save_outlined),
              label: const Text('GUARDAR NUEVA VERSIÓN'),
              style: FilledButton.styleFrom(
                backgroundColor: gold,
                foregroundColor: Colors.black,
              ),
            ),
            OutlinedButton.icon(
              onPressed: _saving ? null : _reset,
              icon: const Icon(Icons.restart_alt),
              label: const Text('Restablecer configuración'),
            ),
          ],
        ),
        const SizedBox(height: 24),
        const Text(
          'HISTORIAL DEL MODELO',
          style: TextStyle(color: gold, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        if (widget.history.isEmpty)
          const Card(
            color: panel,
            child: Padding(
              padding: EdgeInsets.all(18),
              child: Text('Todavía no hay versiones guardadas.'),
            ),
          )
        else
          ...widget.history.map(
            (ModelConfig version) => Card(
              color: panel,
              child: ListTile(
                leading: const Icon(Icons.history, color: gold),
                title: Text(
                  'Modelo PIT v${version.modelVersion}',
                  style: const TextStyle(color: gold),
                ),
                subtitle: Text(
                  version.changeNote.isEmpty
                      ? 'Sin nota de cambios'
                      : version.changeNote,
                ),
                trailing: TextButton(
                  onPressed:
                      _saving ? null : () => _restore(version),
                  child: const Text('Restaurar'),
                ),
              ),
            ),
          ),
        const SizedBox(height: 14),
        Text(
          widget.config.disclaimer,
          style: const TextStyle(color: Colors.white60, fontSize: 12),
        ),
      ],
    );
  }

  Future<void> _save() async {
    final String version = _versionController.text.trim();
    if (!RegExp(r'^\d+\.\d+\.\d+$').hasMatch(version)) {
      _show('Usa una versión como 1.0.1.');
      return;
    }
    if (_noteController.text.trim().isEmpty) {
      _show('Describe el motivo del cambio.');
      return;
    }

    setState(() => _saving = true);
    try {
      await widget.onSave(
        widget.config.copyWith(
          modelVersion: version,
          rules: List<RuleConfig>.unmodifiable(_draftRules),
          updatedAt: DateTime.now(),
          changeNote: _noteController.text.trim(),
        ),
      );
      if (mounted) _show('Modelo PIT v$version guardado.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _restore(ModelConfig version) async {
    setState(() => _saving = true);
    try {
      await widget.onRestore(version);
      if (mounted) _show('Versión restaurada.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _reset() async {
    setState(() => _saving = true);
    try {
      await widget.onReset();
      if (mounted) _show('Configuración de fábrica activada.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _show(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  static String _nextPatch(String current) {
    final List<int?> parts = current.split('.').map(int.tryParse).toList();
    if (parts.length != 3 || parts.any((int? p) => p == null)) {
      return '1.0.1';
    }
    return '${parts[0]}.${parts[1]}.${parts[2]! + 1}';
  }
}
