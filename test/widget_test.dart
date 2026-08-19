import 'package:flutter_test/flutter_test.dart';

import 'package:rr_fabrication/main.dart';

void main() {
  testWidgets('login screen shows welcome and login button', (tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('Welcome'), findsOneWidget);
    expect(find.text('Login'), findsOneWidget);
  });
}
