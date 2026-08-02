import 'package:flutter/material.dart';
import '../../core/models/athena_response.dart';
import '../../core/models/model_config.dart';
import '../../core/models/ranked_combination.dart';
import '../../core/services/athena_engine.dart';

class AthenaScreen extends StatefulWidget {
  const AthenaScreen({
    required this.model,
    required this.modelHistory,
    required this.drawHistory,
    required this.ranking,
    super.key,
  });

  final ModelConfig model;
  final List<ModelConfig> modelHistory;
  final List<List<int>> drawHistory;
  final List<RankedCombination> ranking;

  @override
  State<AthenaScreen> createState() => _AthenaScreenState();
}

class _AthenaScreenState extends State<AthenaScreen> {
  static const Color gold = Color(0xFFE8B85A);
  static const Color panel = Color(0xFF1A1022);

  final AthenaEngine _engine = const AthenaEngine();
  final TextEditingController _questionController =
      TextEditingController();
  AthenaResponse? _response;

  @override
  void initState() {
    super.initState();
    _ask('¿Cómo está la salud del modelo?');
  }

  @override
  void dispose() {
    _questionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final List<String> suggestions = _engine.suggestions();

    return ListView(
      padding: const EdgeInsets.all(24),
      children: <Widget>[
        Row(
          children: <Widget>[
            const CircleAvatar(
              radius: 28,
              backgroundColor: Color(0xFF5B1FA3),
              child: Icon(
                Icons.psychology_alt_outlined,
                color: gold,
                size: 30,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'ATHENA · Analista PIT',
                    style:
                        Theme.of(context).textTheme.headlineMedium?.copyWith(
                              color: gold,
                              fontWeight: FontWeight.bold,
                            ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Analiza el Modelo PIT, el histórico y el ranking actual.',
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Card(
          color: panel,
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              children: <Widget>[
                TextField(
                  controller: _questionController,
                  maxLines: 2,
                  textInputAction: TextInputAction.done,
                  onSubmitted: _ask,
                  decoration: const InputDecoration(
                    labelText: 'Pregunta a ATHENA',
                    hintText:
                        'Ejemplo: ¿Cuál regla tiene mayor evidencia?',
                    prefixIcon: Icon(Icons.chat_bubble_outline),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton.icon(
                    onPressed: () => _ask(_questionController.text),
                    icon: const Icon(Icons.send_outlined),
                    label: const Text('ANALIZAR'),
                    style: FilledButton.styleFrom(
                      backgroundColor: gold,
                      foregroundColor: Colors.black,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'CONSULTAS RÁPIDAS',
          style: TextStyle(
            color: gold,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: suggestions
              .map(
                (String suggestion) => ActionChip(
                  avatar: const Icon(Icons.auto_awesome, size: 18),
                  label: Text(suggestion),
                  onPressed: () {
                    _questionController.text = suggestion;
                    _ask(suggestion);
                  },
                ),
              )
              .toList(growable: false),
        ),
        const SizedBox(height: 20),
        if (_response != null) _buildResponse(_response!),
        const SizedBox(height: 18),
        const Card(
          color: panel,
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'ATHENA v1 funciona localmente y responde mediante análisis '
              'determinista de los datos del Oráculo. No consulta internet, '
              'no genera predicciones y no representa probabilidades de ganar.',
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

  Widget _buildResponse(AthenaResponse response) {
    return Card(
      color: panel,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Icon(
                  Icons.insights_outlined,
                  color: gold,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        response.category.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white60,
                          fontSize: 12,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        response.title,
                        style: const TextStyle(
                          color: gold,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              response.summary,
              style: const TextStyle(fontSize: 16),
            ),
            if (response.details.isNotEmpty) ...<Widget>[
              const SizedBox(height: 16),
              ...response.details.map(
                (String detail) => Padding(
                  padding: const EdgeInsets.only(bottom: 9),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      const Padding(
                        padding: EdgeInsets.only(top: 3),
                        child: Icon(
                          Icons.chevron_right,
                          color: gold,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Expanded(child: Text(detail)),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _ask(String question) {
    final String clean = question.trim();
    if (clean.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Escribe una pregunta para ATHENA.'),
        ),
      );
      return;
    }

    final AthenaResponse response = _engine.answer(
      question: clean,
      model: widget.model,
      modelHistory: widget.modelHistory,
      drawHistory: widget.drawHistory,
      ranking: widget.ranking,
    );

    setState(() => _response = response);
  }
}
