import 'dart:math';

import '../state/game_flow_state.dart';
import '../models/game_state.dart';
import '../models/investment_option.dart';
import '../models/market_event.dart';
import '../models/risk_profile.dart';
import '../models/round_result.dart';
import '../interfaces/investment_engine.dart';

class DefaultInvestmentEngine implements IInvestmentEngine {
  final String playerId;
  final List<InvestmentOption> optionPool;
  final List<MarketEvent> eventPool;

  final Random _random;
  late GameState _state;
  late GameState _previousState;
  late List<InvestmentOption> _currentOptions;
  InvestmentOption? _chosenOption;
  MarketEvent? _currentEvent;
  InvestmentScenarioMode _scenarioMode = InvestmentScenarioMode.realTime;
  HoldPolicy _holdPolicy = HoldPolicy.flat;
  String? _currentScenarioId;
  int _roundCounter = 0;

  DefaultInvestmentEngine({
    required this.playerId,
    required GameState initialState,
    Random? random,
    List<InvestmentOption>? optionPoolOverride,
    List<MarketEvent>? eventPoolOverride,
  })  : _state = initialState,
        _previousState = initialState,
        _currentOptions = const [],
        _random = random ?? Random(),
        optionPool = optionPoolOverride ?? _defaultOptions,
        eventPool = eventPoolOverride ?? _defaultEvents;

  static const List<InvestmentOption> _defaultOptions = [
    InvestmentOption(
      id: 'gov_bond',
      name: '단기 국채',
      category: '채권',
      expectedReturn: 2.0,
      volatility: 3.0,
      cost: 400.0,
      cooldownSec: 30,
      riskLevel: 1,
    ),
    InvestmentOption(
      id: 'tech_etf',
      name: '테크 ETF',
      category: 'ETF',
      expectedReturn: 5.0,
      volatility: 9.0,
      cost: 700.0,
      cooldownSec: 45,
      riskLevel: 3,
    ),
    InvestmentOption(
      id: 'crypto_pool',
      name: '암호화폐 풀',
      category: '디지털자산',
      expectedReturn: 10.0,
      volatility: 16.0,
      cost: 1000.0,
      cooldownSec: 60,
      riskLevel: 5,
    ),
  ];

  static const List<MarketEvent> _defaultEvents = [
    MarketEvent(
      id: 'stable',
      title: '안정권',
      description: '금융 시장이 비교적 안정적입니다.',
      impactMin: -1.0,
      impactMax: 1.5,
      appliesTo: ['채권', 'ETF', '디지털자산'],
      duration: 1,
      rarity: 'common',
      scenarioType: 'base',
    ),
    MarketEvent(
      id: 'rush',
      title: '단기 급등',
      description: '특정 업종 뉴스로 변동성이 커집니다.',
      impactMin: -3.0,
      impactMax: 5.0,
      appliesTo: ['ETF', '디지털자산'],
      duration: 1,
      rarity: 'rare',
      scenarioType: 'base',
      historicalTag: '단기 모멘텀',
    ),
    MarketEvent(
      id: 'panic',
      title: '급락 이슈',
      description: '거시 변수로 투자심리가 약해집니다.',
      impactMin: -8.0,
      impactMax: 0.0,
      appliesTo: ['채권', 'ETF', '디지털자산'],
      duration: 1,
      rarity: 'uncommon',
      scenarioType: 'base',
      historicalTag: '위험 회피 국면',
    ),
  ];

  static const List<String> _speedScenarioOrder = [
    'inflation_shock',
    'rate_hike',
    'dotcom_bubble',
    'recovery',
  ];

  static const List<String> _dailyChallengeOrder = [
    'today_news',
    'yesterday_rally',
    'credit_tightening',
    'fiscal_stimulus',
  ];

