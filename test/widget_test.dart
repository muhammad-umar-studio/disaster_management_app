import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:disaster_management_app/main.dart';

void main() {
  testWidgets('AEGIS app loads', (WidgetTester tester) async {
    await tester.pumpWidget(const AegisApp());
    expect(find.byType(MaterialApp), findsWidgets);
  });
}
