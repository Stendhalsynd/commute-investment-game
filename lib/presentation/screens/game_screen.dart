import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../state/game_providers.dart';
import '../../domain/state/game_flow_state.dart';
import '../../state/game_session.dart';

class GameScreen extends ConsumerWidget {
  const GameScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(gameNotifierProvider);
    final notifier = ref.read(gameNotifierProvider.notifier);

    if (session.isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('출퇴근길 재테크'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _TopStatusPanel(session: session),
              const SizedBox(height: 12),
              _EventPanel(session: session),
              const SizedBox(height: 12),
              if (session.lastResult != null && session.gameState.flowState == GameFlowState.POST_REVIEW)
                _ResultPanel(
                  session: session,
                  onNext: () => notifier.proceedNextRound(),
                ),
              if (session.gameState.flowState == GameFlowState.CHOICE) ...[
                Text(
                  '선택 가능한 투자 옵션',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: ListView.separated(
                    itemCount: session.currentOptions.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, index) {
                      final option = session.currentOptions[index];
                      return Card(
                        elevation: 2,
                        child: ListTile(
                          title: Text(option.name),
                          subtitle: Text(
                            '${option.category} · 기대수익 ${option.expectedReturn.toStringAsFixed(1)}% · '
                            '변동성 ${option.volatility.toStringAsFixed(1)}% · 비용 ${option.cost.toStringAsFixed(0)}원',
                          ),
                          trailing: Text('쿨다운 ${option.cooldownSec}초'),
                          onTap: session.isBusy
                              ? null
                              : () => notifier.chooseAndResolve(option.id),
                        ),
                      );
                    },
                  ),
                ),
              ],
              if (session.isBusy)
                const LinearProgressIndicator(minHeight: 4),
              if (session.error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    session.error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TopStatusPanel extends StatelessWidget {
  const _TopStatusPanel({required this.session});

  final GameSession session;

  @override
  Widget build(BuildContext context) {
    final game = session.gameState;
    return Card(
      color: Theme.of(context).colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('DAY ${game.day}', style: Theme.of(context).textTheme.titleMedium),
                Text(
                  session.statusMessage,
                  style: Theme.of(context).textTheme.labelMedium,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('자산 ${game.cash.toStringAsFixed(0)}원', style: Theme.of(context).textTheme.titleMedium),
            Text('XP ${game.xp} · 연속 출근 ${game.streak}일'),
            if (session.lastRoundMs != null)
              Text('최근 라운드: ${session.lastRoundMs}ms'),
            if (game.mission != null)
              Text('오늘의 미션: ${game.mission} (첫 선택 시 보너스)'),
            if (game.mission == null)
              const Text('오늘의 미션: 완료'),
          ],
        ),
      ),
    );
  }
}

class _EventPanel extends StatelessWidget {
  const _EventPanel({required this.session});

  final GameSession session;

  @override
  Widget build(BuildContext context) {
    final event = session.currentEvent;
    return Card(
      color: Theme.of(context).colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: event == null
            ? const Text('현재 진행 중인 이벤트 없음')
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(event.title, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text(event.description),
                ],
              ),
      ),
    );
  }
}

class _ResultPanel extends StatelessWidget {
  const _ResultPanel({
    required this.session,
    required this.onNext,
  });

  final GameSession session;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final result = session.lastResult!;
    final profit = result.profitLoss;
    final isProfit = profit >= 0;

    return Card(
      color: Theme.of(context).colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              isProfit ? '이익을 기록했습니다' : '손실이 발생했습니다',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text('손익: ${profit.toStringAsFixed(1)}원'),
            Text(result.reason),
            Text('XP +${result.xpDelta}'),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: onNext,
              child: const Text('다음 라운드'),
            ),
          ],
        ),
      ),
    );
  }
}
