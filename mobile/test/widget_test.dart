// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mobile/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const SekuritiV2App());

    // Verify that the app builds and shows some content
    // We expect at least one widget to be present.
    // Since we don't know the exact content of LoginPage, just checking for MaterialApp is a good start.
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
