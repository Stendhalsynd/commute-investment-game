import 'dart:convert';
import 'dart:io';

import '../../domain/models/game_state.dart';
import '../interfaces/session_repository.dart';

class FileSessionRepository implements ISessionRepository {
  final String filePath;

  FileSessionRepository({
    String? filePath,
  }) : filePath = filePath ??
        '${Directory.systemTemp.path}/commute_investment_game_session.json';

  @override
  Future<GameState?> load(String playerId) async {
    final file = File(filePath);
    if (!await file.exists()) return null;

    final raw = await file.readAsString();
    if (raw.trim().isEmpty) return null;

    final data = jsonDecode(raw);
    if (data is! Map<String, dynamic>) return null;
    final entry = data[playerId];
    if (entry == null) return null;
    if (entry is! Map<String, dynamic>) return null;

    return GameState.fromMap(Map<String, dynamic>.from(entry));
  }

  @override
  Future<void> save(GameState state) async {
    final file = File(filePath);
    final existing = await _loadAll();
    existing[state.playerId] = state.toMap();
    await file.writeAsString(jsonEncode(existing));
  }

  @override
  Future<void> archive(String playerId) async {
    final file = File(filePath);
    if (!await file.exists()) return;

    final existing = await _loadAll();
    if (existing.remove(playerId) != null) {
      await file.writeAsString(jsonEncode(existing));
    }
  }

  Future<Map<String, dynamic>> _loadAll() async {
    final file = File(filePath);
    if (!await file.exists()) return <String, dynamic>{};

    final raw = await file.readAsString();
    if (raw.trim().isEmpty) return <String, dynamic>{};

    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic>) return <String, dynamic>{};
    return Map<String, dynamic>.from(decoded);
  }
}
