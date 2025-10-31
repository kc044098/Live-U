import 'package:djs_live_stream/features/mine/user_repository.dart';
import 'package:djs_live_stream/features/mine/user_repository_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'model/focus_user.dart';

class MemberFocusState {
  final List<MemberFocusUser> items;
  final int page;        // 1-based
  final int totalCount;  // API 回傳的 count
  final bool isLoading;

  const MemberFocusState({
    required this.items,
    required this.page,
    required this.totalCount,
    required this.isLoading,
  });

  bool get hasMore => items.length < totalCount;

  static MemberFocusState initial() =>
      const MemberFocusState(items: [], page: 0, totalCount: 0, isLoading: false);

  MemberFocusState copyWith({
    List<MemberFocusUser>? items,
    int? page,
    int? totalCount,
    bool? isLoading,
  }) {
    return MemberFocusState(
      items: items ?? this.items,
      page: page ?? this.page,
      totalCount: totalCount ?? this.totalCount,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class MemberFocusNotifier extends AutoDisposeNotifier<MemberFocusState> {
  late final UserRepository _repo;

  @override
  MemberFocusState build() {
    _repo = ref.read(userRepositoryProvider);
    final link = ref.keepAlive();
    ref.onDispose(() => link.close());
    return MemberFocusState.initial();
  }

  Future<void> loadFirstPage() async {
    if (state.isLoading) return;
    state = state.copyWith(isLoading: true);
    try {
      final page1 = await _repo.fetchMemberFocusList(page: 1);
      state = MemberFocusState(
        items: page1.list,
        page: 1,
        totalCount: page1.count,
        isLoading: false,
      );
    } catch (_) {
      state = state.copyWith(isLoading: false);
      rethrow;
    }
  }

  /// 與 loadFirstPage 相同；提供語意清楚的 API
  Future<void> refresh() => loadFirstPage();

  Future<void> loadNextPage() async {
    if (state.isLoading || !state.hasMore) return;
    state = state.copyWith(isLoading: true);
    try {
      final next = state.page + 1;
      final p = await _repo.fetchMemberFocusList(page: next);
      state = state.copyWith(
        items: [...state.items, ...p.list],
        page: next,
        totalCount: p.count,
        isLoading: false,
      );
    } catch (_) {
      state = state.copyWith(isLoading: false);
      rethrow;
    }
  }
}

final memberFocusProvider =
AutoDisposeNotifierProvider<MemberFocusNotifier, MemberFocusState>(
    MemberFocusNotifier.new);