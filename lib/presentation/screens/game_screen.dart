import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../state/game_providers.dart';
import '../../domain/interfaces/investment_engine.dart';
import '../../domain/models/investment_option.dart';
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
              _ScenarioModeSelector(
                mode: session.scenarioMode,
                onChanged: notifier.setScenarioMode,
                isEnabled: session.gameState.flowState != GameFlowState.CHOICE &&
                    session.gameState.flowState != GameFlowState.SIMULATE &&
                    session.gameState.flowState != GameFlowState.RESULT,
              ),
              const SizedBox(height: 8),
              _HoldPolicySelector(
                policy: session.holdPolicy,
                onChanged: notifier.setHoldPolicy,
                isEnabled: session.gameState.flowState != GameFlowState.CHOICE &&
                    session.gameState.flowState != GameFlowState.SIMULATE &&
                    session.gameState.flowState != GameFlowState.RESULT,
              ),
              const SizedBox(height: 8),
              _ReviewDensitySelector(
                density: session.reviewDensity,
                onChanged: notifier.setReviewDensity,
                isEnabled:
                    session.gameState.flowState == GameFlowState.POST_REVIEW,
              ),
              const SizedBox(height: 12),
              _EventPanel(session: session),
              const SizedBox(height: 12),
              if (session.lastResult != null &&
                  session.gameState.flowState == GameFlowState.POST_REVIEW)
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
                      return _SwipeOptionCard(
                        option: option,
                        isBusy: session.isBusy,
                        onBuy: () => notifier.chooseAndResolve(option.id),
                        onHold: () {
                          if (!session.isBusy) {
                            HapticFeedback.selectionClick();
                            return notifier.holdCurrentRound();
                          }
                          return Future<void>.value();
                        },
                      );
                    },
                  ),
                ),
              ],
              if (session.isBusy) const LinearProgressIndicator(minHeight: 4),
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

class _ScenarioModeSelector extends StatelessWidget {
  const _ScenarioModeSelector({
    required this.mode,
    required this.onChanged,
    required this.isEnabled,
  });

  final InvestmentScenarioMode mode;
  final ValueChanged<InvestmentScenarioMode> onChanged;
  final bool isEnabled;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      children: InvestmentScenarioMode.values.map((entry) {
        return ChoiceChip(
          label: Text(_scenarioLabel(entry)),
          selected: mode == entry,
          onSelected: isEnabled ? (_) => onChanged(entry) : null,
        );
      }).toList(),
    );
  }
}

class _HoldPolicySelector extends StatelessWidget {
  const _HoldPolicySelector({
    required this.policy,
    required this.onChanged,
    required this.isEnabled,
  });

  final HoldPolicy policy;
  final ValueChanged<HoldPolicy> onChanged;
  final bool isEnabled;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      children: HoldPolicy.values.map((entry) {
        return ChoiceChip(
          label: Text(_holdPolicyLabel(entry)),
          selected: policy == entry,
          onSelected: isEnabled ? (_) => onChanged(entry) : null,
        );
      }).toList(),
    );
  }
}

class _ReviewDensitySelector extends StatelessWidget {
  const _ReviewDensitySelector({
    required this.density,
    required this.onChanged,
    required this.isEnabled,
  });

  final ReviewDensity density;
  final ValueChanged<ReviewDensity> onChanged;
  final bool isEnabled;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      children: ReviewDensity.values.map((entry) {
        return ChoiceChip(
          label: Text(_reviewDensityLabel(entry)),
          selected: density == entry,
          onSelected: isEnabled ? (_) => onChanged(entry) : null,
        );
      }).toList(),
    );
  }
}

class _SwipeOptionCard extends StatefulWidget {
  const _SwipeOptionCard({
    required this.option,
    required this.onBuy,
    required this.onHold,
    required this.isBusy,
  });

  final InvestmentOption option;
  final Future<void> Function() onBuy;
  final Future<void> Function() onHold;
  final bool isBusy;

  @override
  State<_SwipeOptionCard> createState() => _SwipeOptionCardState();
}

class _SwipeOptionCardState extends State<_SwipeOptionCard> {
  static const double _actionThreshold = 78.0;

  double _offsetY = 0.0;
  bool _isBusyAction = false;

  void _handleDragUpdate(DragUpdateDetails details) {
    if (!mounted || widget.isBusy) return;
    setState(() {
      _offsetY += details.primaryDelta ?? 0.0;
      if (_offsetY > 110) _offsetY = 110;
      if (_offsetY < -110) _offsetY = -110;
    });
  }

