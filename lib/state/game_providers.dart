import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../analytics/interfaces/analytics_sink.dart';
import '../data/interfaces/session_repository.dart';
import '../data/repositories/file_session_repository.dart';
import '../data/repositories/memory_session_repository.dart';
import 'game_notifier.dart';
import 'game_session.dart';

final sessionRepositoryProvider = Provider<ISessionRepository>((ref) {
  // 기본값은 파일 기반 영속 저장소를 사용한다.
  try {
    return FileSessionRepository();
  } catch (_) {
    return InMemorySessionRepository();
  }
});

final analyticsSinkProvider = Provider<IAnalyticsSink>((ref) {
  return const NoopAnalyticsSink();
});

final gameNotifierProvider = StateNotifierProvider<GameNotifier, GameSession>((ref) {
  final repository = ref.watch(sessionRepositoryProvider);
  final analytics = ref.watch(analyticsSinkProvider);
  return GameNotifier(
    playerId: 'player-1',
    repository: repository,
    analyticsSink: analytics,
  );
});
