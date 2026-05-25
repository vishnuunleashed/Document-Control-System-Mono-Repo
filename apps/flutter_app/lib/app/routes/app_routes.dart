import 'package:go_router/go_router.dart';
import 'package:flutter_app/features/auth/presentation/pages/login_page.dart';
import 'package:flutter_app/features/dashboard/presentation/pages/dashboard_page.dart';
import 'package:flutter_app/features/documents/presentation/pages/document_detail_page.dart';
import 'package:flutter_app/shared/services/session_manager.dart';

class AppRoutes {
  static const String login = '/login';
  static const String dashboard = '/';
  static const String documentDetail = '/document/:id';

  static final GoRouter router = GoRouter(
    initialLocation: dashboard,
    redirect: (context, state) {
      final loggedIn = SessionManager.isAuthenticated;
      final goingToLogin = state.matchedLocation == login;

      if (!loggedIn && !goingToLogin) {
        return login;
      }
      if (loggedIn && goingToLogin) {
        return dashboard;
      }
      return null;
    },
    routes: [
      GoRoute(
        path: login,
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: dashboard,
        builder: (context, state) => const DashboardPage(),
      ),
      GoRoute(
        path: documentDetail,
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return DocumentDetailPage(documentId: id);
        },
      ),
    ],
  );
}
