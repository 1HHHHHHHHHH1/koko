// ✅ app_router.dart — redirect حقيقي مع Supabase Auth
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '/providers/auth_provider.dart';

// Auth Screens
import '/features/auth/presentation/screens/login_screen.dart';
import '/features/auth/presentation/screens/register_screen.dart';
import '/features/auth/presentation/screens/splash_screen.dart';

// Dashboard Screens
import '/features/dashboard/entrepreneur/presentation/screens/entrepreneur_dashboard_screen.dart';
import '/features/dashboard/investor/presentation/screens/investor_dashboard_screen.dart';
import '/features/dashboard/entrepreneur/presentation/screens/create_project_screen.dart';
import '/features/dashboard/investor/presentation/screens/investment_criteria_screen.dart';

// Browse Screens
import '/features/browse/presentation/screens/browse_investors_screen.dart';
import '/features/browse/presentation/screens/browse_projects_screen.dart';
import '/features/browse/presentation/screens/investor_detail_screen.dart';
import '/features/browse/presentation/screens/project_detail_screen.dart';
import '/features/browse/presentation/screens/profile_screen.dart';

// Search / Likes / Messaging
import '/features/search/presentation/screens/search_screen.dart';
import '/features/likes/presentation/screens/my_likes_screen.dart';
import '/features/messaging/presentation/screens/conversations_screen.dart';
import '/features/messaging/presentation/screens/chat_screen.dart';
import '/features/profile/presentation/screens/edit_profile_screen.dart';

// ────────────────────────────────────────────────────────────
// Route names
// ────────────────────────────────────────────────────────────
class Routes {
  static const splash               = '/';
  static const login                = '/login';
  static const register             = '/register';
  static const entrepreneurDashboard = '/entrepreneur';
  static const createProject        = '/entrepreneur/project/create';
  static const investorDashboard    = '/investor';
  static const investmentCriteria   = '/investor/criteria';
  static const browseInvestors      = '/browse/investors';
  static const browseProjects       = '/browse/projects';
  static const search               = '/search';
  static const myLikes              = '/likes';
  static const conversations        = '/messages';
  static const myProfile            = '/my-profile';
}

// ────────────────────────────────────────────────────────────
// Paths that don't require authentication
// ────────────────────────────────────────────────────────────
const _publicRoutes = [Routes.splash, Routes.login, Routes.register];

// ────────────────────────────────────────────────────────────
// Router Provider
// ────────────────────────────────────────────────────────────
final routerProvider = Provider<GoRouter>((ref) {
  // نمرر listenable لكي يعيد GoRouter البناء عند تغيّر Auth
  final authNotifier = ref.watch(authProvider.notifier);

  return GoRouter(
    initialLocation: Routes.splash,
    debugLogDiagnostics: true,
    refreshListenable: _AuthNotifierListenable(ref),

    // ✅ redirect منطق حقيقي
    redirect: (context, state) {
      final authState  = ref.read(authProvider);
      final location   = state.matchedLocation;
      final isPublic   = _publicRoutes.contains(location);
      final isLoading  = authState.status == AuthStatus.initial ||
                         authState.status == AuthStatus.loading;

      // لا تزال تُحمَّل → بقاء على الـ splash
      if (isLoading) {
        return location == Routes.splash ? null : Routes.splash;
      }

      final isAuth = authState.isAuthenticated;

      // غير مسجّل + صفحة خاصة → إلى تسجيل الدخول
      if (!isAuth && !isPublic) return Routes.login;

      // مسجّل + صفحة عامة → إلى داشبورد مناسب
      if (isAuth && isPublic) {
        return authState.user?.userType == 'investor'
            ? Routes.investorDashboard
            : Routes.entrepreneurDashboard;
      }

      return null; // لا تحويل
    },

    routes: [
      GoRoute(path: Routes.splash,
          builder: (_, __) => const SplashScreen()),
      GoRoute(path: Routes.login,
          builder: (_, __) => const LoginScreen()),
      GoRoute(path: Routes.register,
          builder: (_, __) => const RegisterScreen()),

      // Entrepreneur
      GoRoute(path: Routes.entrepreneurDashboard,
          builder: (_, __) => const EntrepreneurDashboardScreen()),
      GoRoute(path: Routes.createProject,
          builder: (_, __) => const CreateProjectScreen()),
      GoRoute(path: '/entrepreneur/project/:id/edit',
          builder: (_, s) =>
              CreateProjectScreen(projectId: s.pathParameters['id'])),

      // Investor
      GoRoute(path: Routes.investorDashboard,
          builder: (_, __) => const InvestorDashboardScreen()),
      GoRoute(path: Routes.investmentCriteria,
          builder: (_, __) => const InvestmentCriteriaScreen()),

      // Browse
      GoRoute(path: Routes.browseInvestors,
          builder: (_, __) => const BrowseInvestorsScreen()),
      GoRoute(path: Routes.browseProjects,
          builder: (_, __) => const BrowseProjectsScreen()),
      GoRoute(path: '/investor/:id',
          builder: (_, s) =>
              InvestorDetailScreen(investorId: s.pathParameters['id']!)),
      GoRoute(path: '/project/:id',
          builder: (_, s) =>
              ProjectDetailScreen(projectId: s.pathParameters['id']!)),

      // Search / Likes / Messaging
      GoRoute(path: Routes.search,
          builder: (_, __) => const SearchScreen()),
      GoRoute(path: Routes.myLikes,
          builder: (_, __) => const MyLikesScreen()),
      GoRoute(path: Routes.conversations,
          builder: (_, __) => const ConversationsScreen()),
      GoRoute(path: '/messages/:id',
          builder: (_, s) =>
              ChatScreen(conversationId: s.pathParameters['id']!)),

      // Profile
      GoRoute(
        path: Routes.myProfile,
        builder: (_, __) => const EditProfileScreen(),
      ),
      GoRoute(path: '/profile/:id',
          builder: (_, s) =>
              ProfileScreen(userId: s.pathParameters['id']!)),
    ],

    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('Page not found',
                style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go(Routes.splash),
              child: const Text('Go Home'),
            ),
          ],
        ),
      ),
    ),
  );
});

// ────────────────────────────────────────────────────────────
// Helper: يجعل GoRouter يستمع لتغيّرات authProvider
// ────────────────────────────────────────────────────────────
class _AuthNotifierListenable extends ChangeNotifier {
  _AuthNotifierListenable(Ref ref) {
    ref.listen<AuthState>(authProvider, (_, __) => notifyListeners());
  }
}