  static const Map<String, List<MarketEvent>> _scenarioEventCatalog = {
    'inflation_shock': [
      MarketEvent(
        id: 'inflation_shock',
        title: '인플레이션 쇼크',
        description: '물가 상승으로 금리 기대치가 급히 상향됩니다.',
        impactMin: -6.0,
        impactMax: -2.0,
        appliesTo: ['채권', 'ETF', '디지털자산'],
        duration: 1,
        rarity: 'scenario',
        scenarioType: 'inflation',
        historicalTag: '1970s_inflation',
        isSynthetic: true,
      ),
    ],
    'rate_hike': [
      MarketEvent(
        id: 'rate_hike',
        title: '급격한 금리 인상',
        description: '금리 상승으로 성장주 부담이 커집니다.',
        impactMin: -7.0,
        impactMax: -3.0,
        appliesTo: ['ETF', '디지털자산'],
        duration: 1,
        rarity: 'scenario',
        scenarioType: 'rates',
        historicalTag: '2020s_rate_hike',
        isSynthetic: true,
      ),
    ],
    'dotcom_bubble': [
      MarketEvent(
        id: 'dotcom_bubble',
        title: '닷컴 과열기',
        description: '기술주 과열이 정점을 지나며 급격히 조정됩니다.',
        impactMin: -12.0,
        impactMax: 4.0,
        appliesTo: ['ETF', '디지털자산'],
        duration: 1,
        rarity: 'scenario',
        scenarioType: 'history',
        historicalTag: 'dotcom_bubble',
        isSynthetic: true,
      ),
    ],
    'recovery': [
      MarketEvent(
        id: 'recovery',
        title: '완만한 회복 국면',
        description: '유동성이 회복되며 위험자산이 반등 신호를 보입니다.',
        impactMin: 1.0,
        impactMax: 7.0,
        appliesTo: ['채권', 'ETF', '디지털자산'],
        duration: 1,
        rarity: 'scenario',
        scenarioType: 'recovery',
        historicalTag: 'policy_turn',
        isSynthetic: true,
      ),
    ],
    'today_news': [
      MarketEvent(
        id: 'today_news',
        title: '브리핑: AI 반도체 특급 호재',
        description: '오늘 뉴스가 특정 섹터를 빠르게 지지합니다.',
        impactMin: -2.0,
        impactMax: 6.0,
        appliesTo: ['ETF', '디지털자산'],
        duration: 1,
        rarity: 'daily',
        scenarioType: 'daily',
        historicalTag: 'today_headline',
        isSynthetic: true,
      ),
    ],
    'yesterday_rally': [
      MarketEvent(
        id: 'yesterday_rally',
        title: '전일 랠리 흔적',
        description: '상승 연속 이후 변동성이 높지만 추세는 완만합니다.',
        impactMin: -1.0,
        impactMax: 5.0,
        appliesTo: ['채권', 'ETF', '디지털자산'],
        duration: 1,
        rarity: 'daily',
        scenarioType: 'daily',
        historicalTag: 'morning_gap',
        isSynthetic: true,
      ),
    ],
    'credit_tightening': [
      MarketEvent(
        id: 'credit_tightening',
        title: '신용 경색 신호',
        description: '신규 자금 유입이 둔화되어 성장주에 압박이 큽니다.',
        impactMin: -9.0,
        impactMax: -1.0,
        appliesTo: ['ETF', '디지털자산'],
        duration: 1,
        rarity: 'daily',
        scenarioType: 'daily',
        historicalTag: 'liquidity_shrink',
        isSynthetic: true,
      ),
    ],
    'fiscal_stimulus': [
      MarketEvent(
        id: 'fiscal_stimulus',
        title: '완화 정책 기대',
        description: '재정 완화 전망으로 채권 쪽 안정성이 높아집니다.',
        impactMin: 0.5,
        impactMax: 4.5,
        appliesTo: ['채권', 'ETF'],
        duration: 1,
        rarity: 'daily',
        scenarioType: 'daily',
        historicalTag: 'fiscal_cycle',
        isSynthetic: true,
      ),
    ],
  };

  @override
  void startRound(
    int day, {
    RiskProfile? overrideProfile,
    InvestmentScenarioMode? scenarioMode,
    String? scenarioId,
  }) {
    if (_state.flowState == GameFlowState.SIMULATE ||
        _state.flowState == GameFlowState.CHOICE ||
        _state.flowState == GameFlowState.RESULT) {
      throw StateError('Round can only start from IDLE, READY, or POST_REVIEW');
    }

    _previousState = _state;
    _roundCounter++;
    _scenarioMode = scenarioMode ?? InvestmentScenarioMode.realTime;
    _currentScenarioId = _resolveScenarioId(day, _scenarioMode, scenarioId);
    final profile = overrideProfile ?? _state.riskProfile;
    final nextMission = day > _state.day ? 'first_choice' : _state.mission;
    _currentOptions = _generateOptions(profile);
    _currentEvent = _selectEvent(day, _scenarioMode, _currentScenarioId);
    _chosenOption = null;
    _state = _state.copyWith(
      day: day,
      riskProfile: profile,
      flowState: GameFlowState.CHOICE,
      lastPlayedAt: DateTime.now(),
      mission: nextMission,
    );
  }

  @override
  void setHoldPolicy(HoldPolicy policy) {
    _holdPolicy = policy;
  }

