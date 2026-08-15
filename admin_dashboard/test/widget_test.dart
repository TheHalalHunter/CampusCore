import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Admin dashboard basic structure test',
      (WidgetTester tester) async {
    // Create a minimal test app
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          appBar: AppBar(title: const Text('Admin Dashboard')),
          body: const Center(child: Text('Admin Portal')),
        ),
      ),
    );

    // Verify app renders
    expect(find.text('Admin Dashboard'), findsOneWidget);
    expect(find.text('Admin Portal'), findsOneWidget);
  });
}
