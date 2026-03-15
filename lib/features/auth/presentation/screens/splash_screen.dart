// ✅ splash_screen.dart — يراقب حالة Auth ويوجّه تلقائياً
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/app_router.dart';
import '../../../../providers/auth_provider.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double>   _fadeAnimation;
  late Animation<double>   _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1500));

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _controller,
            curve: const Interval(0.0, 0.5, curve: Curves.easeIn)));
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
        CurvedAnimation(parent: _controller,
            curve: const Interval(0.0, 0.5, curve: Curves.easeOut)));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // ✅ نستمع للـ authProvider هنا ونوجّه حسب الحالة
  @override
  Widget build(BuildContext context) {
    // يراقب authProvider ويعيد البناء عند كل تغيير
    ref.listen<AuthState>(authProvider, (previous, next) {
      if (next.status == AuthStatus.authenticated) {
        final userType = next.user?.userType;
        if (userType == 'investor') {
          context.go(Routes.investorDashboard);
        } else {
          context.go(Routes.entrepreneurDashboard);
        }
      } else if (next.status == AuthStatus.unauthenticated ||
                 next.status == AuthStatus.error) {
        context.go(Routes.login);
      }
    });

    final theme = Theme.of(context);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.colorScheme.primary,
              theme.colorScheme.secondary,
            ],
          ),
        ),
        child: Center(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) => FadeTransition(
              opacity: _fadeAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 120, height: 120,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 20, offset: const Offset(0, 10)),
                        ],
                      ),
                      child: Icon(Icons.handshake_outlined, size: 64,
                          color: theme.colorScheme.primary),
                    ),
                    const SizedBox(height: 32),
                    Text('VentureBridge',
                        style: theme.textTheme.headlineLarge?.copyWith(
                            color: Colors.white, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text('Connect. Invest. Grow.',
                        style: theme.textTheme.titleMedium?.copyWith(
                            color: Colors.white.withOpacity(0.9))),
                    const SizedBox(height: 48),
                    const CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation(Colors.white)),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
