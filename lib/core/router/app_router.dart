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
final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: Routes.login,
    debugLogDiagnostics: true,
    routes: [

      // Splash
      GoRoute(
        path: Routes.splash,
        builder: (context, state) => const SplashScreen(),
      ),

      // Auth
      GoRoute(
        path: Routes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: Routes.register,
        builder: (context, state) => const RegisterScreen(),
      ),

      /// -------------------------
      /// Entrepreneur Section
      /// -------------------------
      GoRoute(
        path: Routes.entrepreneurDashboard,
        builder: (context, state) => const EntrepreneurDashboardScreen(),
        routes: [

          /// Create Project
          GoRoute(
            path: 'project/create',
            builder: (context, state) => const CreateProjectScreen(),
          ),

          /// Edit Project
          GoRoute(
            path: 'project/:id/edit',
            builder: (context, state) {
              final id = state.pathParameters['id']!;
              return CreateProjectScreen(projectId: id);
            },
          ),
        ],
      ),

      /// -------------------------
      /// Investor Section
      /// -------------------------
      GoRoute(
        path: Routes.investorDashboard,
        builder: (context, state) => const InvestorDashboardScreen(),
        routes: [
          GoRoute(
            path: 'criteria',
            builder: (context, state) => const InvestmentCriteriaScreen(),
          ),
        ],
      ),

      /// -------------------------
      /// Browse
      /// -------------------------
      GoRoute(
        path: Routes.browseProjects,
        builder: (context, state) => const BrowseProjectsScreen(),
        routes: [
          GoRoute(
            path: ':id',
            builder: (context, state) {
              final id = state.pathParameters['id']!;
              return ProjectDetailScreen(projectId: id);
            },
          ),
        ],
      ),

      GoRoute(
        path: Routes.browseInvestors,
        builder: (context, state) => const BrowseInvestorsScreen(),
        routes: [
          GoRoute(
            path: ':id',
            builder: (context, state) {
              final id = state.pathParameters['id']!;
              return InvestorDetailScreen(investorId: id);
            },
          ),
        ],
      ),

      /// Search
      GoRoute(
        path: Routes.search,
        builder: (context, state) => const SearchScreen(),
      ),

      /// Likes
      GoRoute(
        path: Routes.myLikes,
        builder: (context, state) => const MyLikesScreen(),
      ),

      /// Messaging
      GoRoute(
        path: Routes.conversations,
        builder: (context, state) => const ConversationsScreen(),
        routes: [
          GoRoute(
            path: ':id',
            builder: (context, state) {
              final id = state.pathParameters['id']!;
              return ChatScreen(conversationId: id);
            },
          ),
        ],
      ),

      /// Profile
      GoRoute(
        path: Routes.profile,
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return ProfileScreen(userId: id);
        },
      ),
    ],
  );
});