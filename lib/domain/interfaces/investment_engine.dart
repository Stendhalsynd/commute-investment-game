import '../models/game_state.dart';
import '../models/investment_option.dart';
import '../models/market_event.dart';
import '../models/round_result.dart';
import '../state/game_flow_state.dart';
import '../models/risk_profile.dart';

enum InvestmentScenarioMode {
  realTime,
  speedScenario,
  dailyChallenge,
}

enum HoldPolicy {
  flat,
  supportBeginner,
  punishHesitation,
}

abstract class IInvestmentEngine {
  void startRound(
    int day, {
    RiskProfile? overrideProfile,
    InvestmentScenarioMode? scenarioMode,
    String? scenarioId,
  });
  void setHoldPolicy(HoldPolicy policy);
  void choose(String optionId);
  RoundResult resolve();
  RoundResult hold();
  GameState snapshot();
  InvestmentScenarioMode get currentScenarioMode;
  HoldPolicy get currentHoldPolicy;
  String? currentScenarioId();
  GameFlowState get state;
  List<InvestmentOption> currentOptions();
  MarketEvent? currentEvent();
}
