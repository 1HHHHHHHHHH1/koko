// ✅ investor_provider.dart — مُحدَّث لـ SupabaseService
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/supabase/supabase_service.dart';
import '../models/investor.dart';

class InvestorsState {
  final List<Investor> investors;
  final Investor?      selectedInvestor;
  final InvestmentCriteria? myCriteria;
  final bool           isLoading;
  final String?        error;
  final int            currentPage;
  final bool           hasMore;

  const InvestorsState({
    this.investors       = const [],
    this.selectedInvestor,
    this.myCriteria,
    this.isLoading       = false,
    this.error,
    this.currentPage     = 1,
    this.hasMore         = true,
  });

  InvestorsState copyWith({
    List<Investor>?    investors,
    Investor?          selectedInvestor,
    InvestmentCriteria? myCriteria,
    bool?              isLoading,
    String?            error,
    int?               currentPage,
    bool?              hasMore,
  }) => InvestorsState(
    investors:        investors        ?? this.investors,
    selectedInvestor: selectedInvestor ?? this.selectedInvestor,
    myCriteria:       myCriteria       ?? this.myCriteria,
    isLoading:        isLoading        ?? this.isLoading,
    error:            error,
    currentPage:      currentPage      ?? this.currentPage,
    hasMore:          hasMore          ?? this.hasMore,
  );
}

class InvestorsNotifier extends StateNotifier<InvestorsState> {
  final SupabaseService _service;
  InvestorsNotifier(this._service) : super(const InvestorsState());

  Future<void> fetchInvestors({
    bool    refresh  = false,
    String? sort,
    String? industry,
    String? stage,
  }) async {
    if (state.isLoading) return;
    final page = refresh ? 1 : state.currentPage;
    state = state.copyWith(isLoading: true, error: null, currentPage: page);
    try {
      final list = await _service.getInvestors(
          page: page, industry: industry, stage: stage);
      state = state.copyWith(
        investors:   refresh ? list : [...state.investors, ...list],
        isLoading:   false,
        currentPage: page + 1,
        hasMore:     list.length >= 20,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> fetchInvestorById(String id) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final investor = await _service.getInvestorById(id);
      state = state.copyWith(selectedInvestor: investor, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<bool> updateCriteria(InvestmentCriteria criteria) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _service.updateInvestorCriteria(criteria);
      state = state.copyWith(myCriteria: criteria, isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  void clearSelectedInvestor() => state = state.copyWith(selectedInvestor: null);
  void clearError()             => state = state.copyWith(error: null);
}

final investorsProvider =
    StateNotifierProvider<InvestorsNotifier, InvestorsState>((ref) {
  return InvestorsNotifier(ref.watch(supabaseServiceProvider));
});