  @override
  void choose(String optionId) {
    if (_state.flowState != GameFlowState.CHOICE) {
      throw StateError('choose() is only allowed during CHOICE state');
    }
    final option = _currentOptions.firstWhere(
      (it) => it.id == optionId,
      orElse: () => throw ArgumentError('Invalid optionId: $optionId'),
    );
    _chosenOption = option;
    _state = _state.copyWith(flowState: GameFlowState.SIMULATE);
  }

  @override
  RoundResult resolve() {
    if (_state.flowState != GameFlowState.SIMULATE) {
      throw StateError('resolve() is only allowed during SIMULATE state');
    }
    if (_chosenOption == null) {
      throw StateError('No option chosen');
    }

    final option = _chosenOption!;
    if (_state.cash < option.cost) {
      throw StateError('Not enough cash');
    }

    final event = _currentEvent!;
    final volatility = (_random.nextDouble() * 2 - 1) * option.volatility;
    final eventImpact = _sampleEventImpact();
    final categoryBonus = event.appliesTo.contains(option.category) ? 1.0 : 0.85;
    final expectedRate = option.expectedReturn / 100.0;
    final resultRate = (expectedRate + volatility / 100.0 + eventImpact / 100.0) *
        categoryBonus;
    final clampedRate = resultRate.clamp(-0.75, 2.0);
    final profitLoss = option.cost * clampedRate;
    final xpDelta = profitLoss >= 0 ? 10 : 5;

    final before = _state;
    final missionReward = before.mission != null ? 5 : 0;
    final updatedPortfolio = Map<String, double>.from(_state.portfolio)
      ..update(
        option.id,
        (old) => old + option.cost,
        ifAbsent: () => option.cost,
      );
    final after = _state.copyWith(
      flowState: GameFlowState.RESULT,
      cash: _state.cash - option.cost + option.cost + profitLoss,
      streak: profitLoss >= 0 ? _state.streak + 1 : 0,
      xp: _state.xp + xpDelta + missionReward,
      portfolio: updatedPortfolio,
      clearMission: true,
    );

    final insight = _buildInsight(
      option: option,
      event: event,
      resultRate: clampedRate,
      missionCompleted: missionReward > 0,
      profitLoss: profitLoss,
    );
    final reason = _buildReason(option, event, clampedRate, missionReward > 0);
    final result = RoundResult(
      roundId: 'round-$_roundCounter',
      before: before,
      after: after,
      profitLoss: profitLoss,
      xpDelta: xpDelta + missionReward,
      reason: reason,
      insight: insight,
      scenarioMode: _scenarioMode.name,
      scenarioId: _currentScenarioId,
      timeStamp: DateTime.now(),
    );
    _state = after.copyWith(flowState: GameFlowState.POST_REVIEW);
    _previousState = before;
    return result;
  }

  @override
  RoundResult hold() {
    if (_state.flowState != GameFlowState.CHOICE) {
      throw StateError('hold() is only allowed during CHOICE state');
    }

    final event = _currentEvent!;
    final before = _state;
    final holdXpDelta = _calcHoldXpDelta(before);
    final after = _state.copyWith(
      flowState: GameFlowState.RESULT,
      clearMission: true,
      xp: max(0, _state.xp + holdXpDelta),
    );

    final result = RoundResult(
      roundId: 'round-$_roundCounter',
      before: before,
      after: after,
      profitLoss: 0,
      xpDelta: holdXpDelta,
      reason: _buildHoldReason(event),
      insight: _buildHoldInsight(event),
      scenarioMode: _scenarioMode.name,
      scenarioId: _currentScenarioId,
      timeStamp: DateTime.now(),
    );
    _state = after.copyWith(flowState: GameFlowState.POST_REVIEW);
    _previousState = before;
    return result;
  }

  double _sampleEventImpact() {
    final event = _currentEvent!;
    if (event.impactMax == event.impactMin) return event.impactMin;
    return event.impactMin +
        (event.impactMax - event.impactMin) * _random.nextDouble();
  }

  List<InvestmentOption> _generateOptions(RiskProfile profile) {
    final options = optionPool.where((option) {
      if (profile == RiskProfile.conservative) {
        return option.riskLevel <= 2;
      }
      if (profile == RiskProfile.balanced) {
        return option.riskLevel <= 4;
      }
      return true;
    }).toList();

    if (options.length <= 3) return options;
    options.shuffle(_random);
    return options.take(3).toList();
  }

