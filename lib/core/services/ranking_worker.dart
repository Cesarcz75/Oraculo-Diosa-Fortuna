import 'dart:isolate';
import '../models/ranked_combination.dart';
import '../models/model_config.dart';
import 'statistical_engine.dart';

class RankingRequest {
  const RankingRequest({
    required this.history,
    required this.latest,
    required this.topN,
    required this.replyPort,
    required this.config,
  });

  final List<List<int>> history;
  final List<int> latest;
  final int topN;
  final SendPort replyPort;
  final ModelConfig config;
}

void rankingWorker(RankingRequest request) {
  try {
    final StatisticalEngine engine = StatisticalEngine(request.history, request.config);
    final List<RankedCombination> ranking = engine.rankTop(
      latest: request.latest,
      topN: request.topN,
      onProgress: (int done, int total) {
        request.replyPort.send(<String, Object>{
          'type': 'progress',
          'done': done,
          'total': total,
        });
      },
    );

    request.replyPort.send(<String, Object>{
      'type': 'result',
      'items': ranking
          .map((RankedCombination item) => item.toMap())
          .toList(growable: false),
    });
  } catch (error, stackTrace) {
    request.replyPort.send(<String, Object>{
      'type': 'error',
      'message': error.toString(),
      'stack': stackTrace.toString(),
    });
  }
}
