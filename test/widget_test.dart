import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:smart_mart_mobile/main.dart';

void main() {
  testWidgets('App boots to the splash screen', (WidgetTester tester) async {
    await tester.pumpWidget(const SmartMartApp());
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}
