import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/network/api_service.dart';
import '../models/investor.dart';

// Investors State
class InvestorsState {
  final List<Investor> investors;
  final Investor? selectedInvestor;
  final InvestmentCriteria? myCriteria;
  final bool isLoading;
  final String? error;
  final int currentPage;
  final bool hasMore;

  const InvestorsState({
    this.investors = const [],
    this.selectedInvestor,
    this.myCriteria,
    this.isLoading = false,
    this.error,
    this.currentPage = 1,
    this.hasMore = true,
  });

  InvestorsState copyWith({
    List<Investor>? investors,
    Investor? selectedInvestor,
    InvestmentCriteria? myCriteria,
    bool? isLoading,
    String? error,
    int? currentPage,
    bool? hasMore,
  }) {
    return InvestorsState(
      investors: investors ?? this.investors,
      selectedInvestor: selectedInvestor ?? this.selectedInvestor,
      myCriteria: myCriteria ?? this.myCriteria,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      currentPage: currentPage ?? this.currentPage,
      hasMore: hasMore ?? this.hasMore,
    );
  }
}

// Investors Notifier
class InvestorsNotifier extends StateNotifier<InvestorsState> {
  final ApiService _apiService;

  InvestorsNotifier(this._apiService) : super(const InvestorsState());

  Future<void> fetchInvestors({
    bool refresh = false,
    String? sort,
    String? industry,
    String? stage,
  }) async {
    if (state.isLoading) return;

    final page = refresh ? 1 : state.currentPage;
    
    state = state.copyWith(
      isLoading: true,
      error: null,
      currentPage: page,
    );

    try {
      final investors = await _apiService.getInvestors(
        page: page,
        sort: sort,
        industry: industry,
        stage: stage,
      );

      if (refresh) {
        state = state.copyWith(
          investors: investors,
          isLoading: false,
          currentPage: 2,
          hasMore: investors.length >= 20,
        );
      } else {
        state = state.copyWith(
          investors: [...state.investors, ...investors],
          isLoading: false,
          currentPage: page + 1,
          hasMore: investors.length >= 20,
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> fetchInvestorById(String id) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final investor = await _apiService.getInvestorById(id);
      state = state.copyWith(
        selectedInvestor: investor,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<bool> updateCriteria(InvestmentCriteria criteria) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await _apiService.updateInvestorCriteria(criteria);
      state = state.copyWith(
        myCriteria: criteria,
        isLoading: false,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return false;
    }
  }

  void clearSelectedInvestor() {
    state = state.copyWith(selectedInvestor: null);
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

// Provider
final investorsProvider =
    StateNotifierProvider<InvestorsNotifier, InvestorsState>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return InvestorsNotifier(apiService);
});
