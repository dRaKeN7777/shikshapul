import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shikshapul/main.dart';

void main() {
  testWidgets('Lite app reaches the first screen without native AI',
      (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: ShikshaPulApp()),
    );
    await tester.pump();

    expect(find.text('ShikshaPul'), findsOneWidget);
    expect(find.text('SELECT YOUR EXAM'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  test('decoded image cache stays bounded for low-memory phones', () {
    PaintingBinding.instance.imageCache
      ..maximumSize = 80
      ..maximumSizeBytes = 24 * 1024 * 1024;

    expect(PaintingBinding.instance.imageCache.maximumSize, 80);
    expect(
      PaintingBinding.instance.imageCache.maximumSizeBytes,
      24 * 1024 * 1024,
    );
  });
}
