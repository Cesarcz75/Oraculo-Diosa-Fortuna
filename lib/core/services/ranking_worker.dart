import 'dart:isolate';
import '../models/ranked_combination.dart';
import 'statistical_engine.dart';

class RankingRequest {
  const RankingRequest({
    required this.history,
    required this.latest,
    required this.topN,
    required this.replyPort,
  });

  final List<List<int>> history;
  final List<int> latest;
  final int topN;
  final SendPort replyPort;
}

Future<void> rankingWorker(RankingRequest request) async {
  try {
    final StatisticalEngine engine = StatisticalEngine(request.history);
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