  void _handleDragEnd(DragEndDetails details) {
    if (!mounted || widget.isBusy) return;

    final triggeredBuy = _offsetY < -_actionThreshold;
    final triggeredHold = _offsetY > _actionThreshold;
    _offsetY = 0;
    if ((triggeredBuy || triggeredHold) && !_isBusyAction) {
      if (triggeredBuy) {
        _isBusyAction = true;
        HapticFeedback.mediumImpact();
        widget.onBuy().whenComplete(() {
          if (!mounted) return;
          _isBusyAction = false;
        });
      } else {
        HapticFeedback.lightImpact();
        _isBusyAction = true;
        widget.onHold().whenComplete(() {
          if (!mounted) return;
          _isBusyAction = false;
        });
      }
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final isBuyAction = _offsetY < 0;
    final isHoldAction = _offsetY > 0;
    final progress = (_offsetY.abs() / 110).clamp(0.0, 1.0);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 120),
      transform: Matrix4.translationValues(0.0, _offsetY, 0.0),
      child: Card(
        elevation: 2,
        child: Stack(
          children: [
            if (isBuyAction && progress > 0.05)
              Positioned.fill(
                child: Align(
                  alignment: Alignment.topCenter,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(
                      '위로 스와이프: 매수',
                      style: TextStyle(
                        color: Colors.red.shade600,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ),
                ),
              ),
            if (isHoldAction && progress > 0.05)
              Positioned.fill(
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      '아래로 스와이프: 보류',
                      style: TextStyle(
                        color: Colors.blue.shade600,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ),
                ),
              ),
            GestureDetector(
              onTap: () {
                if (!widget.isBusy && !_isBusyAction) {
                  _isBusyAction = true;
                  HapticFeedback.mediumImpact();
                  widget.onBuy().whenComplete(() {
                    if (!mounted) return;
                    _isBusyAction = false;
                  });
                }
              },
              onVerticalDragUpdate: _handleDragUpdate,
              onVerticalDragEnd: _handleDragEnd,
              onVerticalDragCancel: () {
                setState(() => _offsetY = 0);
              },
              child: ListTile(
                title: Text(widget.option.name),
                subtitle: Text(
                  '${widget.option.category} · 기대수익 ${widget.option.expectedReturn.toStringAsFixed(1)}% · '
                  '변동성 ${widget.option.volatility.toStringAsFixed(1)}% · 비용 ${widget.option.cost.toStringAsFixed(0)}원',
                ),
                trailing: Text('쿨다운 ${widget.option.cooldownSec}초'),
                selected: isBuyAction || isHoldAction,
                selectedTileColor: isBuyAction
                    ? Colors.red.withOpacity(0.06)
                    : isHoldAction
                        ? Colors.blue.withOpacity(0.06)
                        : null,
                leading: Icon(
                  isBuyAction
                      ? Icons.arrow_upward
                      : isHoldAction
                          ? Icons.arrow_downward
                          : Icons.show_chart,
                  color: isBuyAction
                      ? Colors.red.shade700
                      : isHoldAction
                          ? Colors.blue.shade700
                          : Colors.grey,
                ),
              ),
            ),
          ],
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
    final assetValue = _virtualSavings(game.cash, game.portfolio);
    final target = _homeSavingsTarget(day: game.day, xp: game.xp);
    final progress = (assetValue / target).clamp(0.0, 1.0);

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
            const SizedBox(height: 8),
            Text('내 집 마련 게이지', style: Theme.of(context).textTheme.labelMedium),
            const SizedBox(height: 4),
            LinearProgressIndicator(
              minHeight: 6,
              value: progress,
              backgroundColor: Colors.grey.shade200,
              color: Colors.teal.shade500,
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('현재 ${assetValue.toStringAsFixed(0)}원'),
                Text('목표 ${target.toStringAsFixed(0)}원'),
              ],
            ),
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
    final reviewTooltip = _shortenForTooltip(
      result.insight,
      maxLength: _reviewLength(session.reviewDensity),
    );

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
            const SizedBox(height: 4),
            Tooltip(
              message: result.insight,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.insights,
                    size: 16,
                    color: isProfit ? Colors.red.shade600 : Colors.blue.shade600,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Review: $reviewTooltip',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              'XP ${result.xpDelta >= 0 ? '+' : ''}${result.xpDelta}',
              style: TextStyle(
                color: result.xpDelta >= 0 ? Colors.red.shade700 : Colors.blue.shade700,
                fontWeight: FontWeight.w600,
              ),
            ),
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

String _shortenForTooltip(String text, {int maxLength = 50}) {
  final plain = text.trim();
  if (plain.length <= maxLength) return plain;
  return '${plain.substring(0, maxLength - 1)}…';
}

int _reviewLength(ReviewDensity density) {
  switch (density) {
    case ReviewDensity.compact:
      return 36;
    case ReviewDensity.standard:
      return 50;
    case ReviewDensity.readable:
      return 72;
  }
}

String _scenarioLabel(InvestmentScenarioMode mode) {
  switch (mode) {
    case InvestmentScenarioMode.speedScenario:
      return '스피드 시나리오';
    case InvestmentScenarioMode.dailyChallenge:
      return '데일리 챌린지';
    case InvestmentScenarioMode.realTime:
    default:
      return '실시간';
  }
}

String _holdPolicyLabel(HoldPolicy policy) {
  switch (policy) {
    case HoldPolicy.flat:
      return '보류: 보상 0';
    case HoldPolicy.supportBeginner:
      return '보류: 초보자 보정';
    case HoldPolicy.punishHesitation:
      return '보류: 집중도 강화';
  }
}

String _reviewDensityLabel(ReviewDensity density) {
  switch (density) {
    case ReviewDensity.compact:
      return 'Review 짧게(36)';
    case ReviewDensity.standard:
      return 'Review 기본(50)';
    case ReviewDensity.readable:
      return 'Review 넓게(72)';
  }
}

double _virtualSavings(
  double cash,
  Map<String, double> portfolio,
) {
  final invested = portfolio.values.fold(0.0, (sum, item) => sum + item);
  return cash + invested;
}

double _homeSavingsTarget({
  required int day,
  required int xp,
}) {
  return 12000.0 + (day * 2500.0) + (xp >= 20 ? 5000.0 : 0.0);
}