  MarketEvent _selectEvent(
    int day,
    InvestmentScenarioMode scenarioMode,
    String? scenarioId,
  ) {
    final scenarioEvent = _getScenarioEvent(scenarioId);
    if (scenarioEvent != null) return scenarioEvent;

    switch (scenarioMode) {
      case InvestmentScenarioMode.speedScenario:
        return _pickSpeedScenario(day);
      case InvestmentScenarioMode.dailyChallenge:
        return _pickDailyChallenge(day);
      case InvestmentScenarioMode.realTime:
      default:
        return _pickEvent();
    }
  }

  String? _resolveScenarioId(
    int day,
    InvestmentScenarioMode mode,
    String? overrideId,
  ) {
    if (overrideId != null) return overrideId;

    if (mode == InvestmentScenarioMode.speedScenario) {
      return _speedScenarioOrder[
          (day - 1).clamp(0, 1000000) % _speedScenarioOrder.length];
    }

    if (mode == InvestmentScenarioMode.dailyChallenge) {
      return _dailyChallengeOrder[
          (day - 1).clamp(0, 1000000) % _dailyChallengeOrder.length];
    }

    return null;
  }

  MarketEvent? _getScenarioEvent(String? scenarioId) {
    if (scenarioId == null) return null;
    final candidate = _scenarioEventCatalog[scenarioId];
    if (candidate == null || candidate.isEmpty) return null;
    return candidate[_random.nextInt(candidate.length)];
  }

  MarketEvent _pickSpeedScenario(int day) {
    final key = _speedScenarioOrder[
        (day - 1).clamp(0, 1000000) % _speedScenarioOrder.length];
    return _getScenarioEvent(key)!;
  }

  MarketEvent _pickDailyChallenge(int day) {
    final key = _dailyChallengeOrder[
        (day - 1).clamp(0, 1000000) % _dailyChallengeOrder.length];
    return _getScenarioEvent(key)!;
  }

  MarketEvent _pickEvent() {
    final index = _random.nextInt(eventPool.length);
    return eventPool[index];
  }

  String _buildReason(
    InvestmentOption option,
    MarketEvent event,
    double rate,
    bool missionCompleted,
  ) {
    final percent = (rate * 100).toStringAsFixed(1);
    final missionPart = missionCompleted ? ' · 일일 미션 보너스 반영' : '';
    final tag = event.historicalTag != null ? ' (${event.historicalTag})' : '';
    return '${event.title}$tag 영향: ${percent}% 반영, ${option.name} 선택$missionPart';
  }

  String _buildHoldReason(MarketEvent event) {
    final tag = event.historicalTag != null ? ' (${event.historicalTag})' : '';
    return '${event.title}$tag 국면에서 관망으로 라운드를 마칩니다.';
  }

  String _buildInsight({
    required InvestmentOption option,
    required MarketEvent event,
    required double resultRate,
    required bool missionCompleted,
    required double profitLoss,
  }) {
    final direction = profitLoss >= 0 ? '수익' : '손실';
    final scenario = (event.historicalTag ?? event.scenarioType ?? '현재 시장')
        .replaceAll('_', ' ');
    final riskTone = option.riskLevel >= 4
        ? '공격형'
        : option.riskLevel >= 3
            ? '균형형'
            : '보수형';
    final trendTone = resultRate >= 0.0 ? '상승' : '약세';
    final missionHint = missionCompleted ? ' 첫 선택 보너스 적용.' : '';
    final categoryTone = event.appliesTo.contains(option.category) ? '호재' : '중립';
    return '$scenario 국면에서 $riskTone 선택이 ${categoryTone}로 반응해 $trendTone 쪽 $direction으로 이어졌습니다.$missionHint'
        .trim();
  }

  String _buildHoldInsight(MarketEvent event) {
    final scenario = event.historicalTag ?? event.scenarioType ?? '현재 시장';
    return '$scenario 국면에서 즉시 매수 대신 관망해 변동성 진입을 늦춰 손실 확산을 줄였습니다.';
  }

  int _calcHoldXpDelta(GameState before) {
    switch (_holdPolicy) {
      case HoldPolicy.flat:
        return 0;
      case HoldPolicy.supportBeginner:
        return before.mission != null ? 2 : 1;
      case HoldPolicy.punishHesitation:
        return before.day <= 2 ? 0 : -2;
    }
  }

  @override
  GameState snapshot() => _state;

  @override
  GameFlowState get state => _state.flowState;

  @override
  InvestmentScenarioMode get currentScenarioMode => _scenarioMode;

  @override
  HoldPolicy get currentHoldPolicy => _holdPolicy;

  @override
  String? currentScenarioId() => _currentScenarioId;

  @override
  List<InvestmentOption> currentOptions() => List.unmodifiable(_currentOptions);

  @override
  MarketEvent? currentEvent() => _currentEvent;
}
