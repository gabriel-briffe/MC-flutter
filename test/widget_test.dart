import 'package:flutter_test/flutter_test.dart';
import 'package:mc_flutter/app.dart';
import 'package:mc_flutter/map/osm_map_page.dart';

void main() {
  testWidgets('app loads map page', (WidgetTester tester) async {
    // Arrange
    await tester.pumpWidget(const McFlutterApp());

    // Act — first frame
    await tester.pump();

    // Assert
    expect(find.byType(OsmMapPage), findsOneWidget);
  });
}
