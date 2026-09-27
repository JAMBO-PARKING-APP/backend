// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';
import 'package:parking_user_app/core/providers/connectivity_provider.dart';
import 'package:parking_user_app/core/settings_provider.dart';
import 'package:parking_user_app/main.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('user app root can be built', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => SettingsProvider()),
          ChangeNotifierProvider(create: (_) => ConnectivityProvider()),
        ],
        child: const SpaceUserApp(),
      ),
    );
    await tester.pump();
    expect(find.byType(SpaceUserApp), findsOneWidget);
  });
}
