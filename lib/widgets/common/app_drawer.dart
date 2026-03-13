import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/app_router.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../providers/likes_provider.dart';

class AppDrawer extends ConsumerWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final user = ref.watch(currentUserProvider);
    final isEntrepreneur = user?.userType == 'entrepreneur';

    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    theme.colorScheme.primary,
                    theme.colorScheme.secondary,
                  ],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 32,
                    backgroundColor: Colors.white,
                    child: Text(
                      user?.name.isNotEmpty == true
                          ? user!.name[0].toUpperCase()
                          : 'U',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    user?.name ?? 'User',
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    user?.email ?? '',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      isEntrepreneur ? 'Entrepreneur' : 'Investor',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Menu
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  _DrawerItem(
                    icon: Icons.dashboard_outlined,
                    title: 'Dashboard',
                    onTap: () {
                      Navigator.pop(context);
                      context.go(
                        isEntrepreneur
                            ? Routes.entrepreneurDashboard
                            : Routes.investorDashboard,
                      );
                    },
                  ),

                  _DrawerItem(
                    icon: Icons.search,
                    title: 'Search',
                    onTap: () {
                      Navigator.pop(context);
                      context.push(Routes.search);
                    },
                  ),

                  const Divider(),

                  _DrawerItem(
                    icon: Icons.business_center_outlined,
                    title: 'Browse Projects',
                    onTap: () {
                      Navigator.pop(context);
                      context.push(Routes.browseProjects);
                    },
                  ),

                  _DrawerItem(
                    icon: Icons.people_outlined,
                    title: 'Browse Investors',
                    onTap: () {
                      Navigator.pop(context);
                      context.push(Routes.browseInvestors);
                    },
                  ),

                  const Divider(),

                  _DrawerItem(
                    icon: Icons.favorite_outline,
                    title: 'My Likes',
                    onTap: () {
                      Navigator.pop(context);
                      context.push(Routes.myLikes);
                    },
                  ),

                  _DrawerItem(
                    icon: Icons.message_outlined,
                    title: 'Messages',
                    onTap: () {
                      Navigator.pop(context);
                      context.push(Routes.conversations);
                    },
                  ),

                  if (isEntrepreneur) ...[
                    const Divider(),
                    _DrawerItem(
                      icon: Icons.add_business,
                      title: 'Create Project',
                      onTap: () {
                        Navigator.pop(context);
                        context.push(Routes.createProject);
                      },
                    ),
                  ],

                  if (!isEntrepreneur) ...[
                    const Divider(),
                    _DrawerItem(
                      icon: Icons.tune,
                      title: 'Investment Criteria',
                      onTap: () {
                        Navigator.pop(context);
                        context.push(Routes.investmentCriteria);
                      },
                    ),
                  ],
                ],
              ),
            ),

            const Divider(),

            _DrawerItem(
              icon: Icons.logout,
              title: 'Logout',
              textColor: theme.colorScheme.error,
              onTap: () async {
                Navigator.pop(context);
                await ref.read(authProvider.notifier).logout();
              },
            ),

            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final Color? textColor;

  const _DrawerItem({
    required this.icon,
    required this.title,
    required this.onTap,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: textColor),
      title: Text(
        title,
        style: TextStyle(color: textColor),
      ),
      onTap: onTap,
    );
  }
}