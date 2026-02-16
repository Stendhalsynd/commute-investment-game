import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

import 'package:commute_investment_game/domain/state/game_flow_state.dart';
import 'package:commute_investment_game/domain/models/game_state.dart';
import 'package:commute_investment_game/domain/interfaces/investment_engine.dart';
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

    test('speed scenario mode sets scenario context and insight', () {
      final engine = DefaultInvestmentEngine(
        playerId: 'p1',
        initialState: GameState.initial(playerId: 'p1'),
        random: Random(1),
      );

      engine.startRound(
        1,
        scenarioMode: InvestmentScenarioMode.speedScenario,
      );
      expect(engine.currentScenarioMode, equals(InvestmentScenarioMode.speedScenario));
      expect(engine.currentScenarioId(), isNotNull);
      expect(engine.currentScenarioId(), isNotEmpty);
      expect(engine.currentEvent(), isNotNull);
      final option = engine.currentOptions().first;

      engine.choose(option.id);
      final result = engine.resolve();

      expect(result.scenarioMode, equals('speedScenario'));
      expect(result.scenarioId, isNotNull);
      expect(result.scenarioId, isNotEmpty);
      expect(result.insight.trim(), isNotEmpty);
    });

    test('hold from choice keeps assets and marks round skipped', () {
      final engine = DefaultInvestmentEngine(
        playerId: 'p1',
        initialState: GameState.initial(playerId: 'p1'),
        random: Random(1),
      );

      engine.startRound(1);
      final before = engine.snapshot();
      final result = engine.hold();

      expect(result.scenarioMode, equals(InvestmentScenarioMode.realTime.name));
      expect(result.xpDelta, equals(0));
      expect(result.profitLoss, equals(0));
      expect(result.reason, contains('관망'));
      expect(engine.state, equals(GameFlowState.POST_REVIEW));
      expect(engine.snapshot().flowState, equals(GameFlowState.POST_REVIEW));
      expect(engine.snapshot().cash, equals(before.cash));
      expect(engine.snapshot().mission, isNull);
    });

    test('support-beginner hold policy gives positive xp reward', () {
      final engine = DefaultInvestmentEngine(
        playerId: 'p1',
        initialState: GameState.initial(playerId: 'p1'),
        random: Random(1),
      );

      engine.setHoldPolicy(HoldPolicy.supportBeginner);
      engine.startRound(1);
      final result = engine.hold();

      expect(result.xpDelta, equals(2));
      expect(engine.snapshot().xp, equals(2));
    });

    test('punish-hesitation hold policy applies gentle penalty', () {
      final initial = GameState.initial(playerId: 'p1').copyWith(
        xp: 10,
        clearMission: true,
      );
      final engine = DefaultInvestmentEngine(
        playerId: 'p1',
        initialState: initial,
        random: Random(1),
      );

      engine.setHoldPolicy(HoldPolicy.punishHesitation);
      engine.startRound(3);
      final result = engine.hold();

      expect(result.xpDelta, equals(-2));
      expect(engine.snapshot().xp, equals(8));
    });
  });
}
