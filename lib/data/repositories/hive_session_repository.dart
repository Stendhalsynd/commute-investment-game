import '../../domain/models/game_state.dart';
import '../interfaces/session_repository.dart';

class HiveSessionRepository implements ISessionRepository {
  final Map<String, GameState> _store = {};

  @override
  Future<GameState?> load(String playerId) async {
    return _store[playerId];
  }

  @override
  Future<void> save(GameState state) async {
    _store[state.playerId] = state;
  }

  @override
  Future<void> archive(String playerId) async {
    _store.remove(playerId);
  }
}
