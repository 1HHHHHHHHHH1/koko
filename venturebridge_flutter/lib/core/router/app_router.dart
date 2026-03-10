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

// Search Screen
import '/features/search/presentation/screens/search_screen.dart';

// Likes Screen
import '/features/likes/presentation/screens/my_likes_screen.dart';

// Messaging Screens
import '/features/messaging/presentation/screens/conversations_screen.dart';
import '/features/messaging/presentation/screens/chat_screen.dart';

// Profile Screens
import '/features/browse/presentation/screens/profile_screen.dart';

// Route Names
class Routes {
  static const splash = '/';
  static const login = '/login';
  static const register = '/register';
  
  // Entrepreneur Routes
  static const entrepreneurDashboard = '/entrepreneur';
  static const createProject = '/entrepreneur/project/create';
  static const editProject = '/entrepreneur/project/:id/edit';
  
  // Investor Routes
  static const investorDashboard = '/investor';
  static const investmentCriteria = '/investor/criteria';
  
  // Browse Routes
  static const browseInvestors = '/browse/investors';
  static const browseProjects = '/browse/projects';
  static const investorDetail = '/investor/:id';
  static const projectDetail = '/project/:id';

  // Search
  static const search = '/search';
  
  // Likes

  static const myLikes = '/likes';
  // Messaging
  static const conversations = '/messages';
  static const chat = '/messages/:id';
  
  // Profile
  static const profile = '/profile/:id';
}

// Router Provider
final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: Routes.login,
    debugLogDiagnostics: true,
      redirect: (context, state) {
        return null;
      },
    routes: [
      // Splash
      GoRoute(
        path: Routes.splash,
        builder: (context, state) => const SplashScreen(),
      ),

      // Auth Routes
      GoRoute(
        path: Routes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: Routes.register,
        builder: (context, state) => const RegisterScreen(),
      ),

      // Entrepreneur Routes
      GoRoute(
        path: Routes.entrepreneurDashboard,
        builder: (context, state) => const EntrepreneurDashboardScreen(),
      ),
      GoRoute(
        path: Routes.createProject,
        builder: (context, state) => const CreateProjectScreen(),
      ),
      GoRoute(
        path: '/entrepreneur/project/:id/edit',
        builder: (context, state) {
          final projectId = state.pathParameters['id']!;
          return CreateProjectScreen(projectId: projectId);
        },
      ),

      // Investor Routes
      GoRoute(
        path: Routes.investorDashboard,
        builder: (context, state) => const InvestorDashboardScreen(),
      ),
      GoRoute(
        path: Routes.investmentCriteria,
        builder: (context, state) => const InvestmentCriteriaScreen(),
      ),

      // Browse Routes
      GoRoute(
        path: Routes.browseInvestors,
        builder: (context, state) => const BrowseInvestorsScreen(),
      ),
      GoRoute(
        path: Routes.browseProjects,
        builder: (context, state) => const BrowseProjectsScreen(),
      ),
      GoRoute(
        path: '/investor/:id',
        builder: (context, state) {
          final investorId = state.pathParameters['id']!;
          return InvestorDetailScreen(investorId: investorId);
        },
      ),
      GoRoute(
        path: '/project/:id',
        builder: (context, state) {
          final projectId = state.pathParameters['id']!;
          return ProjectDetailScreen(projectId: projectId);
        },
      ),

      // Search
      GoRoute(
        path: Routes.search,
        builder: (context, state) => const SearchScreen(),
      ),

      // Likes
      GoRoute(
        path: Routes.myLikes,
        builder: (context, state) => const MyLikesScreen(),
      ),

      // Messaging
      GoRoute(
        path: Routes.conversations,
        builder: (context, state) => const ConversationsScreen(),
      ),
      GoRoute(
        path: '/messages/:id',
        builder: (context, state) {
          final conversationId = state.pathParameters['id']!;
          return ChatScreen(conversationId: conversationId);
        },
      ),

      // Profile
      GoRoute(
        path: '/profile/:id',
        builder: (context, state) {
          final userId = state.pathParameters['id']!;
          return ProfileScreen(userId: userId);
        },
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              'Page not found',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              state.matchedLocation,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
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
