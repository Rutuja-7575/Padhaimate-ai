import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:padhaimate_app/main.dart';

void main() {
  testWidgets('App loads and shows bottom navigation', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    // Bottom nav tabs should be present
    expect(find.text('Upload'), findsOneWidget);
    expect(find.text('Library'), findsOneWidget);

    // Should be showing app bar title for the default tab
    expect(find.text('Ask PadhaiMate'), findsOneWidget);
  });
}