import 'dart:math';

import '../models/game_flow_state.dart';
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
    ),
  ];

  @override
  void startRound(int day, {RiskProfile? overrideProfile}) {
    if (_state.flowState == GameFlowState.SIMULATE ||
        _state.flowState == GameFlowState.CHOICE ||
        _state.flowState == GameFlowState.RESULT ||
        _state.flowState == GameFlowState.POST_REVIEW) {
      // Keep engine strict: must be in IDLE or READY for new round
      if (_state.flowState != GameFlowState.IDLE &&
          _state.flowState != GameFlowState.READY) {
        throw StateError('Round can only start from IDLE or READY');
      }
    }

    _previousState = _state;
    _roundCounter++;
    final profile = overrideProfile ?? _state.riskProfile;
    final nextMission = day > _state.day ? 'first_choice' : _state.mission;
    _currentOptions = _generateOptions(profile);
    _currentEvent = _pickEvent();
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
      mission: null,
    );

    final result = RoundResult(
      roundId: 'round-$_roundCounter',
      before: before,
      after: after,
      profitLoss: profitLoss,
      xpDelta: xpDelta + missionReward,
      reason: _buildReason(option, event, clampedRate, missionReward > 0),
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
    return '${event.title} 영향: ${percent}% 반영, ${option.name} 선택$missionPart';
  }

  @override
  GameState snapshot() => _state;

  @override
  GameFlowState get state => _state.flowState;

  @override
  List<InvestmentOption> currentOptions() => List.unmodifiable(_currentOptions);

  @override
  MarketEvent? currentEvent() => _currentEvent;
}
