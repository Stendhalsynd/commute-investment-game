import '../../domain/models/game_state.dart';
import '../interfaces/session_repository.dart';

class InMemorySessionRepository implements ISessionRepository {
  final Map<String, GameState> _cache = {};

  @override
  Future<GameState?> load(String playerId) async {
    return _cache[playerId];
  }

  @override
  Future<void> save(GameState state) async {
    _cache[state.playerId] = state;
  }

  @override
  Future<void> archive(String playerId) async {
    _cache.remove(playerId);
  }
}
