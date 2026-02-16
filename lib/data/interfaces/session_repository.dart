import '../../domain/models/game_state.dart';

abstract class ISessionRepository {
  Future<GameState?> load(String playerId);
  Future<void> save(GameState state);
  Future<void> archive(String playerId);
}
