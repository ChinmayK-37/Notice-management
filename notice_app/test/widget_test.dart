import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:notice_app/app.dart';
import 'package:notice_app/core/services/token_service.dart';
import 'package:notice_app/features/auth/providers/auth_provider.dart';
import 'package:notice_app/features/auth/ui/login_screen.dart';

void main() {
  testWidgets('shows login screen', (WidgetTester tester) async {
    final memory = <String, String>{};

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          tokenServiceProvider.overrideWith(
            (ref) => TokenService(memory: memory),
          ),
        ],
        child: const App(),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.byType(LoginScreen), findsOneWidget);
  });
}
