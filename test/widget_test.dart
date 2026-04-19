import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Askaria PC smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(body: Center(child: Text('Askaria PC Test'))),
    ));
    expect(find.text('Askaria PC Test'), findsOneWidget);
  });
}
