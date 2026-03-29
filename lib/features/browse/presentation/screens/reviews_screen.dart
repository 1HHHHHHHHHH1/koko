import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/supabase/supabase_service.dart';
import '../../../../models/rating.dart';

final reviewsProvider = FutureProvider.family<List<Rating>, String>(
  (ref, targetId) async {
    final service = ref.watch(supabaseServiceProvider);
    return service.getRatingsForTarget(targetId);
  },
);

class ReviewsScreen extends ConsumerWidget {
  final String targetId;
  final String title;

  const ReviewsScreen({
    super.key,
    required this.targetId,
    this.title = 'Reviews',
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final reviewsAsync = ref.watch(reviewsProvider(targetId));

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: reviewsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Failed to load reviews:\n$error',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.red.shade600,
              ),
            ),
          ),
        ),
        data: (ratings) {
          if (ratings.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.rate_review_outlined,
                      size: 64,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No reviews yet',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Ratings and written comments will appear here.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: ratings.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final rating = ratings[index];
              final hasComment =
                  rating.comment != null && rating.comment!.trim().isNotEmpty;

              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            backgroundImage: rating.userAvatar != null
                                ? NetworkImage(rating.userAvatar!)
                                : null,
                            child: rating.userAvatar == null
                                ? Text(
                                    rating.userName.isNotEmpty
                                        ? rating.userName[0].toUpperCase()
                                        : '?',
                                  )
                                : null,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  rating.userName,
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: List.generate(5, (starIndex) {
                                    return Icon(
                                      starIndex < rating.score
                                          ? Icons.star
                                          : Icons.star_border,
                                      size: 16,
                                      color: Colors.amber[700],
                                    );
                                  }),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            DateFormat('dd/MM/yyyy').format(rating.createdAt),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        hasComment
                            ? rating.comment!.trim()
                            : 'No written comment',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: hasComment ? null : Colors.grey[600],
                          fontStyle:
                              hasComment ? FontStyle.normal : FontStyle.italic,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
