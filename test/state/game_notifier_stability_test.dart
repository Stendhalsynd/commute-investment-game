import 'package:flutter_test/flutter_test.dart';

import 'package:commute_investment_game/analytics/interfaces/analytics_sink.dart';
import 'package:commute_investment_game/data/repositories/memory_session_repository.dart';
import 'package:commute_investment_game/domain/state/game_flow_state.dart';
import 'package:commute_investment_game/state/game_notifier.dart';

class _CapturingAnalyticsSink implements IAnalyticsSink {
  final List<String> events = [];
  final List<String> errors = [];

  @override
  void trackEvent(String name, Map<String, Object?> payload) {
    events.add(name);
  }

  @override
  void trackError(String code, Map<String, Object?> context) {
    errors.add(code);
  }
}

Future<void> _awaitFlowState(
  GameNotifier notifier,
  GameFlowState expected, {
  int timeoutMs = 2000,
}) async {
  final end = DateTime.now().add(Duration(milliseconds: timeoutMs));

  while (notifier.state.gameState.flowState != expected ||
      notifier.state.isLoading ||
      notifier.state.isBusy) {
    if (DateTime.now().isAfter(end)) {
      fail('Timed out while waiting for $expected');
    }
    await Future<void>.delayed(const Duration(milliseconds: 5));
  }
}

String _selectAffordableOptionId(GameNotifier notifier) {
  final options = notifier.state.currentOptions
      .where((option) => option.cost <= notifier.state.gameState.cash)
      .toList();

  if (options.isEmpty) {
    fail('No affordable options found for cash ${notifier.state.gameState.cash}');
  }

  return options.first.id;
}

void main() {
  group('GameNotifier stability and recovery', () {
    test('10-round start->choose->resolve->next round loop runs without state errors', () async {
      final analytics = _CapturingAnalyticsSink();
      final notifier = GameNotifier(
        playerId: 'player-qa-stability',
        repository: InMemorySessionRepository(),
        analyticsSink: analytics,
      );

      await _awaitFlowState(notifier, GameFlowState.CHOICE);

      for (var i = 0; i < 10; i++) {
        final optionId = _selectAffordableOptionId(notifier);
        await notifier.chooseAndResolve(optionId);

        await _awaitFlowState(notifier, GameFlowState.POST_REVIEW);
        expect(notifier.state.lastResult, isNotNull);
        expect(notifier.state.lastRoundMs, isNotNull);
        expect(notifier.state.lastRoundMs, lessThan(90000));
        expect(notifier.state.error, isNull);
        expect(notifier.state.statusMessage, contains('결과'));

        if (i < 9) {
          await notifier.proceedNextRound();
          await _awaitFlowState(notifier, GameFlowState.CHOICE);
          expect(notifier.state.lastResult, isNull);
        }
      }

      expect(notifier.state.gameState.day, equals(10));
      expect(notifier.state.error, isNull);
      expect(analytics.events, everyElement('round_resolved'));
      expect(analytics.events, hasLength(10));
      expect(analytics.errors, isEmpty);
    });

    test('restores latest state on restart and continues next round', () async {
      final repository = InMemorySessionRepository();
      final sharedPlayerId = 'player-qa-restore';
      final firstRun = GameNotifier(
        playerId: sharedPlayerId,
        repository: repository,
        analyticsSink: const NoopAnalyticsSink(),
      );

      await _awaitFlowState(firstRun, GameFlowState.CHOICE);
      final optionId = _selectAffordableOptionId(firstRun);
      await firstRun.chooseAndResolve(optionId);
      await _awaitFlowState(firstRun, GameFlowState.POST_REVIEW);

      final xpAfterRound = firstRun.state.gameState.xp;
      final streakAfterRound = firstRun.state.gameState.streak;
      final dayAfterRound = firstRun.state.gameState.day;
      expect(firstRun.state.lastResult, isNotNull);

      final restarted = GameNotifier(
        playerId: sharedPlayerId,
        repository: repository,
        analyticsSink: const NoopAnalyticsSink(),
      );

      await _awaitFlowState(restarted, GameFlowState.POST_REVIEW);
      expect(restarted.state.gameState.day, equals(dayAfterRound));
      expect(restarted.state.gameState.xp, equals(xpAfterRound));
      expect(restarted.state.gameState.streak, equals(streakAfterRound));
      expect(restarted.state.gameState.flowState, equals(GameFlowState.POST_REVIEW));
      expect(restarted.state.lastResult, isNull);

      await restarted.proceedNextRound();
      await _awaitFlowState(restarted, GameFlowState.CHOICE);
      expect(restarted.state.gameState.day, equals(dayAfterRound + 1));
    });
  });
}
