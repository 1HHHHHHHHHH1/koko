import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../providers/investor_provider.dart';
import '../../../../providers/likes_provider.dart';
import '../../../../providers/ratings_provider.dart';
import '../../../../providers/messaging_provider.dart';
import 'reviews_screen.dart';
import '../../../../widgets/common/rating_display.dart';

class _InvestorLocationDetails {
  final String? location;
  final String? country;

  const _InvestorLocationDetails({
    this.location,
    this.country,
  });
}

_InvestorLocationDetails _parseInvestorLocation(String? rawLocation) {
  if (rawLocation == null) return const _InvestorLocationDetails();

  final cleaned = rawLocation.trim();
  if (cleaned.isEmpty) return const _InvestorLocationDetails();

  final parts = cleaned
      .split(',')
      .map((part) => part.trim())
      .where((part) => part.isNotEmpty)
      .toList();

  if (parts.length < 2) {
    return _InvestorLocationDetails(location: cleaned);
  }

  final country = parts.removeLast();
  final location = parts.join(', ');

  return _InvestorLocationDetails(
    location: location.isEmpty ? null : location,
    country: country,
  );
}

Uri? _buildInvestorUri(String rawUrl) {
  final cleaned = rawUrl.trim();
  if (cleaned.isEmpty) return null;

  final hasScheme = RegExp(r'^[a-zA-Z][a-zA-Z0-9+.-]*://').hasMatch(cleaned);
  return Uri.tryParse(hasScheme ? cleaned : 'https://$cleaned');
}

String _formatInvestorLinkLabel(String rawUrl) {
  return rawUrl
      .trim()
      .replaceFirst(RegExp(r'^https?://', caseSensitive: false), '')
      .replaceFirst(RegExp(r'/$', caseSensitive: false), '');
}

Future<void> _openInvestorLink(BuildContext context, String rawUrl) async {
  final uri = _buildInvestorUri(rawUrl);
  if (uri == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('This link is not valid.')),
    );
    return;
  }

  final launched = await launchUrl(uri, mode: LaunchMode.platformDefault);
  if (!launched && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Could not open ${uri.toString()}')),
    );
  }
}

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
    final locationDetails = _parseInvestorLocation(investor?.location);
    final investorDescription = investor?.criteria?.additionalNotes?.trim();
    final hasDetails =
        locationDetails.location != null || locationDetails.country != null;
    final hasLinks = (investor?.website?.trim().isNotEmpty ?? false) ||
        (investor?.linkedIn?.trim().isNotEmpty ?? false);

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
                  if (ratingSummary != null) ...[
                    RatingDisplay(summary: ratingSummary),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => ReviewsScreen(
                                targetId: widget.investorId,
                                title: '${investor.name} Reviews',
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.rate_review_outlined),
                        label: const Text('View Reviews'),
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),

                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: () async {
                            final convId = await ref
                                .read(messagingProvider.notifier)
                                .getOrCreateConversation(investor.userId);
                            if (context.mounted) {
                              context.push('/messages/$convId');
                            }
                          },
                          icon: const Icon(Icons.message),
                          label: const Text('Message'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _showRatingDialog,
                          icon: const Icon(Icons.star),
                          label: const Text('Rate'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  if (investorDescription?.isNotEmpty ?? false) ...[
                    Text(
                      'Description',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      investorDescription!,
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 24),
                  ],

                  if (hasDetails) ...[
                    Text(
                      'Details',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (locationDetails.location != null)
                      _InfoRow(
                        icon: Icons.location_on_outlined,
                        label: 'Location',
                        value: locationDetails.location!,
                      ),
                    if (locationDetails.country != null)
                      _InfoRow(
                        icon: Icons.public,
                        label: 'Country',
                        value: locationDetails.country!,
                      ),
                    const SizedBox(height: 12),
                  ],

                  if (hasLinks) ...[
                    Text(
                      'Links',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (investor.website?.trim().isNotEmpty ?? false)
                      _LinkRow(
                        icon: Icons.language,
                        label: 'Website',
                        value: _formatInvestorLinkLabel(investor.website!),
                        onTap: () =>
                            _openInvestorLink(context, investor.website!),
                      ),
                    if (investor.linkedIn?.trim().isNotEmpty ?? false)
                      _LinkRow(
                        icon: Icons.link,
                        label: 'LinkedIn',
                        value: _formatInvestorLinkLabel(investor.linkedIn!),
                        onTap: () =>
                            _openInvestorLink(context, investor.linkedIn!),
                      ),
                    const SizedBox(height: 12),
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
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showRatingDialog() {
    double rating = 0;
    final commentController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) {
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
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                if (rating > 0) {
                  final messenger = ScaffoldMessenger.of(context);
                  await ref.read(ratingsProvider.notifier).submitRating(
                        targetId: widget.investorId,
                        targetType: 'investor',
                        score: rating.toInt(),
                        comment: commentController.text.isEmpty
                            ? null
                            : commentController.text,
                      );
                  if (!mounted) return;
                  Navigator.of(context).pop();
                  messenger.showSnackBar(
                    const SnackBar(
                      content: Text('Rating submitted!'),
                      backgroundColor: Colors.green,
                    ),
                  );
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

    return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 20, color: Colors.grey[600]),
            const SizedBox(width: 8),
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
        ));
  }
}

class _LinkRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;

  const _LinkRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final linkColor = Colors.blue.shade700;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 20, color: Colors.grey[600]),
              const SizedBox(width: 8),
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
                        color: linkColor,
                        fontWeight: FontWeight.w500,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.open_in_new, size: 16, color: linkColor),
            ],
          ),
        ),
      ),
    );
  }
}
