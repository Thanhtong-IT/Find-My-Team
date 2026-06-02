import 'package:flutter_test/flutter_test.dart';
import 'package:find_my_team01/main.dart';

void main() {
  testWidgets('App starts with SplashScreen', (WidgetTester tester) async {
    await tester.pumpWidget(const FindMyTeamApp());
    await tester.pump();
    expect(find.text('Find My Team'), findsOneWidget);
  });
}
