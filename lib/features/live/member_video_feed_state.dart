import 'package:djs_live_stream/features/live/video_repository.dart';
import 'package:djs_live_stream/features/live/video_repository_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/member_video_model.dart';

class MemberFeedState {
  final List<MemberVideoModel> items;
  final int page;        // 目前頁（1-based）
  final int totalCount;  // 後端回傳 count
  final bool isLoading;

  const MemberFeedState({
    required this.items,
    required this.page,
    required this.totalCount,
    required this.isLoading,
  });

  bool get hasMore => items.length < totalCount;

  MemberFeedState copyWith({
    List<MemberVideoModel>? items,
    int? page,
    int? totalCount,
    bool? isLoading,
  }) {
    return MemberFeedState(
      items: items ?? this.items,
      page: page ?? this.page,
      totalCount: totalCount ?? this.totalCount,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  List<MemberVideoModel> updateItemLocal(int id, MemberVideoModel Function(MemberVideoModel) updater) {
    return items.map((e) => e.id == id ? updater(e) : e).toList();
  }

  static MemberFeedState initial() =>
      const MemberFeedState(items: [], page: -1, totalCount: 0, isLoading: false);
}

class MemberFeedNotifier extends AutoDisposeNotifier<MemberFeedState> {
  late final VideoRepository _repo;

  @override
  MemberFeedState build() {
    final link = ref.keepAlive();
    ref.onDispose(() => link.close());
    _repo = ref.read(videoRepositoryProvider);
    return MemberFeedState.initial();
  }

  Future<void> loadFirstPage({int? uid}) async {
    if (state.isLoading) return;
    state = state.copyWith(isLoading: true);

    final page1 = await _repo.fetchMemberVideos(page: 1, uid: uid);
    state = MemberFeedState(
      items: page1.list,
      page: 1,
      totalCount: page1.count,
      isLoading: false,
    );
  }

  Future<void> loadNextPage({int? uid}) async {
    if (state.isLoading || !state.hasMore) return;
    state = state.copyWith(isLoading: true);

    final next = state.page + 1;
    final p = await _repo.fetchMemberVideos(page: next, uid: uid);
    state = state.copyWith(
      items: [...state.items, ...p.list],
      page: next,
      totalCount: p.count,
      isLoading: false,
    );
  }

  Future<void> updateItem({
    required int id,
    String? title,
    int? isTop,
  }) async {
    // 先找舊資料
    final old = state.items.firstWhere((e) => e.id == id, orElse: () => throw StateError('item not found'));
    final updated = MemberVideoModel(
      id: old.id,
      videoUrl: old.videoUrl,
      coverUrl: old.coverUrl,
      title: title ?? old.title,
      isTop: isTop ?? old.isTop,
      isShow: old.isShow,
      isLike: old.isLike,
      updateAt: old.updateAt,
    );

    // 樂觀更新
    final prev = state;
    state = state.copyWith(items: state.updateItemLocal(id, (_) => updated));

    try {
      await _repo.updateVideo(
        id: id,
        title: updated.title,
        isTop: updated.isTop,
      );
    } catch (e) {
      // 回滾
      state = prev;
      rethrow;
    }
  }

  void applyLocalUpdate({
    required int id,
    required String title,
    required int isTop,
  }) {
    final updatedList = state.items.map((video) {
      if (video.id == id) {
        return video.copyWith(title: title, isTop: isTop);
      }
      return video;
    }).toList();

    state = state.copyWith(items: updatedList);
  }

}

final memberFeedProvider =
AutoDisposeNotifierProvider<MemberFeedNotifier, MemberFeedState>(() {
  return MemberFeedNotifier();
});

class MemberFeedByUserNotifier extends AutoDisposeFamilyNotifier<MemberFeedState, int> {
  late final VideoRepository _repo;
  late final int _uid;

  @override
  MemberFeedState build(int uid) {
    // ✅ 防止被自動回收（例如 Tab 切換短暫無監聽時）
    final keepAliveLink = ref.keepAlive();

    // 可選：你也可以在 onDispose 關閉資源；這裡留著以防未來加 Timer/Stream
    ref.onDispose(() {
      keepAliveLink.close();
    });
    _repo = ref.read(videoRepositoryProvider);
    _uid = uid;
    return MemberFeedState.initial();
  }

  Future<void> loadFirstPage({int? uid}) async {
    if (state.isLoading) return;
    state = state.copyWith(isLoading: true);

    final page1 = await _repo.fetchMemberVideos(page: 1, uid: _uid);
    state = MemberFeedState(
      items: page1.list,
      page: 1,
      totalCount: page1.count,
      isLoading: false,
    );
  }

  Future<void> loadNextPage({int? uid}) async {
    if (state.isLoading || !state.hasMore) return;
    state = state.copyWith(isLoading: true);

    final next = state.page + 1;
    final p = await _repo.fetchMemberVideos(page: next, uid: _uid);
    state = state.copyWith(
      items: [...state.items, ...p.list],
      page: next,
      totalCount: p.count,
      isLoading: false,
    );
  }

}

final memberFeedByUserProvider =
AutoDisposeNotifierProviderFamily<MemberFeedByUserNotifier, MemberFeedState, int>(
  MemberFeedByUserNotifier.new,
);
