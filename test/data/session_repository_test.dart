import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:commute_investment_game/data/repositories/file_session_repository.dart';
import 'package:commute_investment_game/domain/state/game_flow_state.dart';
import 'package:commute_investment_game/domain/models/game_state.dart';
import 'package:commute_investment_game/domain/models/risk_profile.dart';

void main() {
  group('FileSessionRepository', () {
    test('save/load/archive roundtrip', () async {
      final tmpDir = await Directory.systemTemp.createTemp('commute-game-repo-test-');
      final filePath = '${tmpDir.path}/session.json';

      final repository = FileSessionRepository(filePath: filePath);

      final initial = GameState.initial(
        playerId: 'player-1',
        initialCash: 12000,
        riskProfile: RiskProfile.aggressive,
      );
      await repository.save(initial);

      final loadedFirst = await repository.load('player-1');
      expect(loadedFirst, isNotNull);
      expect(loadedFirst!.playerId, initial.playerId);
      expect(loadedFirst.day, initial.day);
      expect(loadedFirst.cash, initial.cash);
      expect(loadedFirst.flowState, initial.flowState);
      expect(loadedFirst.riskProfile, initial.riskProfile);

      final updated = initial.copyWith(
        day: 2,
        cash: 9800,
        xp: 12,
        streak: 3,
        clearMission: true,
        flowState: GameFlowState.POST_REVIEW,
      );
      await repository.save(updated);

      final loadedSecond = await repository.load('player-1');
      expect(loadedSecond, isNotNull);
      expect(loadedSecond!.day, 2);
      expect(loadedSecond.cash, 9800);
      expect(loadedSecond.xp, 12);
      expect(loadedSecond.streak, 3);
      expect(loadedSecond.flowState, GameFlowState.POST_REVIEW);
      expect(loadedSecond.mission, isNull);
      expect(loadedSecond.riskProfile, RiskProfile.aggressive);

      await repository.archive('player-1');
      final loadedAfterArchive = await repository.load('player-1');
      expect(loadedAfterArchive, isNull);

      await tmpDir.delete(recursive: true);
    });
  });
}
