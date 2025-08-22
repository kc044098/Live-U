
import 'package:djs_live_stream/features/mine/user_repository.dart';
import 'package:djs_live_stream/features/mine/user_repository_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'model/fan_user.dart';

// fans_provider.dart（或放在你現有的 provider 檔內）

class MemberFansState {
  final List<MemberFanUser> items;
  final int page;        // 1-based
  final int totalCount;  // API 回傳的 count
  final bool isLoading;

  const MemberFansState({
    required this.items,
    required this.page,
    required this.totalCount,
    required this.isLoading,
  });

  bool get hasMore => items.length < totalCount;

  static MemberFansState initial() =>
      const MemberFansState(items: [], page: 0, totalCount: 0, isLoading: false);

  MemberFansState copyWith({
    List<MemberFanUser>? items,
    int? page,
    int? totalCount,
    bool? isLoading,
  }) {
    return MemberFansState(
      items: items ?? this.items,
      page: page ?? this.page,
      totalCount: totalCount ?? this.totalCount,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class MemberFansNotifier extends AutoDisposeNotifier<MemberFansState> {
  late final UserRepository _repo;

  @override
  MemberFansState build() {
    _repo = ref.read(userRepositoryProvider);
    // 保活（避免切 tab 被回收）
    final link = ref.keepAlive();
    ref.onDispose(() => link.close());
    return MemberFansState.initial();
  }

  Future<void> loadFirstPage() async {
    if (state.isLoading) return;
    state = state.copyWith(isLoading: true);

    final page1 = await _repo.fetchMemberFans(page: 1);
    state = MemberFansState(
      items: page1.list,
      page: 1,
      totalCount: page1.count,
      isLoading: false,
    );
  }

  Future<void> loadNextPage() async {
    if (state.isLoading || !state.hasMore) return;
    state = state.copyWith(isLoading: true);

    final next = state.page + 1;
    final p = await _repo.fetchMemberFans(page: next);
    state = state.copyWith(
      items: [...state.items, ...p.list],
      page: next,
      totalCount: p.count, // 後端 count 為總數；帶回一致即可
      isLoading: false,
    );
  }
}

final memberFansProvider =
AutoDisposeNotifierProvider<MemberFansNotifier, MemberFansState>(
    MemberFansNotifier.new);
