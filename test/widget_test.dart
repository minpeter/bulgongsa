import 'package:flutter_test/flutter_test.dart';
import 'package:study_anxiety_app/main.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:study_anxiety_app/services/storage_service.dart';

void main() {
  testWidgets('App should launch with STUDY BUDDY header', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final storageService = StorageService(prefs);

    await tester.pumpWidget(StudyAnxietyApp(storageService: storageService));
    await tester.pumpAndSettle();

    // Check for the main header
    expect(find.text('STUDY BUDDY'), findsOneWidget);
  });

  testWidgets('App should show study button', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final storageService = StorageService(prefs);

    await tester.pumpWidget(StudyAnxietyApp(storageService: storageService));
    await tester.pumpAndSettle();

    // Check for study start button
    expect(find.text('▶ 공부 시작!'), findsOneWidget);
  });
}
