import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import '../../../../core/router/app_router.dart';
import '../../../../providers/investor_provider.dart';
import '../../../../providers/likes_provider.dart';
import '../../../../providers/ratings_provider.dart';
import '../../../../widgets/common/rating_display.dart';

class InvestorDetailScreen extends ConsumerStatefulWidget {
  final String investorId;

  const InvestorDetailScreen({super.key, required this.investorId});

  @override
  ConsumerState<InvestorDetailScreen> createState() =>
      _InvestorDetailScreenState();
}

class _InvestorDetailScreenState extends ConsumerState<InvestorDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(investorsProvider.notifier).fetchInvestorById(widget.investorId);
      ref.read(ratingsProvider.notifier).fetchRatingSummary(widget.investorId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final investorsState = ref.watch(investorsProvider);
    final investor = investorsState.selectedInvestor;
    final ratingSummary = ref.watch(ratingSummaryProvider(widget.investorId));
    final isLiked = ref.watch(isLikedProvider(widget.investorId));

    if (investorsState.isLoading && investor == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (investor == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Investor not found')),
      );
    }

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // App Bar
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      theme.colorScheme.secondary,
                      theme.colorScheme.primary,
                    ],
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 40),
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.white,
                        backgroundImage: investor.avatar != null
                            ? NetworkImage(investor.avatar!)
                            : null,
                        child: investor.avatar == null
                            ? Text(
                                investor.name.isNotEmpty
                                    ? investor.name[0].toUpperCase()
                                    : 'I',
                                style: TextStyle(
                                  fontSize: 36,
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.secondary,
                                ),
                              )
                            : null,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        investor.name,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (investor.company != null || investor.position != null)
                        Text(
                          [investor.position, investor.company]
                              .where((e) => e != null)
                              .join(' at '),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: Colors.white.withOpacity(0.9),
                          ),
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
                      .toggleLike(investor.id, 'investor');
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
                  // Rating Summary
                  if (ratingSummary != null)
                    RatingDisplay(summary: ratingSummary),
                  const SizedBox(height: 16),

                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: () => context.go(Routes.conversations),
                          icon: const Icon(Icons.message),
                          label: const Text('Message'),
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

                  // Bio
                  if (investor.bio != null) ...[
                    Text(
                      'About',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      investor.bio!,
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Investment Criteria
                  if (investor.criteria != null) ...[
                    Text(
                      'Investment Criteria',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _CriteriaRow(
                              icon: Icons.attach_money,
                              label: 'Investment Range',
                              value: investor.criteria!.investmentRange,
                            ),
                            const Divider(height: 24),
                            _CriteriaRow(
                              icon: Icons.category,
                              label: 'Industries',
                              value: investor.criteria!.industries.join(', '),
                            ),
                            const Divider(height: 24),
                            _CriteriaRow(
                              icon: Icons.stairs,
                              label: 'Stages',
                              value: investor.criteria!.stages.join(', '),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Location
                  if (investor.location != null) ...[
                    _InfoRow(
                      icon: Icons.location_on_outlined,
                      label: 'Location',
                      value: investor.location!,
                    ),
                    const SizedBox(height: 16),
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
          title: const Text('Rate this Investor'),
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
                        targetId: widget.investorId,
                        targetType: 'investor',
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

class _CriteriaRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _CriteriaRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: theme.colorScheme.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: Colors.grey[600],
          ),
        ),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
