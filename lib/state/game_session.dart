import 'package:flutter/foundation.dart';

import '../domain/interfaces/investment_engine.dart';
import '../domain/models/game_state.dart';
import '../domain/models/investment_option.dart';
import '../domain/models/market_event.dart';
import '../domain/models/round_result.dart';

@immutable
class GameSession {
  final bool isLoading;
  final bool isReady;
  final bool isBusy;
  final String? error;
  final GameState gameState;
  final MarketEvent? currentEvent;
  final List<InvestmentOption> currentOptions;
  final RoundResult? lastResult;
  final String statusMessage;
  final int? lastRoundMs;
  final InvestmentScenarioMode scenarioMode;
  final HoldPolicy holdPolicy;
  final ReviewDensity reviewDensity;

  const GameSession({
    required this.isLoading,
    required this.isReady,
    required this.isBusy,
    required this.gameState,
    this.scenarioMode = InvestmentScenarioMode.realTime,
    this.holdPolicy = HoldPolicy.flat,
    this.reviewDensity = ReviewDensity.compact,
    this.currentEvent,
    this.currentOptions = const [],
    this.lastResult,
    this.error,
    this.statusMessage = '',
    this.lastRoundMs,
  });

  factory GameSession.loading() {
    return GameSession(
      isLoading: true,
      isReady: false,
      isBusy: false,
      gameState: GameState.initial(playerId: 'player-1'),
      scenarioMode: InvestmentScenarioMode.realTime,
      holdPolicy: HoldPolicy.flat,
      reviewDensity: ReviewDensity.compact,
    );
  }

  GameSession copyWith({
    bool? isLoading,
    bool? isReady,
    bool? isBusy,
    String? error,
    GameState? gameState,
    MarketEvent? currentEvent,
    List<InvestmentOption>? currentOptions,
    RoundResult? lastResult,
    String? statusMessage,
    int? lastRoundMs,
    InvestmentScenarioMode? scenarioMode,
    HoldPolicy? holdPolicy,
    ReviewDensity? reviewDensity,
    bool clearError = false,
    bool clearLastResult = false,
    bool clearLastRoundMs = false,
  }) {
    return GameSession(
      isLoading: isLoading ?? this.isLoading,
      isReady: isReady ?? this.isReady,
      isBusy: isBusy ?? this.isBusy,
      error: clearError ? null : (error ?? this.error),
      gameState: gameState ?? this.gameState,
      currentEvent: currentEvent ?? this.currentEvent,
      currentOptions: currentOptions ?? this.currentOptions,
      lastResult: clearLastResult ? null : (lastResult ?? this.lastResult),
      statusMessage: statusMessage ?? this.statusMessage,
      scenarioMode: scenarioMode ?? this.scenarioMode,
      holdPolicy: holdPolicy ?? this.holdPolicy,
      reviewDensity: reviewDensity ?? this.reviewDensity,
      lastRoundMs: clearLastRoundMs ? null : (lastRoundMs ?? this.lastRoundMs),
    );
  }
}

enum ReviewDensity {
  compact,
  standard,
  readable,
}
