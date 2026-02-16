import '../models/game_state.dart';
import '../models/investment_option.dart';
import '../models/market_event.dart';
import '../models/round_result.dart';
import '../state/game_flow_state.dart';
import '../models/risk_profile.dart';

abstract class IInvestmentEngine {
  void startRound(int day, {RiskProfile? overrideProfile});
  void choose(String optionId);
  RoundResult resolve();
  GameState snapshot();
  GameFlowState get state;
  List<InvestmentOption> currentOptions();
  MarketEvent? currentEvent();
}
