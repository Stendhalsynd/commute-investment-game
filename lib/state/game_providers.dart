import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../analytics/interfaces/analytics_sink.dart';
import '../data/interfaces/session_repository.dart';
import '../data/repositories/memory_session_repository.dart';
import 'game_notifier.dart';
import 'game_session.dart';

ISessionRepository _createRepository() {
  if (kIsWeb) {
    return InMemorySessionRepository();
  }
  // 네이티브 환경에서만 파일 기반 저장소 시도
  try {
    // dynamic import를 사용할 수 없으므로 InMemory로 폴백
    // TODO: 네이티브 빌드 시 FileSessionRepository 활성화
    return InMemorySessionRepository();
  } catch (_) {
    return InMemorySessionRepository();
  }
}

final sessionRepositoryProvider = Provider<ISessionRepository>((ref) {
  return _createRepository();
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

