import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../user_repository.dart';
import '../user_repository_provider.dart';
import 'invite_user_item.dart';

class InviteListState {
  final List<InviteUserItem> items;
  final bool isLoading;
  final bool hasMore;
  final int page;
  final String? error;
  final int totalCount;

  const InviteListState({
    this.items = const [],
    this.isLoading = false,
    this.hasMore = true,
    this.page = 1,
    this.error,
    this.totalCount = 0,
  });

  InviteListState copyWith({
    List<InviteUserItem>? items,
    bool? isLoading,
    bool? hasMore,
    int? page,
    String? error, // 若要清空錯誤，傳入空字串或 null 皆可，這裡直接覆蓋
    int? totalCount,
  }) {
    return InviteListState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      hasMore: hasMore ?? this.hasMore,
      page: page ?? this.page,
      error: error,
      totalCount: totalCount ?? this.totalCount,
    );
  }
}

class InviteListController extends StateNotifier<InviteListState> {
  final UserRepository repo;

  InviteListController(this.repo) : super(const InviteListState());

  Future<void> loadFirstPage() async {
    state = state.copyWith(isLoading: true, error: null, page: 1);
    try {
      final page1 = await repo.fetchInviteList(page: 1);
      state = state.copyWith(
        items: page1.list,
        page: 1,
        isLoading: false,
        hasMore: page1.list.isNotEmpty,
        totalCount: page1.count,
        error: null,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: '$e');
    }
  }

  Future<void> loadNextPage() async {
    if (state.isLoading || !state.hasMore) return;
    final next = state.page + 1;
    state = state.copyWith(isLoading: true);
    try {
      final res = await repo.fetchInviteList(page: next);
      // 去重：以 id 當 key
      final existing = {for (final x in state.items) x.id};
      final fresh = res.list.where((e) => existing.add(e.id)).toList();

      state = state.copyWith(
        items: [...state.items, ...fresh],
        page: next,
        isLoading: false,
        hasMore: res.list.isNotEmpty,
        totalCount: res.count > 0 ? res.count : state.totalCount,
        error: null,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: '$e');
    }
  }
}

// Provider
final inviteListProvider =
StateNotifierProvider<InviteListController, InviteListState>((ref) {
  final repo = ref.read(userRepositoryProvider);
  return InviteListController(repo);
});
