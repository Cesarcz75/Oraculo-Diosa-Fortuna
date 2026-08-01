
import 'dart:isolate';
import 'models.dart';
import 'statistical_engine.dart';

class RankingRequest {
  const RankingRequest({
    required this.history,
    required this.latestDraw,
    required this.topN,
    required this.replyPort,
  });

  final List<List<int>> history;
  final List<int> latestDraw;
  final int topN;
  final SendPort replyPort;
}

Future<void> rankingWorker(RankingRequest request) async {
  try {
    final engine = StatisticalEngine(request.history);
    final ranking = engine.rankTop(
      latestDraw: request.latestDraw,
      topN: request.topN,
      onProgress: (done, total) {
        request.replyPort.send({
          'type': 'progress',
          'done': done,
          'total': total,
        });
      },
    );

    request.replyPort.send({
      'type': 'result',
      'items': ranking.map((item) => {
        'numbers': item.numbers,
        'score': item.score,
        'sum': item.sum,
        'evens': item.evens,
        'repeated': item.repeated,
      }).toList(),
    });
  } catch (error, stack) {
    request.replyPort.send({
      'type': 'error',
      'message': error.toString(),
      'stack': stack.toString(),
    });
  }
}

RankedCombination rankedCombinationFromMap(Map<dynamic, dynamic> map) {
  return RankedCombination(
    numbers: List<int>.from(map['numbers'] as List),
    score: (map['score'] as num).toDouble(),
    sum: map['sum'] as int,
    evens: map['evens'] as int,
    repeated: map['repeated'] as int,
  );
}
