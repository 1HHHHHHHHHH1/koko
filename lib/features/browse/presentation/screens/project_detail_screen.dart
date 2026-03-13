import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import '../../../../core/router/app_router.dart';
import '../../../../providers/project_provider.dart';
import '../../../../providers/likes_provider.dart';
import '../../../../providers/ratings_provider.dart';
import '../../../../widgets/common/rating_display.dart';

class ProjectDetailScreen extends ConsumerStatefulWidget {
  final String projectId;

  const ProjectDetailScreen({super.key, required this.projectId});

  @override
  ConsumerState<ProjectDetailScreen> createState() =>
      _ProjectDetailScreenState();
}

class _ProjectDetailScreenState extends ConsumerState<ProjectDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(projectsProvider.notifier).fetchProjectById(widget.projectId);
      ref.read(ratingsProvider.notifier).fetchRatingSummary(widget.projectId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final projectsState = ref.watch(projectsProvider);
    final project = projectsState.selectedProject;
    final ratingSummary = ref.watch(ratingSummaryProvider(widget.projectId));
    final isLiked = ref.watch(isLikedProvider(widget.projectId));

    if (projectsState.isLoading && project == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (project == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Project not found')),
      );
    }

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // App Bar
          SliverAppBar(
            expandedHeight: 180,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
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
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 80, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              project.stage,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              project.industry,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        project.title,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: Icon(
                  isLiked ? Icons.favorite : Icons.favorite_outline,
                  color: isLiked ? Colors.red : Colors.white,
                ),
                onPressed: () {
                  ref
                      .read(likesProvider.notifier)
                      .toggleLike(project.id, 'project');
                },
              ),
            ],
          ),

          // Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Funding Progress Card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Funding Goal',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  Text(
                                    project.formattedFundingGoal,
                                    style:
                                        theme.textTheme.headlineSmall?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: theme.colorScheme.primary,
                                    ),
                                  ),
                                ],
                              ),
                              if (ratingSummary != null)
                                Row(
                                  children: [
                                    Icon(
                                      Icons.star,
                                      color: Colors.amber[700],
                                      size: 24,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      ratingSummary.formattedRating,
                                      style: theme.textTheme.titleLarge
                                          ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      ' (${ratingSummary.totalRatings})',
                                      style:
                                          theme.textTheme.bodyMedium?.copyWith(
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                          if (project.fundingRaised != null) ...[
                            const SizedBox(height: 16),
                            LinearProgressIndicator(
                              value: project.fundingProgress / 100,
                              backgroundColor: Colors.grey[200],
                              borderRadius: BorderRadius.circular(4),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${project.fundingProgress.toStringAsFixed(1)}% funded',
                              style: theme.textTheme.bodySmall,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: () => context.go(Routes.conversations),
                          icon: const Icon(Icons.message),
                          label: const Text('Contact'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _showRatingDialog(context),
                          icon: const Icon(Icons.star),
                          label: const Text('Rate'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Owner Info
                  _SectionTitle(title: 'Created By'),
                  const SizedBox(height: 8),
                  Card(
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor:
                            theme.colorScheme.primary.withOpacity(0.1),
                        backgroundImage: project.ownerAvatar != null
                            ? NetworkImage(project.ownerAvatar!)
                            : null,
                        child: project.ownerAvatar == null
                            ? Text(
                                project.ownerName.isNotEmpty
                                    ? project.ownerName[0].toUpperCase()
                                    : 'E',
                                style: TextStyle(
                                  color: theme.colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              )
                            : null,
                      ),
                      title: Text(project.ownerName),
                      subtitle: const Text('Entrepreneur'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => context.go('/profile/${project.ownerId}'),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Description
                  _SectionTitle(title: 'About'),
                  const SizedBox(height: 8),
                  Text(
                    project.description,
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 24),

                  // Tags
                  if (project.tags?.isNotEmpty == true) ...[
                    _SectionTitle(title: 'Tags'),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: project.tags!.map((tag) {
                        return Chip(
                          label: Text(tag),
                          backgroundColor: Colors.grey[200],
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Links
                  if (project.website != null || project.videoUrl != null) ...[
                    _SectionTitle(title: 'Links'),
                    const SizedBox(height: 8),
                    if (project.website != null)
                      ListTile(
                        leading: const Icon(Icons.language),
                        title: const Text('Website'),
                        subtitle: Text(project.website!),
                        trailing: const Icon(Icons.open_in_new, size: 18),
                        contentPadding: EdgeInsets.zero,
                        onTap: () {
                          // Open URL
                        },
                      ),
                    if (project.videoUrl != null)
                      ListTile(
                        leading: const Icon(Icons.video_library),
                        title: const Text('Pitch Video'),
                        subtitle: Text(project.videoUrl!),
                        trailing: const Icon(Icons.play_circle_outline),
                        contentPadding: EdgeInsets.zero,
                        onTap: () {
                          // Open video
                        },
                      ),
                  ],

                  // Rating Summary
                  if (ratingSummary != null) ...[
                    const SizedBox(height: 24),
                    _SectionTitle(title: 'Ratings'),
                    const SizedBox(height: 8),
                    RatingDisplay(summary: ratingSummary),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showRatingDialog(BuildContext context) {
    double rating = 0;
    final commentController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Rate this Project'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RatingBar.builder(
                initialRating: 0,
                minRating: 1,
                direction: Axis.horizontal,
                allowHalfRating: false,
                itemCount: 5,
                itemPadding: const EdgeInsets.symmetric(horizontal: 4),
                itemBuilder: (context, _) => const Icon(
                  Icons.star,
                  color: Colors.amber,
                ),
                onRatingUpdate: (value) {
                  rating = value;
                },
              ),
              const SizedBox(height: 16),
              TextField(
                controller: commentController,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'Add a comment (optional)',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                if (rating > 0) {
                  await ref.read(ratingsProvider.notifier).submitRating(
                        targetId: widget.projectId,
                        targetType: 'project',
                        score: rating.toInt(),
                        comment: commentController.text.isEmpty
                            ? null
                            : commentController.text,
                      );
                  if (mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Rating submitted!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                }
              },
              child: const Text('Submit'),
            ),
          ],
        );
      },
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
    );
  }
}
