// 狀態
import 'package:djs_live_stream/features/wallet/model/withdraw_record.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../wallet_repository.dart';

class WithdrawListState {
  final List<WithdrawRecord> items;
  final int page;
  final bool isLoading;
  final bool hasMore;
  final String? error;

  const WithdrawListState({
    this.items = const [],
    this.page = 1,
    this.isLoading = false,
    this.hasMore = true,
    this.error,
  });

  WithdrawListState copyWith({
    List<WithdrawRecord>? items,
    int? page,
    bool? isLoading,
    bool? hasMore,
    String? error,
  }) {
    return WithdrawListState(
      items: items ?? this.items,
      page: page ?? this.page,
      isLoading: isLoading ?? this.isLoading,
      hasMore: hasMore ?? this.hasMore,
      error: error,
    );
  }
}

class WithdrawListController extends StateNotifier<WithdrawListState> {
  WithdrawListController(this._repo) : super(const WithdrawListState());
  final WalletRepository _repo;

  Future<void> loadFirstPage() async {
    if (state.isLoading) return;
    state = state.copyWith(isLoading: true, error: null, page: 1);
    try {
      final list = await _repo.fetchWithdrawList(page: 1);
      list.sort((a, b) => b.createAt.compareTo(a.createAt));
      state = state.copyWith(
        items: list,
        page: 1,
        isLoading: false,
        hasMore: list.isNotEmpty,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> loadNextPage() async {
    if (state.isLoading || !state.hasMore) return;
    final next = state.page + 1;
    state = state.copyWith(isLoading: true, error: null);
    try {
      final list = await _repo.fetchWithdrawList(page: next);

      final merged = <WithdrawRecord>[...state.items, ...list]
        ..sort((a, b) => b.createAt.compareTo(a.createAt));

      state = state.copyWith(
        items: merged,
        page: next,
        isLoading: false,
        hasMore: list.isNotEmpty,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

final withdrawListProvider =
StateNotifierProvider<WithdrawListController, WithdrawListState>((ref) {
  final repo = ref.watch(walletRepositoryProvider);
  return WithdrawListController(repo)..loadFirstPage();
});
