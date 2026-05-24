import 'package:flutter/material';
import 'package:go_router/go_router.dart';

class AppRoutes {
  static const String login = '/login';
  static const String dashboard = '/';

  static final GoRouter router = GoRouter(
    initialLocation: dashboard,
    routes: [
      GoRoute(
        path: login,
        builder: (context, state) => const Scaffold(
          body: Center(
            child: Text('DCS Login Screen (Placeholder)'),
          ),
        ),
      ),
      GoRoute(
        path: dashboard,
        builder: (context, state) => const Scaffold(
          body: Center(
            child: Text(
              'Document Control System\n(Clean Architecture Initialized)',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ),
    ],
  );
}
