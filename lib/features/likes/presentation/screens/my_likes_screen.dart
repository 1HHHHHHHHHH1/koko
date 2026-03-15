import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../providers/likes_provider.dart';

class MyLikesScreen extends ConsumerStatefulWidget {
  const MyLikesScreen({super.key});

  @override
  ConsumerState<MyLikesScreen> createState() => _MyLikesScreenState();
}

class _MyLikesScreenState extends ConsumerState<MyLikesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(likesProvider.notifier).fetchMyLikes();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final likesState = ref.watch(likesProvider);

    final investorLikes =
        likesState.likes.where((l) => l.targetType == 'investor').toList();
    final projectLikes =
        likesState.likes.where((l) => l.targetType == 'project').toList();
    final entrepreneurLikes =
        likesState.likes.where((l) => l.targetType == 'entrepreneur').toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Likes'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'Investors (${investorLikes.length})'),
            Tab(text: 'Projects (${projectLikes.length})'),
            Tab(text: 'Entrepreneurs (${entrepreneurLikes.length})'),
          ],
        ),
      ),
      body: likesState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                // Investors Tab
                _LikesList(
                  likes: investorLikes,
                  emptyIcon: Icons.people_outline,
                  emptyTitle: 'No liked investors',
                  emptySubtitle: 'Browse and like investors you\'re interested in',
                  onTap: (id) => context.go('/investor/$id'),
                  onUnlike: (id) {
                    ref.read(likesProvider.notifier).toggleLike(id, 'investor');
                  },
                ),

                // Projects Tab
                _LikesList(
                  likes: projectLikes,
                  emptyIcon: Icons.business_center_outlined,
                  emptyTitle: 'No liked projects',
                  emptySubtitle: 'Browse and like projects you\'re interested in',
                  onTap: (id) => context.go('/project/$id'),
                  onUnlike: (id) {
                    ref.read(likesProvider.notifier).toggleLike(id, 'project');
                  },
                ),

                // Entrepreneurs Tab
                _LikesList(
                  likes: entrepreneurLikes,
                  emptyIcon: Icons.lightbulb_outline,
                  emptyTitle: 'No liked entrepreneurs',
                  emptySubtitle:
                      'Browse and like entrepreneurs you\'re interested in',
                  onTap: (id) => context.go('/profile/$id'),
                  onUnlike: (id) {
                    ref.read(likesProvider.notifier).toggleLike(id, 'entrepreneur');
                  },
                ),
              ],
            ),
    );
  }
}

class _LikesList extends StatelessWidget {
  final List likes;
  final IconData emptyIcon;
  final String emptyTitle;
  final String emptySubtitle;
  final Function(String) onTap;
  final Function(String) onUnlike;

  const _LikesList({
    required this.likes,
    required this.emptyIcon,
    required this.emptyTitle,
    required this.emptySubtitle,
    required this.onTap,
    required this.onUnlike,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (likes.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                emptyIcon,
                size: 64,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                emptyTitle,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                emptySubtitle,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        // Refresh likes
      },
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: likes.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final like = likes[index];
          return Card(
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                child: Icon(
                  _getIconForType(like.targetType),
                  color: theme.colorScheme.primary,
                ),
              ),
              title: Text('${like.targetType.toString().toUpperCase()}'),
              subtitle: Text('ID: ${like.targetId}'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.favorite, color: Colors.red),
                    onPressed: () => onUnlike(like.targetId),
                  ),
                  const Icon(Icons.chevron_right),
                ],
              ),
              onTap: () => onTap(like.targetId),
            ),
          );
        },
      ),
    );
  }

  IconData _getIconForType(String type) {
    switch (type) {
      case 'investor':
        return Icons.account_balance;
      case 'project':
        return Icons.business_center;
      case 'entrepreneur':
        return Icons.lightbulb;
      default:
        return Icons.favorite;
    }
  }
}
