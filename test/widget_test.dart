// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:pinkrain/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory tempDir;

  setUpAll(() async {
    // Create a temporary directory for Hive
    tempDir = await Directory.systemTemp.createTemp('test_hive_');
    Hive.init(tempDir.path);
  });

  tearDownAll(() async {
    // Clean up Hive and temp directory
    await Hive.close();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

testWidgets('App initializes and renders', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());
    
    // Let the app initialize and advance past splash screen timer
    await tester.pump();
    await tester.pump(const Duration(seconds: 3)); // Skip splash timer
    await tester.pumpAndSettle();

    // Verify that the app renders without crashing
    // This is a simple smoke test that just checks if the app starts
    expect(find.byType(MyApp), findsOneWidget);
  });
}
