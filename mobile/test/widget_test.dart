import 'package:flutter_test/flutter_test.dart';
import 'package:covatask_mobile/main.dart';

void main() {
  testWidgets('CovaTask demarre sans erreur', (WidgetTester tester) async {
    await tester.pumpWidget(const TaskManagerApp());
    await tester.pump();
    expect(find.byType(TaskManagerApp), findsOneWidget);
  });
}
