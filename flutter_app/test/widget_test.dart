import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:tamil_handwriting_collector/drawing_canvas.dart';
import 'package:tamil_handwriting_collector/main.dart';
import 'package:tamil_handwriting_collector/tamil_letters.dart';

void main() {
  testWidgets('shows a Tamil letter and a drawing canvas', (WidgetTester tester) async {
    await tester.pumpWidget(const TamilHandwritingApp());

    expect(find.byType(Scaffold), findsOneWidget);
    expect(find.text('Next'), findsOneWidget);
    expect(find.text('Undo'), findsOneWidget);
    expect(find.text('Clear'), findsOneWidget);
  });

  testWidgets('drawing a stroke and capturing produces non-empty PNG bytes',
      (WidgetTester tester) async {
    final controller = DrawingCanvasController();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 300,
            height: 300,
            child: DrawingCanvas(controller: controller),
          ),
        ),
      ),
    );

    expect(controller.isEmpty, isTrue);

    await tester.dragFrom(const Offset(50, 50), const Offset(100, 100));
    await tester.pump();

    expect(controller.isEmpty, isFalse);

    final bytes = await tester.runAsync(() => controller.captureImage());
    expect(bytes, isNotNull);
    expect(bytes!.length, greaterThan(0));
    // PNG magic bytes.
    expect(bytes.take(4), [0x89, 0x50, 0x4E, 0x47]);

    controller.undo();
    expect(controller.isEmpty, isTrue);
  });

  test('tamilLetters has exactly 247 unique entries', () {
    expect(tamilLetters.length, 247);
    expect(tamilLetters.toSet().length, 247);
  });

  test('slugForLetter produces stable, ASCII-safe keys', () {
    final slug = slugForLetter('கு');
    expect(slug, '0B95-0BC1');
  });

  test('slugToLetter reverses slugForLetter for every letter', () {
    for (final letter in tamilLetters) {
      expect(slugToLetter[slugForLetter(letter)], letter);
    }
  });
}
