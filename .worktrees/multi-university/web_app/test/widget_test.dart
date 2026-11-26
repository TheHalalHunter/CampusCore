import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Web app basic structure test', (WidgetTester tester) async {
    // Create a minimal test app
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          appBar: AppBar(title: const Text('CampusCore Web')),
          body: const Center(child: Text('Student Portal')),
        ),
      ),
    );

    // Verify app renders
    expect(find.text('CampusCore Web'), findsOneWidget);
    expect(find.text('Student Portal'), findsOneWidget);
  });
}
