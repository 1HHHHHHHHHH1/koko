import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/services/notification_service.dart';
import 'providers/auth_provider.dart';

class VentureBridgeApp extends ConsumerWidget {
  const VentureBridgeApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    // ✅ ابدأ الاستماع للإشعارات عند تسجيل الدخول
    ref.listen<AuthState>(authProvider, (prev, next) {
      final svc = ref.read(notificationServiceProvider);
      if (next.isAuthenticated && next.user != null) {
        svc.startListening(next.user!.id);
      } else {
        svc.stopListening();
      }
    });

    return MaterialApp.router(
      title: 'SharkSpace',
      debugShowCheckedModeBanner: false,
      darkTheme: AppTheme.darkTheme,
      theme: AppTheme.lightTheme,
      themeMode: ThemeMode.system,
      routerConfig: router,

      builder: (context, child) {
        return NotificationOverlay(
          child: child!,
        );
      },
    );
  }
}
