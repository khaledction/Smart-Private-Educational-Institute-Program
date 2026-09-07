import 'package:flutter_test/flutter_test.dart';
import 'package:maehdi_app/main.dart';

void main() {
  testWidgets('يعرض التطبيق بدون انهيار', (WidgetTester tester) async {
    await tester.pumpWidget(const MaehdiApp());
    expect(find.text('معهدّي'), findsWidgets);
  });
}
