import 'package:flutter_test/flutter_test.dart';
import 'package:koere_mobile/main.dart';

void main() {
  testWidgets('App smoke test', (tester) async {
    await tester.pumpWidget(const KoereApp());
    expect(find.byType(KoereApp), findsOneWidget);
  });
}
