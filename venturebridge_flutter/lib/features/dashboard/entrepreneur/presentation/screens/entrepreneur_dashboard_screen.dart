import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '/core/router/app_router.dart';
import '/providers/auth_provider.dart';
import '/providers/project_provider.dart';
import '/providers/match_provider.dart';
import '/widgets/common/app_drawer.dart';
import '/widgets/cards/match_card.dart';
import '/widgets/cards/project_card.dart';

class EntrepreneurDashboardScreen extends ConsumerStatefulWidget {
  const EntrepreneurDashboardScreen({super.key});

  @override
  ConsumerState<EntrepreneurDashboardScreen> createState() =>
      _EntrepreneurDashboardScreenState();
}

class _EntrepreneurDashboardScreenState
    extends ConsumerState<EntrepreneurDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(projectsProvider.notifier).fetchMyProjects();
      ref.read(matchesProvider.notifier).fetchMatchedInvestors();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = ref.watch(currentUserProvider);
    final projectsState = ref.watch(projectsProvider);
    final matchesState = ref.watch(matchesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => context.go(Routes.search),
          ),
          IconButton(
            icon: const Icon(Icons.message_outlined),
            onPressed: () => context.go(Routes.conversations),
          ),
        ],
      ),
      drawer: const AppDrawer(),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(projectsProvider.notifier).fetchMyProjects();
          await ref.read(matchesProvider.notifier).fetchMatchedInvestors();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome Section
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
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome back,',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                    Text(
                      user?.name ?? 'Entrepreneur',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        _StatChip(
                          icon: Icons.folder_outlined,
                          label: '${projectsState.myProjects.length} Projects',
                        ),
                        const SizedBox(width: 12),
                        _StatChip(
                          icon: Icons.people_outlined,
                          label:
                              '${matchesState.matchedInvestors.length} Matches',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Quick Actions
              Row(
                children: [
                  Expanded(
                    child: _QuickActionCard(
                      icon: Icons.add_business,
                      title: 'Create Project',
                      color: theme.colorScheme.primary,
                      onTap: () => context.go(Routes.createProject),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _QuickActionCard(
                      icon: Icons.search,
                      title: 'Find Investors',
                      color: theme.colorScheme.secondary,
                      onTap: () => context.go(Routes.browseInvestors),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // My Projects Section
              _SectionHeader(
                title: 'My Projects',
                onViewAll: projectsState.myProjects.isNotEmpty
                    ? () {}
                    : null,
              ),
              const SizedBox(height: 12),
              if (projectsState.isLoading)
                const Center(child: CircularProgressIndicator())
              else if (projectsState.myProjects.isEmpty)
                _EmptyState(
                  icon: Icons.folder_outlined,
                  title: 'No Projects Yet',
                  subtitle: 'Create your first project to get started',
                  actionLabel: 'Create Project',
                  onAction: () => context.go(Routes.createProject),
                )
              else
                SizedBox(
                  height: 200,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: projectsState.myProjects.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemBuilder: (context, index) {
                      final project = projectsState.myProjects[index];
                      return SizedBox(
                        width: 280,
                        child: ProjectCard(
                          project: project,
                          onTap: () => context.go('/project/${project.id}'),
                        ),
                      );
                    },
                  ),
                ),
              const SizedBox(height: 24),

              // Matched Investors Section
              _SectionHeader(
                title: 'Matched Investors',
                subtitle: 'Based on your project criteria',
                onViewAll: matchesState.matchedInvestors.isNotEmpty
                    ? () => context.go(Routes.browseInvestors)
                    : null,
              ),
              const SizedBox(height: 12),
              if (matchesState.isLoading)
                const Center(child: CircularProgressIndicator())
              else if (matchesState.matchedInvestors.isEmpty)
                _EmptyState(
                  icon: Icons.people_outlined,
                  title: 'No Matches Yet',
                  subtitle: 'Create a project to find matching investors',
                  actionLabel: 'Browse Investors',
                  onAction: () => context.go(Routes.browseInvestors),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: matchesState.matchedInvestors.length > 5
                      ? 5
                      : matchesState.matchedInvestors.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final match = matchesState.matchedInvestors[index];
                    return MatchCard(
                      match: match,
                      onTap: () => context.go('/investor/${match.targetId}'),
                      onMessage: () {
                        context.go(Routes.conversations);
                      },
                    );
                  },
                ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go(Routes.createProject),
        icon: const Icon(Icons.add),
        label: const Text('New Project'),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _StatChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.white),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.title,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final VoidCallback? onViewAll;

  const _SectionHeader({
    required this.title,
    this.subtitle,
    this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 2),
              Text(
                subtitle!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
              ),
            ],
          ],
        ),
        if (onViewAll != null)
          TextButton(
            onPressed: onViewAll,
            child: const Text('View All'),
          ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String actionLabel;
  final VoidCallback onAction;

  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(icon, size: 48, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: onAction,
            child: Text(actionLabel),
          ),
        ],
      ),
    );
  }
}
