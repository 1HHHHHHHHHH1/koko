import 'package:flutter/material.dart';
import '../../models/rating.dart';

class RatingDisplay extends StatelessWidget {
  final RatingSummary summary;

  const RatingDisplay({super.key, required this.summary});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Average Rating
            Column(
              children: [
                Text(
                  summary.formattedRating,
                  style: theme.textTheme.headlineLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Row(
                  children: List.generate(5, (index) {
                    final filled = index < summary.averageRating.round();
                    return Icon(
                      filled ? Icons.star : Icons.star_border,
                      color: Colors.amber[700],
                      size: 16,
                    );
                  }),
                ),
                const SizedBox(height: 4),
                Text(
                  '${summary.totalRatings} ratings',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            const SizedBox(width: 24),
            // Distribution
            Expanded(
              child: Column(
                children: List.generate(5, (index) {
                  final star = 5 - index;
                  final count = summary.distribution[star] ?? 0;
                  final percentage = summary.totalRatings > 0
                      ? count / summary.totalRatings
                      : 0.0;

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      children: [
                        Text(
                          '$star',
                          style: theme.textTheme.bodySmall,
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.star,
                          size: 12,
                          color: Colors.amber[700],
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(2),
                            child: LinearProgressIndicator(
                              value: percentage,
                              backgroundColor: Colors.grey[200],
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.amber[700]!,
                              ),
                              minHeight: 6,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 24,
                          child: Text(
                            '$count',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.grey[600],
                            ),
                            textAlign: TextAlign.end,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
