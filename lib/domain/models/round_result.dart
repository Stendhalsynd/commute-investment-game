import 'game_state.dart';

class RoundResult {
  final String roundId;
  final GameState before;
  final GameState after;
  final double profitLoss;
  final int xpDelta;
  final String reason;
  final String insight;
  final String scenarioMode;
  final String? scenarioId;
  final DateTime timeStamp;

  const RoundResult({
    required this.roundId,
    required this.before,
    required this.after,
    required this.profitLoss,
    required this.xpDelta,
    required this.reason,
    required this.insight,
    required this.scenarioMode,
    this.scenarioId,
    required this.timeStamp,
  });

  Map<String, Object?> toMap() {
    return {
      'roundId': roundId,
      'before': before.toMap(),
      'after': after.toMap(),
      'profitLoss': profitLoss,
      'xpDelta': xpDelta,
      'reason': reason,
      'insight': insight,
      'scenarioMode': scenarioMode,
      'scenarioId': scenarioId,
      'timeStamp': timeStamp.toIso8601String(),
    };
  }

  factory RoundResult.fromMap(Map<String, dynamic> map) {
    return RoundResult(
      roundId: map['roundId'] as String,
      before: GameState.fromMap(map['before'] as Map<String, dynamic>),
      after: GameState.fromMap(map['after'] as Map<String, dynamic>),
      profitLoss: (map['profitLoss'] as num).toDouble(),
      xpDelta: map['xpDelta'] as int,
      reason: map['reason'] as String,
      insight: map['insight'] as String? ??
          '자동 분석 결과가 아직 준비되지 않았습니다.',
      scenarioMode: map['scenarioMode'] as String? ?? 'realTime',
      scenarioId: map['scenarioId'] as String?,
      timeStamp: DateTime.parse(map['timeStamp'] as String),
    );
  }
}
