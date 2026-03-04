import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import '../features/services/presentation/pages/services_list_page.dart';
import '../features/services/presentation/pages/service_details_page.dart';

final router = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      name: 'services',
      builder: (context, state) => const ServicesListPage(),
      routes: [
        GoRoute(
          path: 'service/:id',
          name: 'service',
          builder: (context, state) {
            final id = state.pathParameters['id']!;
            return ServiceDetailsPage(serviceId: id);
          },
        ),
      ],
    ),
  ],
  errorBuilder: (context, state) => Scaffold(
    appBar: AppBar(title: const Text('Error')),
    body: Center(child: Text('Error: ${state.error}')),
  ),
);

// Helper extension for easier navigation
extension GoRouterExtension on BuildContext {
  void goToServiceDetails(String serviceId) {
    go('/service/$serviceId');
  }

  void pushServiceDetails(String serviceId) {
    push('/service/$serviceId');
  }
}
