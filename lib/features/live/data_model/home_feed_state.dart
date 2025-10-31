// lib/features/home/home_feed_controller.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../config/providers/app_config_provider.dart';
import '../../../data/network/api_client_provider.dart';
import 'feed_item.dart';

import '../video_repository.dart';

class HomeFeedState {
  final List<FeedItem> items;
  final int page;
  final bool hasMore;
  final bool isLoading;

  const HomeFeedState({
    this.items = const [],
    this.page = 1,
    this.hasMore = true,
    this.isLoading = false,
  });

  HomeFeedState copyWith({
    List<FeedItem>? items,
    int? page,
    bool? hasMore,
    bool? isLoading,
  }) => HomeFeedState(
    items: items ?? this.items,
    page: page ?? this.page,
    hasMore: hasMore ?? this.hasMore,
    isLoading: isLoading ?? this.isLoading,
  );
}

class HomeFeedController extends StateNotifier<HomeFeedState> {
  final VideoRepository _repo;
  HomeFeedController(this._repo) : super(const HomeFeedState());

  Future<void> loadFirst() async {
    if (state.isLoading) return;
    state = state.copyWith(isLoading: true, page: 1, hasMore: true);
    final list = await _repo.fetchRecommend(page: 1);
    state = state.copyWith(
      items: list,
      page: 1,
      hasMore: list.isNotEmpty,
      isLoading: false,
    );
  }

  Future<void> loadMoreIfNeeded(int currentIndex) async {
    if (!state.hasMore || state.isLoading) return;
    if (currentIndex < state.items.length - 3) return;

    state = state.copyWith(isLoading: true);
    final nextPage = state.page + 1;
    final list = await _repo.fetchRecommend(page: nextPage);
    state = state.copyWith(
      items: [...state.items, ...list],
      page: nextPage,
      hasMore: list.isNotEmpty,
      isLoading: false,
    );
  }

  Future<void> refresh() => loadFirst();

  Future<void> setLikeByUser({required int uid, required bool liked}) async {
    final items = state.items.map((e) {
      if (e.uid != uid) return e;
      return e.copyWith(isLike: liked ? 1 : 2);
    }).toList();
    state = state.copyWith(items: items);
  }
}

final homeFeedProvider = StateNotifierProvider<HomeFeedController, HomeFeedState>((ref) {
  final api = ref.watch(apiClientProvider);
  final config = ref.watch(appConfigProvider);
  return HomeFeedController(VideoRepository(api, config, ref));
});