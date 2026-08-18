import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_scanner/main.dart';

void main() {
  testWidgets('App loads smoke test', (WidgetTester tester) async {
    // runAsync so the splash screen's real startup work (opening the drift
    // database to repair product image paths) uses real timers instead of the
    // fake-async clock, which would otherwise fail with a pending timer.
    await tester.runAsync(() async {
      await tester.pumpWidget(const ProviderScope(child: CatalogMakerApp()));
    });
    expect(find.byType(CatalogMakerApp), findsOneWidget);
  });
}
