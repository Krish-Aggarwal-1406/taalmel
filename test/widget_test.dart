import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:taalmel/pages/login_page.dart';

void main() {
  testWidgets('Login page smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      GetMaterialApp(
        home: LoginPage(),
      ),
    );

    // Check if "Log In" button is visible
    expect(find.text('Log In'), findsOneWidget);
  });
}
