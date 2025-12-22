import 'package:flutter_test/flutter_test.dart';
import 'package:study_anxiety_app/main.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:study_anxiety_app/services/storage_service.dart';

void main() {
  testWidgets('App should launch', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final storageService = StorageService(prefs);

    await tester.pumpWidget(StudyAnxietyApp(storageService: storageService));

    expect(find.text('불안해서 공부하는 사람들'), findsOneWidget);
  });
}
