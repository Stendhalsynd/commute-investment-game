import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:commute_investment_game/main.dart';

void main() {
  testWidgets('게임 앱 기본 화면을 렌더링한다', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: CommuteInvestmentApp(),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('출퇴근길 재테크'), findsOneWidget);
    expect(find.textContaining('DAY'), findsOneWidget);
    expect(find.textContaining('자산'), findsOneWidget);
  });
}
