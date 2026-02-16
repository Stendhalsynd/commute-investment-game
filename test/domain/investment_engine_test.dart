import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

import 'package:commute_investment_game/domain/state/game_flow_state.dart';
import 'package:commute_investment_game/domain/models/game_state.dart';
import 'package:commute_investment_game/domain/services/investment_engine.dart';

void main() {
  group('DefaultInvestmentEngine', () {
    test('startRound moves to CHOICE and exposes options', () {
      final engine = DefaultInvestmentEngine(
        playerId: 'p1',
        initialState: GameState.initial(playerId: 'p1'),
        random: Random(1),
      );

      engine.startRound(1);
      expect(engine.state, equals(GameFlowState.CHOICE));
      expect(engine.currentOptions(), isNotEmpty);
    });

    test('choose invalid option id throws argument error', () {
      final engine = DefaultInvestmentEngine(
        playerId: 'p1',
        initialState: GameState.initial(playerId: 'p1'),
        random: Random(2),
      );

      engine.startRound(1);
      expect(
        () => engine.choose('invalid-id'),
        throwsArgumentError,
      );
    });

    test('resolve generates post-review state and preserves mission bonus once', () {
      final engine = DefaultInvestmentEngine(
        playerId: 'p1',
        initialState: GameState.initial(playerId: 'p1'),
        random: Random(3),
      );
      engine.startRound(1);
      final option = engine.currentOptions().first;
      final beforeXp = engine.snapshot().xp;

      engine.choose(option.id);
      final result = engine.resolve();

      expect(result.xpDelta >= 5, isTrue);
      expect(engine.state, equals(GameFlowState.POST_REVIEW));
      expect(engine.snapshot().xp, greaterThanOrEqualTo(beforeXp + 5));
      expect(engine.snapshot().mission, isNull);
    });

    test('resolve transitions to post-review and keeps streak valid', () {
      final engine = DefaultInvestmentEngine(
        playerId: 'p1',
        initialState: GameState.initial(playerId: 'p1', initialCash: 500),
        random: Random(42),
      );
      engine.startRound(1);
      final option = engine.currentOptions().first;
      engine.choose(option.id);
      final result = engine.resolve();
      final after = engine.snapshot();

      expect(result, isNotNull);
      expect(after.streak, greaterThanOrEqualTo(0));
      expect(after.flowState, equals(GameFlowState.POST_REVIEW));
    });

    test('proceed to next round resets mission to first choice', () {
      final engine = DefaultInvestmentEngine(
        playerId: 'p1',
        initialState: GameState.initial(playerId: 'p1'),
        random: Random(7),
      );
      engine.startRound(1);
      final option = engine.currentOptions().first;
      engine.choose(option.id);
      engine.resolve();

      engine.startRound(2);
      final state = engine.snapshot();
      expect(state.day, equals(2));
      expect(state.mission, equals('first_choice'));
      expect(state.flowState, equals(GameFlowState.CHOICE));
    });
  });
}
