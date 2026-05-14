import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:notice_app/features/auth/providers/auth_provider.dart';
import 'package:notice_app/features/auth/ui/login_screen.dart';
import 'package:notice_app/features/auth/ui/register_screen.dart';
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
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => const MainScreen(),
      ),
    ],
    redirect: (context, state) {
      if (authState.isLoading) {
        return null;
      }

      final bool isLoggedIn = authState.isLoggedIn;
      final String loc = state.matchedLocation;
      final bool isPublicAuth = loc == '/login' || loc == '/register';

      if (!isLoggedIn && !isPublicAuth) {
        return '/login';
      }

      if (isLoggedIn && isPublicAuth) {
        return '/home';
      }

      return null;
    },
  );
});
