import 'package:chatflow/main.dart';
import 'package:chatflow/utils/constants.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('ChatFlowApp renders Firebase Setup Guide when uninitialized',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const ChatFlowApp(
        isFirebaseReady: false,
        firebaseError: 'Firebase not configured yet',
      ),
    );

    // Verify brand title and subtitle render
    expect(find.text(AppConstants.appName), findsOneWidget);
    expect(find.text(AppConstants.appSubtitle), findsOneWidget);
    expect(find.text('Firebase Setup Required'), findsOneWidget);
    expect(find.text('Retry Connection'), findsOneWidget);
  });
}
