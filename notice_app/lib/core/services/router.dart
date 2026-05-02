import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:notice_app/features/auth/providers/auth_provider.dart';
import 'package:notice_app/features/auth/ui/login_screen.dart';
import 'package:notice_app/shared/ui/main_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final AuthState authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: '/login',
    routes: <RouteBase>[
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => const MainScreen(),
      ),
    ],
    redirect: (context, state) {
      final bool isLoggedIn = authState.isLoggedIn;
      final bool isLoginRoute = state.matchedLocation == '/login';

      if (!isLoggedIn && !isLoginRoute) {
        return '/login';
      }

      if (isLoggedIn && isLoginRoute) {
        return '/home';
      }

      return null;
    },
  );
});
