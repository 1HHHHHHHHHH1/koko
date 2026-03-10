import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../providers/search_provider.dart';
import '../../../../widgets/cards/project_card.dart';
import '../../../../widgets/cards/investor_card.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _searchController = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _focusNode.requestFocus();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _performSearch() {
    final query = _searchController.text.trim();
    if (query.isNotEmpty) {
      ref.read(searchProvider.notifier).setQuery(query);
      ref.read(searchProvider.notifier).search();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final searchState = ref.watch(searchProvider);

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          focusNode: _focusNode,
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            hintText: 'Search investors, projects...',
            border: InputBorder.none,
            fillColor: Colors.transparent,
            filled: true,
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _searchController.clear();
                      ref.read(searchProvider.notifier).clearSearch();
                    },
                  )
                : null,
          ),
          onSubmitted: (_) => _performSearch(),
          onChanged: (value) {
            setState(() {});
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: _performSearch,
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Chips
          Container(
            height: 50,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _FilterChip(
                  label: 'All',
                  isSelected: searchState.filterType == null,
                  onTap: () {
                    ref.read(searchProvider.notifier).setFilterType(null);
                    if (searchState.query.isNotEmpty) {
                      ref.read(searchProvider.notifier).search();
                    }
                  },
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Investors',
                  isSelected:
                      searchState.filterType == AppConstants.searchTypeInvestor,
                  onTap: () {
                    ref.read(searchProvider.notifier).setFilterType(
                          AppConstants.searchTypeInvestor,
                        );
                    if (searchState.query.isNotEmpty) {
                      ref.read(searchProvider.notifier).search();
                    }
                  },
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Entrepreneurs',
                  isSelected: searchState.filterType ==
                      AppConstants.searchTypeEntrepreneur,
                  onTap: () {
                    ref.read(searchProvider.notifier).setFilterType(
                          AppConstants.searchTypeEntrepreneur,
                        );
                    if (searchState.query.isNotEmpty) {
                      ref.read(searchProvider.notifier).search();
                    }
                  },
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Projects',
                  isSelected:
                      searchState.filterType == AppConstants.searchTypeProject,
                  onTap: () {
                    ref.read(searchProvider.notifier).setFilterType(
                          AppConstants.searchTypeProject,
                        );
                    if (searchState.query.isNotEmpty) {
                      ref.read(searchProvider.notifier).search();
                    }
                  },
                ),
              ],
            ),
          ),

          // Results
          Expanded(
            child: searchState.isLoading
                ? const Center(child: CircularProgressIndicator())
                : !searchState.hasSearched
                    ? _SearchPlaceholder()
                    : searchState.totalResults == 0
                        ? _NoResults(query: searchState.query)
                        : _SearchResults(
                            searchState: searchState,
                            onInvestorTap: (id) => context.go('/investor/$id'),
                            onProjectTap: (id) => context.go('/project/$id'),
                            onUserTap: (id) => context.go('/profile/$id'),
                          ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
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

class _SearchPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search,
            size: 64,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 16),
          Text(
            'Search for investors, projects,\nor entrepreneurs',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.grey[500],
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _NoResults extends StatelessWidget {
  final String query;

  const _NoResults({required this.query});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No results found',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Try different keywords or filters',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
        ],
      ),
    );
  }
}

class _SearchResults extends StatelessWidget {
  final SearchState searchState;
  final Function(String) onInvestorTap;
  final Function(String) onProjectTap;
  final Function(String) onUserTap;

  const _SearchResults({
    required this.searchState,
    required this.onInvestorTap,
    required this.onProjectTap,
    required this.onUserTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Investors Section
        if (searchState.investorResults.isNotEmpty) ...[
          _SectionHeader(
            title: 'Investors',
            count: searchState.investorResults.length,
          ),
          const SizedBox(height: 8),
          ...searchState.investorResults.map((investor) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: InvestorCard(
                investor: investor,
                onTap: () => onInvestorTap(investor.id),
              ),
            );
          }),
          const SizedBox(height: 16),
        ],

        // Projects Section
        if (searchState.projectResults.isNotEmpty) ...[
          _SectionHeader(
            title: 'Projects',
            count: searchState.projectResults.length,
          ),
          const SizedBox(height: 8),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.85,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: searchState.projectResults.length,
            itemBuilder: (context, index) {
              final project = searchState.projectResults[index];
              return ProjectCard(
                project: project,
                onTap: () => onProjectTap(project.id),
              );
            },
          ),
          const SizedBox(height: 16),
        ],

        // Users/Entrepreneurs Section
        if (searchState.userResults.isNotEmpty) ...[
          _SectionHeader(
            title: 'Users',
            count: searchState.userResults.length,
          ),
          const SizedBox(height: 8),
          ...searchState.userResults.map((user) {
            return Card(
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                  backgroundImage:
                      user.avatar != null ? NetworkImage(user.avatar!) : null,
                  child: user.avatar == null
                      ? Text(
                          user.name.isNotEmpty
                              ? user.name[0].toUpperCase()
                              : 'U',
                          style: TextStyle(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : null,
                ),
                title: Text(user.name),
                subtitle: Text(user.userType == 'investor'
                    ? 'Investor'
                    : 'Entrepreneur'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => onUserTap(user.id),
              ),
            );
          }),
        ],
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final int count;

  const _SectionHeader({
    required this.title,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        Text(
          '$count found',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
              ),
        ),
      ],
    );
  }
}
