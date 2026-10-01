import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_class_07/main.dart';

void main() {
  testWidgets('win timer starts only after happiness rises strictly above 80', (
    tester,
  ) async {
    await tester.pumpWidget(
      const DigitalPetApp(
        hungerInterval: Duration(days: 1),
        winDuration: Duration(seconds: 1),
      ),
    );

    final playLabel = find.text('Do Play');
    await tester.scrollUntilVisible(
      playLabel,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    final play = find.widgetWithText(FilledButton, 'Do Play');
    await tester.tap(play);
    await tester.pump();
    await tester.tap(play);
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));
    expect(find.textContaining('You won!'), findsNothing);

    await tester.tap(play);
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.textContaining('You won!'), findsOneWidget);
  });

  testWidgets('selected activity updates pet state and feedback', (
    tester,
  ) async {
    await tester.pumpWidget(
      const DigitalPetApp(hungerInterval: Duration(days: 1)),
    );

    final feed = find.text('🍖 Feed');
    await tester.scrollUntilVisible(
      feed,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(feed);
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, 'Do Feed'));
    await tester.pump();

    expect(find.text('Hunger: 40 / 100'), findsOneWidget);
    expect(find.textContaining('Pip enjoyed the meal'), findsOneWidget);
  });
}
