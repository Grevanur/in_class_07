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

    final play = find.widgetWithText(FilledButton, 'Play');
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
}
