import 'package:flutter_test/flutter_test.dart';
import 'package:mc_flutter/main.dart';

void main() {
  testWidgets('app loads map page', (WidgetTester tester) async {
    await tester.pumpWidget(const McFlutterApp());
    expect(find.byType(OsmMapPage), findsOneWidget);
  });
}
