import 'package:flutter/material.dart';
import '../../models/match.dart';

class MatchCard extends StatelessWidget {
  final Match match;
  final VoidCallback onTap;
  final VoidCallback? onMessage;

  const MatchCard({
    super.key,
    required this.match,
    required this.onTap,
    this.onMessage,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isInvestorMatch = match.isInvestorMatch;

    // Get display data
    final String name = isInvestorMatch
        ? match.investor?.name ?? 'Investor'
        : match.project?.title ?? 'Project';
    final String? subtitle = isInvestorMatch
        ? match.investor?.company
        : match.project?.ownerName;
    final String? avatar = isInvestorMatch
        ? match.investor?.avatar
        : match.project?.ownerAvatar;

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
                radius: 28,
                backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                backgroundImage: avatar != null ? NetworkImage(avatar) : null,
                child: avatar == null
                    ? Text(
                        name.isNotEmpty ? name[0].toUpperCase() : '?',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 12),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 8),
                    // Match percentage and criteria
                    Row(
                      children: [
                        _MatchBadge(percentage: match.matchPercentage),
                        if (match.matchingCriteria?.isNotEmpty == true) ...[
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              match.matchingCriteria!.take(2).join(', '),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: Colors.grey[500],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              // Actions
              Column(
                children: [
                  if (onMessage != null)
                    IconButton(
                      onPressed: onMessage,
                      icon: const Icon(Icons.message_outlined),
                      style: IconButton.styleFrom(
                        backgroundColor:
                            theme.colorScheme.primary.withOpacity(0.1),
                      ),
                    ),
                  const SizedBox(height: 4),
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

class _MatchBadge extends StatelessWidget {
  final double percentage;

  const _MatchBadge({required this.percentage});

  Color _getColor() {
    if (percentage >= 80) return Colors.green;
    if (percentage >= 60) return Colors.orange;
    return Colors.grey;
  }

  @override
  Widget build(BuildContext context) {
    final color = _getColor();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.auto_awesome,
            size: 14,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            '${percentage.toStringAsFixed(0)}% Match',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
