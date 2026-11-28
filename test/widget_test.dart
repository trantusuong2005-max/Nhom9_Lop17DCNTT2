import 'package:flutter_test/flutter_test.dart';
import 'package:travel_diary_app/main.dart';

void main() {
  testWidgets('App loads TravelDiaryApp', (WidgetTester tester) async {
    await tester.pumpWidget(const TravelDiaryApp(firebaseReady: false));
    expect(find.text('Sổ tay Chuyến đi (Offline)'), findsOneWidget);
  });
}