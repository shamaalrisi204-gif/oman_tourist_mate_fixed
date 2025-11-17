import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oman_tourist_mate_fixed/main.dart';

void main() {
  testWidgets('OmanTouristMateApp loads successfully',
      (WidgetTester tester) async {
    // شغّل التطبيق
    await tester.pumpWidget(const OmanTouristMateApp());

    // تأكد إن التطبيق اشتغل بدون كراش (وجود MaterialApp)
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
