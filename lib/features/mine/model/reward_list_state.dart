import 'package:djs_live_stream/features/mine/model/reward_item.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../user_repository.dart';
import '../user_repository_provider.dart';

class RewardListState {
  final List<RewardItem> items;
  final bool isLoading;
  final bool hasMore;
  final String? error;
  final int page;

  const RewardListState({
    this.items = const [],
    this.isLoading = false,
    this.hasMore = true,
    this.error,
    this.page = 0,
  });

  RewardListState copyWith({
    List<RewardItem>? items,
    bool? isLoading,
    bool? hasMore,
    String? error,
    int? page,
  }) {
    return RewardListState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      hasMore: hasMore ?? this.hasMore,
      error: error,
      page: page ?? this.page,
    );
  }
}

final rewardListProvider =
StateNotifierProvider<RewardListController, RewardListState>((ref) {
  final repo = ref.read(userRepositoryProvider);
  return RewardListController(repo);
});

class RewardListController extends StateNotifier<RewardListState> {
  final UserRepository _repo;
  RewardListController(this._repo) : super(const RewardListState());

  Future<void> loadFirstPage() async {
    state = state.copyWith(isLoading: true, error: null, page: 0, items: []);
    try {
      final page1 = await _repo.fetchRewardList(flag: 3, page: 1);
      state = state.copyWith(
        isLoading: false,
        items: page1.list,
        page: 1,
        hasMore: page1.list.isNotEmpty,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: '$e');
    }
  }

  Future<void> loadNextPage() async {
    if (state.isLoading || !state.hasMore) return;
    state = state.copyWith(isLoading: true, error: null);
    final next = state.page + 1;
    try {
      final res = await _repo.fetchRewardList(flag: 3, page: next);
      // 去重（以 id 為鍵）
      final seen = state.items.map((e) => e.id).toSet();
      final merged = List<RewardItem>.from(state.items)
        ..addAll(res.list.where((e) => seen.add(e.id)));
      state = state.copyWith(
        isLoading: false,
        items: merged,
        page: next,
        hasMore: res.list.isNotEmpty,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: '$e');
    }
  }
}