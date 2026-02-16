import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../analytics/interfaces/analytics_sink.dart';
import '../data/interfaces/session_repository.dart';
import '../domain/interfaces/investment_engine.dart';
import '../domain/models/game_flow_state.dart';
import '../domain/models/game_state.dart';
import '../domain/services/investment_engine.dart';
import 'game_session.dart';

class GameNotifier extends StateNotifier<GameSession> {
  final String playerId;
  final ISessionRepository repository;
  final IAnalyticsSink analyticsSink;
  late IInvestmentEngine _engine;
  Stopwatch? _roundStopwatch;

  GameNotifier({
    required this.playerId,
    required this.repository,
    required this.analyticsSink,
  }) : super(GameSession.loading()) {
    unawaited(_initialize());
  }

  Future<void> _initialize() async {
    try {
      state = state.copyWith(isLoading: true, isBusy: false, statusMessage: '불러오는 중');
      final loaded = await repository.load(playerId);
      final initial = loaded ?? GameState.initial(playerId: playerId);
      _engine = DefaultInvestmentEngine(playerId: playerId, initialState: initial);

      state = _withEngine();
      _ensureRoundStarted();
      await _persist();
      state = state.copyWith(
        isLoading: false,
        isReady: true,
        isBusy: false,
        clearError: true,
        statusMessage: '라운드 준비 완료',
      );
    } catch (error, stack) {
      state = state.copyWith(
        isLoading: false,
        isReady: false,
        isBusy: false,
        error: '초기화 실패: $error',
        statusMessage: '초기화 실패',
      );
      analyticsSink.trackError('game_init_failure', {
        'error': '$error',
        'stack': '$stack',
      });
    }
  }

  void _ensureRoundStarted() {
    final flow = _engine.state;
    if (flow == GameFlowState.READY || flow == GameFlowState.IDLE) {
      final currentDay = _engine.snapshot().day;
      _startRoundTimer();
      _engine.startRound(currentDay);
    }
    state = _withEngine();
  }

  GameSession _withEngine() {
    final snapshot = _engine.snapshot();
    return state.copyWith(
      gameState: snapshot,
      currentEvent: _engine.currentEvent(),
      currentOptions: _engine.currentOptions(),
    );
  }

  Future<void> _persist() async {
    try {
      await repository.save(_engine.snapshot());
    } catch (error, stack) {
      analyticsSink.trackError('game_persist_failure', {
        'error': '$error',
        'stack': '$stack',
      });
    }
  }

  void _startRoundTimer() {
    _roundStopwatch?.stop();
    _roundStopwatch = Stopwatch()..start();
  }

  Future<void> chooseAndResolve(String optionId) async {
    try {
      state = state.copyWith(isBusy: true, clearError: true);
      _engine.choose(optionId);
      final roundDurationMs = _roundStopwatch?.elapsedMilliseconds;
      final result = _engine.resolve();
      _roundStopwatch?.stop();

      state = _withEngine();
      state = state.copyWith(
        isBusy: false,
        lastResult: result,
        statusMessage: '결과 계산 완료',
        lastRoundMs: roundDurationMs,
      );

      await _persist();

      analyticsSink.trackEvent('round_resolved', {
        'roundId': result.roundId,
        'playerId': result.after.playerId,
        'profitLoss': result.profitLoss,
        'roundDurationMs': roundDurationMs ?? 0,
      });
    } on StateError catch (error) {
      state = state.copyWith(
        isBusy: false,
        error: '행동이 허용되지 않습니다: $error',
        statusMessage: '실행 실패',
      );
      analyticsSink.trackError('game_state_error', {
        'error': '$error',
        'optionId': optionId,
      });
    } on ArgumentError catch (error) {
      state = state.copyWith(
        isBusy: false,
        error: '선택이 잘못됐습니다: $error',
        statusMessage: '실행 실패',
      );
      analyticsSink.trackError('game_input_error', {
        'error': '$error',
        'optionId': optionId,
      });
    } catch (error, stack) {
      state = state.copyWith(
        isBusy: false,
        error: '예기치 못한 오류: $error',
        statusMessage: '실행 실패',
      );
      _roundStopwatch?.stop();
      analyticsSink.trackError('game_unknown_error', {
        'error': '$error',
        'stack': '$stack',
      });
    }
  }

  Future<void> proceedNextRound() async {
    try {
      state = state.copyWith(isBusy: true, clearError: true);

      if (_engine.state == GameFlowState.POST_REVIEW) {
        final nextDay = _engine.snapshot().day + 1;
        _startRoundTimer();
        _engine.startRound(nextDay);
        state = state.copyWith(
          lastResult: null,
          lastRoundMs: null,
          statusMessage: '다음 라운드 준비',
        );
        state = _withEngine();
        await _persist();
      } else {
        throw StateError('다음 라운드는 결과 화면에서만 진행할 수 있습니다.');
      }
    } on StateError catch (error) {
      state = state.copyWith(
        isBusy: false,
        error: '$error',
        statusMessage: '진행 실패',
      );
      analyticsSink.trackError('round_transition_error', {'error': '$error'});
    } finally {
      state = state.copyWith(isBusy: false);
    }
  }
}
