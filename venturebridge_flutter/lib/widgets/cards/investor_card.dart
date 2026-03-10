import 'package:flutter/material.dart';
import '../../models/investor.dart';

class InvestorCard extends StatelessWidget {
  final Investor investor;
  final VoidCallback onTap;
  final VoidCallback? onLike;
  final bool showLike;

  const InvestorCard({
    super.key,
    required this.investor,
    required this.onTap,
    this.onLike,
    this.showLike = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Avatar
              CircleAvatar(
                radius: 32,
                backgroundColor: theme.colorScheme.secondary.withOpacity(0.1),
                backgroundImage:
                    investor.avatar != null ? NetworkImage(investor.avatar!) : null,
                child: investor.avatar == null
                    ? Text(
                        investor.name.isNotEmpty
                            ? investor.name[0].toUpperCase()
                            : 'I',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.secondary,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 16),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name
                    Text(
                      investor.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    // Company & Position
                    if (investor.company != null || investor.position != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        [investor.position, investor.company]
                            .where((e) => e != null)
                            .join(' at '),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 8),

                    // Investment Criteria
                    if (investor.criteria != null) ...[
                      Row(
                        children: [
                          Icon(
                            Icons.attach_money,
                            size: 14,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              investor.criteria!.investmentRange,
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: theme.colorScheme.primary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 4),

                    // Industries Tags
                    if (investor.criteria?.industries.isNotEmpty == true)
                      Wrap(
                        spacing: 4,
                        runSpacing: 4,
                        children: investor.criteria!.industries.take(3).map((ind) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              ind,
                              style: const TextStyle(fontSize: 10),
                            ),
                          );
                        }).toList(),
                      ),
                  ],
                ),
              ),

              // Actions Column
              Column(
                children: [
                  // Rating
                  if (investor.averageRating != null) ...[
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.star,
                          size: 16,
                          color: Colors.amber[700],
                        ),
                        const SizedBox(width: 2),
                        Text(
                          investor.averageRating!.toStringAsFixed(1),
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                  ],
                  // Like Button
                  if (showLike && onLike != null)
                    IconButton(
                      onPressed: onLike,
                      icon: Icon(
                        investor.isLiked == true
                            ? Icons.favorite
                            : Icons.favorite_outline,
                        color:
                            investor.isLiked == true ? Colors.red : Colors.grey,
                      ),
                      iconSize: 24,
                    ),
                  Icon(
                    Icons.chevron_right,
                    color: Colors.grey[400],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
