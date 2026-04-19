import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:zeno/main.dart';

void main() {
  testWidgets('shows firebase error shell when firebase is unavailable', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MyApp(isFirebaseAvailable: false),
      ),
    );

    expect(find.text('Firebase Connection Error'), findsOneWidget);
    expect(find.text('Try Again'), findsOneWidget);
  });
}
