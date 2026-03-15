import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_router.dart';
import '../../providers/auth_provider.dart';
import '../../features/profile/presentation/screens/edit_profile_screen.dart';

class AppDrawer extends ConsumerWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme          = Theme.of(context);
    final user           = ref.watch(currentUserProvider);
    final isEntrepreneur = user?.userType == 'entrepreneur';

    return Drawer(
      child: SafeArea(
        child: Column(
          children: [

            // ✅ Header قابل للنقر → ينتقل لبروفايل المستخدم
            GestureDetector(
              onTap: () {
                Navigator.pop(context);
                if (user != null) {
                  context.go('/profile/${user.id}');
                }
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
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
                    // ✅ صورة البروفايل مع أيقونة الكاميرا
                    Stack(
                      children: [
                        CircleAvatar(
                          radius: 32,
                          backgroundColor: Colors.white.withOpacity(0.2),
                          backgroundImage: user?.avatar != null
                              ? NetworkImage(user!.avatar!) : null,
                          child: user?.avatar == null
                              ? Text(
                                  user?.name.isNotEmpty == true
                                      ? user!.name[0].toUpperCase() : 'U',
                                  style: TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    color: theme.colorScheme.primary,
                                  ),
                                )
                              : null,
                        ),
                        // أيقونة تعديل الصورة
                        Positioned(
                          bottom: 0, right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color: theme.colorScheme.secondary, width: 1.5),
                            ),
                            child: Icon(Icons.camera_alt,
                                color: theme.colorScheme.secondary, size: 12),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      user?.name ?? 'User',
                      style: theme.textTheme.titleLarge?.copyWith(
                          color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      user?.email ?? '',
                      style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.white.withOpacity(0.85)),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            isEntrepreneur ? '🚀 Entrepreneur' : '💼 Investor',
                            style: const TextStyle(
                                color: Colors.white, fontSize: 12),
                          ),
                        ),
                        const Spacer(),
                        // ✅ نص "View Profile"
                        Text(
                          'View Profile →',
                          style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // ── Menu Items ─────────────────────────────
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [

                  _DrawerItem(
                    icon: Icons.dashboard_outlined,
                    title: 'Dashboard',
                    onTap: () {
                      Navigator.pop(context);
                      context.go(isEntrepreneur
                          ? Routes.entrepreneurDashboard
                          : Routes.investorDashboard);
                    },
                  ),

                  // ✅ My Profile
                  _DrawerItem(
                    icon: Icons.person_outline,
                    title: 'My Profile',
                    onTap: () {
                      Navigator.pop(context);
                      if (user != null) context.go('/profile/${user.id}');
                    },
                  ),

                  _DrawerItem(
                    icon: Icons.search,
                    title: 'Search',
                    onTap: () {
                      Navigator.pop(context);
                      context.go(Routes.search);
                    },
                  ),
                  const Divider(),

                  _DrawerItem(
                    icon: Icons.business_center_outlined,
                    title: 'Browse Projects',
                    onTap: () {
                      Navigator.pop(context);
                      context.go(Routes.browseProjects);
                    },
                  ),
                  _DrawerItem(
                    icon: Icons.people_outlined,
                    title: 'Browse Investors',
                    onTap: () {
                      Navigator.pop(context);
                      context.go(Routes.browseInvestors);
                    },
                  ),
                  const Divider(),

                  _DrawerItem(
                    icon: Icons.favorite_outline,
                    title: 'My Likes',
                    onTap: () {
                      Navigator.pop(context);
                      context.go(Routes.myLikes);
                    },
                  ),
                  _DrawerItem(
                    icon: Icons.message_outlined,
                    title: 'Messages',
                    onTap: () {
                      Navigator.pop(context);
                      context.go(Routes.conversations);
                    },
                  ),

                  if (isEntrepreneur) ...[
                    const Divider(),
                    _DrawerItem(
                      icon: Icons.add_business,
                      title: 'Create Project',
                      onTap: () {
                        Navigator.pop(context);
                        context.go(Routes.createProject);
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
                        context.go(Routes.investmentCriteria);
                      },
                    ),
                  ],

                  const Divider(),
                  // ✅ Edit Profile
                  _DrawerItem(
                    icon: Icons.edit_outlined,
                    title: 'Edit Profile',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(context,
                        MaterialPageRoute(
                            builder: (_) => const EditProfileScreen()));
                    },
                  ),
                ],
              ),
            ),

            // ── Logout ─────────────────────────────────
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
  final String   title;
  final VoidCallback onTap;
  final Color?   textColor;

  const _DrawerItem({
    required this.icon,
    required this.title,
    required this.onTap,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) => ListTile(
        leading: Icon(icon, color: textColor),
        title: Text(title, style: TextStyle(color: textColor)),
        onTap: onTap,
      );
}
