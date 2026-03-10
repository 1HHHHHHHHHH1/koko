import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/network/api_service.dart';
import '../models/user.dart';
import '../models/project.dart';
import '../models/investor.dart';

// Search State
class SearchState {
  final String query;
  final String? filterType; // 'investor', 'entrepreneur', 'project'
  final List<User> userResults;
  final List<Project> projectResults;
  final List<Investor> investorResults;
  final bool isLoading;
  final String? error;
  final bool hasSearched;

  const SearchState({
    this.query = '',
    this.filterType,
    this.userResults = const [],
    this.projectResults = const [],
    this.investorResults = const [],
    this.isLoading = false,
    this.error,
    this.hasSearched = false,
  });

  SearchState copyWith({
    String? query,
    String? filterType,
    List<User>? userResults,
    List<Project>? projectResults,
    List<Investor>? investorResults,
    bool? isLoading,
    String? error,
    bool? hasSearched,
  }) {
    return SearchState(
      query: query ?? this.query,
      filterType: filterType,
      userResults: userResults ?? this.userResults,
      projectResults: projectResults ?? this.projectResults,
      investorResults: investorResults ?? this.investorResults,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      hasSearched: hasSearched ?? this.hasSearched,
    );
  }

  int get totalResults =>
      userResults.length + projectResults.length + investorResults.length;

  bool get hasResults => totalResults > 0;
}

// Search Notifier
class SearchNotifier extends StateNotifier<SearchState> {
  final ApiService _apiService;

  SearchNotifier(this._apiService) : super(const SearchState());

  void setQuery(String query) {
    state = state.copyWith(query: query);
  }

  void setFilterType(String? type) {
    state = state.copyWith(filterType: type);
  }

  Future<void> search() async {
    if (state.query.isEmpty) return;

    state = state.copyWith(isLoading: true, error: null);

    try {
      final results = await _apiService.search(
        query: state.query,
        type: state.filterType,
      );

      state = state.copyWith(
        userResults: results.users,
        projectResults: results.projects,
        investorResults: results.investors,
        isLoading: false,
        hasSearched: true,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
        hasSearched: true,
      );
    }
  }

  void clearSearch() {
    state = const SearchState();
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

// Provider
final searchProvider =
    StateNotifierProvider<SearchNotifier, SearchState>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return SearchNotifier(apiService);
});
