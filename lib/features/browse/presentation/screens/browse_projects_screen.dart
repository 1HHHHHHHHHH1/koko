import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../providers/project_provider.dart';
import '../../../../providers/likes_provider.dart';
import '../../../../widgets/cards/project_card.dart';

class BrowseProjectsScreen extends ConsumerStatefulWidget {
  const BrowseProjectsScreen({super.key});

  @override
  ConsumerState<BrowseProjectsScreen> createState() =>
      _BrowseProjectsScreenState();
}

class _BrowseProjectsScreenState extends ConsumerState<BrowseProjectsScreen> {
  final ScrollController _scrollController = ScrollController();
  String? _selectedSort = AppConstants.sortNewest;
  String? _selectedIndustry;
  String? _selectedStage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(projectsProvider.notifier).fetchProjects(refresh: true);
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
      final state = ref.read(projectsProvider);
      if (!state.isLoading && state.hasMore) {
        ref.read(projectsProvider.notifier).fetchProjects(
              sort: _selectedSort,
              industry: _selectedIndustry,
              stage: _selectedStage,
            );
      }
    }
  }

  void _applyFilters() {
    ref.read(projectsProvider.notifier).fetchProjects(
          refresh: true,
          sort: _selectedSort,
          industry: _selectedIndustry,
          stage: _selectedStage,
        );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final projectsState = ref.watch(projectsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Browse Projects'),
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

          // Grid
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                await ref.read(projectsProvider.notifier).fetchProjects(
                      refresh: true,
                      sort: _selectedSort,
                      industry: _selectedIndustry,
                      stage: _selectedStage,
                    );
              },
              child: projectsState.projects.isEmpty
                  ? projectsState.isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.business_center_outlined,
                                size: 64,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No projects found',
                                style: theme.textTheme.titleMedium,
                              ),
                            ],
                          ),
                        )
                  : GridView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(16),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.85,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                      ),
                      itemCount: projectsState.projects.length +
                          (projectsState.hasMore ? 2 : 0),
                      itemBuilder: (context, index) {
                        if (index >= projectsState.projects.length) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }

                        final project = projectsState.projects[index];
                        return ProjectCard(
                          project: project,
                          showLike: true,
                          onTap: () => context.go('/project/${project.id}'),
                          onLike: () {
                            ref.read(likesProvider.notifier).toggleLike(
                                  project.id,
                                  'project',
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
              initialChildSize: 0.7,
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
                                _selectedStage = null;
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
                          const SizedBox(height: 24),
                          Text(
                            'Stage',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: AppConstants.investmentStages.map((stage) {
                              final isSelected = _selectedStage == stage;
                              return FilterChip(
                                label: Text(stage),
                                selected: isSelected,
                                onSelected: (_) {
                                  setModalState(() {
                                    _selectedStage = isSelected ? null : stage;
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
