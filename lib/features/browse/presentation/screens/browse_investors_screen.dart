import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../providers/investor_provider.dart';
import '../../../../providers/likes_provider.dart';
import '../../../../widgets/cards/investor_card.dart';

class BrowseInvestorsScreen extends ConsumerStatefulWidget {
  const BrowseInvestorsScreen({super.key});

  @override
  ConsumerState<BrowseInvestorsScreen> createState() =>
      _BrowseInvestorsScreenState();
}

class _BrowseInvestorsScreenState extends ConsumerState<BrowseInvestorsScreen> {
  final ScrollController _scrollController = ScrollController();
  String? _selectedSort = AppConstants.sortNewest;
  String? _selectedIndustry;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(investorsProvider.notifier).fetchInvestors(refresh: true);
    });
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      final state = ref.read(investorsProvider);
      if (!state.isLoading && state.hasMore) {
        ref.read(investorsProvider.notifier).fetchInvestors(
              sort: _selectedSort,
              industry: _selectedIndustry,
            );
      }
    }
  }

  void _applyFilters() {
    ref.read(investorsProvider.notifier).fetchInvestors(
          refresh: true,
          sort: _selectedSort,
          industry: _selectedIndustry,
        );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final investorsState = ref.watch(investorsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Browse Investors'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showFilterSheet(context),
          ),
        ],
      ),
      body: Column(
        children: [
          // Sort chips
          Container(
            height: 50,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _SortChip(
                  label: 'Newest',
                  isSelected: _selectedSort == AppConstants.sortNewest,
                  onTap: () {
                    setState(() => _selectedSort = AppConstants.sortNewest);
                    _applyFilters();
                  },
                ),
                const SizedBox(width: 8),
                _SortChip(
                  label: 'Highest Rated',
                  isSelected: _selectedSort == AppConstants.sortHighestRated,
                  onTap: () {
                    setState(() => _selectedSort = AppConstants.sortHighestRated);
                    _applyFilters();
                  },
                ),
                const SizedBox(width: 8),
                _SortChip(
                  label: 'Most Liked',
                  isSelected: _selectedSort == AppConstants.sortMostLiked,
                  onTap: () {
                    setState(() => _selectedSort = AppConstants.sortMostLiked);
                    _applyFilters();
                  },
                ),
              ],
            ),
          ),

          // List
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                await ref.read(investorsProvider.notifier).fetchInvestors(
                      refresh: true,
                      sort: _selectedSort,
                      industry: _selectedIndustry,
                    );
              },
              child: investorsState.investors.isEmpty
                  ? investorsState.isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.people_outline,
                                size: 64,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No investors found',
                                style: theme.textTheme.titleMedium,
                              ),
                            ],
                          ),
                        )
                  : ListView.separated(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount: investorsState.investors.length +
                          (investorsState.hasMore ? 1 : 0),
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        if (index >= investorsState.investors.length) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(16),
                              child: CircularProgressIndicator(),
                            ),
                          );
                        }

                        final investor = investorsState.investors[index];
                        return InvestorCard(
                          investor: investor,
                          showLike: true,
                          onTap: () => context.go('/investor/${investor.id}'),
                          onLike: () {
                            ref.read(likesProvider.notifier).toggleLike(
                                  investor.id,
                                  'investor',
                                );
                          },
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }

  void _showFilterSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return DraggableScrollableSheet(
              initialChildSize: 0.6,
              minChildSize: 0.4,
              maxChildSize: 0.9,
              expand: false,
              builder: (context, scrollController) {
                return Column(
                  children: [
                    Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Filters',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          TextButton(
                            onPressed: () {
                              setModalState(() {
                                _selectedIndustry = null;
                              });
                            },
                            child: const Text('Clear'),
                          ),
                        ],
                      ),
                    ),
                    const Divider(),
                    Expanded(
                      child: ListView(
                        controller: scrollController,
                        padding: const EdgeInsets.all(16),
                        children: [
                          Text(
                            'Industry',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: AppConstants.industries.map((industry) {
                              final isSelected = _selectedIndustry == industry;
                              return FilterChip(
                                label: Text(industry),
                                selected: isSelected,
                                onSelected: (_) {
                                  setModalState(() {
                                    _selectedIndustry =
                                        isSelected ? null : industry;
                                  });
                                },
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: () {
                            Navigator.pop(context);
                            setState(() {});
                            _applyFilters();
                          },
                          child: const Text('Apply Filters'),
                        ),
                      ),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }
}

class _SortChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _SortChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: Chip(
        label: Text(label),
        backgroundColor:
            isSelected ? theme.colorScheme.primary : Colors.grey[200],
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : Colors.grey[700],
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
    );
  }
}
