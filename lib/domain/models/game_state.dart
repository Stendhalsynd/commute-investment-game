import 'risk_profile.dart';
import '../state/game_flow_state.dart';

class GameState {
  final String playerId;
  final int day;
  final double cash;
  final RiskProfile riskProfile;
  final int xp;
  final int streak;
  final Map<String, double> portfolio;
  final DateTime lastPlayedAt;
  final String? mission;
  final GameFlowState flowState;

  const GameState({
    required this.playerId,
    required this.day,
    required this.cash,
    required this.riskProfile,
    required this.xp,
    required this.streak,
    required this.portfolio,
    required this.lastPlayedAt,
    required this.flowState,
    this.mission,
  });

  factory GameState.initial({
    required String playerId,
    double initialCash = 10000.0,
    RiskProfile riskProfile = RiskProfile.balanced,
  }) {
    return GameState(
      playerId: playerId,
      day: 1,
      cash: initialCash,
      riskProfile: riskProfile,
      xp: 0,
      streak: 0,
      portfolio: const {},
      lastPlayedAt: DateTime.now(),
      flowState: GameFlowState.READY,
      mission: 'first_choice',
    );
  }

  GameState copyWith({
    String? playerId,
    int? day,
    double? cash,
    RiskProfile? riskProfile,
    int? xp,
    int? streak,
    Map<String, double>? portfolio,
    DateTime? lastPlayedAt,
    String? mission,
    bool clearMission = false,
    GameFlowState? flowState,
  }) {
    return GameState(
      playerId: playerId ?? this.playerId,
      day: day ?? this.day,
      cash: cash ?? this.cash,
      riskProfile: riskProfile ?? this.riskProfile,
      xp: xp ?? this.xp,
      streak: streak ?? this.streak,
      portfolio: portfolio ?? this.portfolio,
      lastPlayedAt: lastPlayedAt ?? this.lastPlayedAt,
      mission: clearMission ? null : mission ?? this.mission,
      flowState: flowState ?? this.flowState,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'playerId': playerId,
      'day': day,
      'cash': cash,
      'riskProfile': riskProfile.name,
      'xp': xp,
      'streak': streak,
      'portfolio': portfolio,
      'lastPlayedAt': lastPlayedAt.toIso8601String(),
      'mission': mission,
      'flowState': flowState.name,
    };
  }

  factory GameState.fromMap(Map<String, dynamic> map) {
    return GameState(
      playerId: map['playerId'] as String,
      day: map['day'] as int,
      cash: (map['cash'] as num).toDouble(),
      riskProfile: RiskProfile.values.byName(map['riskProfile'] as String),
      xp: map['xp'] as int,
      streak: map['streak'] as int,
      portfolio: (map['portfolio'] as Map)
          .map((key, value) => MapEntry(key as String, (value as num).toDouble())),
      lastPlayedAt: DateTime.parse(map['lastPlayedAt'] as String),
      mission: map['mission'] as String?,
      flowState: GameFlowState.values.byName(map['flowState'] as String),
    );
  }

}
