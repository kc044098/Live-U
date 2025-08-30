import 'package:djs_live_stream/features/live/video_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/user_model.dart';

class FriendListState {
  final List<UserModel> users;
  final int currentPage;
  final bool hasMore;
  final bool isLoading;

  FriendListState({
    required this.users,
    required this.currentPage,
    required this.hasMore,
    required this.isLoading,
  });

  FriendListState.initial()
      : users = [],
        currentPage = 1,
        hasMore = true,
        isLoading = false;

  FriendListState copyWith({
    List<UserModel>? users,
    int? currentPage,
    bool? hasMore,
    bool? isLoading,
  }) {
    return FriendListState(
      users: users ?? this.users,
      currentPage: currentPage ?? this.currentPage,
      hasMore: hasMore ?? this.hasMore,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class FriendListNotifier extends StateNotifier<FriendListState> {
  final VideoRepository repository;

  FriendListNotifier(this.repository) : super(FriendListState.initial());

  Future<void> loadFirstPage() async {
    state = FriendListState.initial();
    await _loadPage(1);
  }

  Future<void> loadNextPage() async {
    if (!state.hasMore || state.isLoading) return;
    await _loadPage(state.currentPage + 1);
  }

  Future<void> _loadPage(int page) async {
    state = state.copyWith(isLoading: true);

    try {
      final newUsers = await repository.fetchRecommendedUsers(page: page);
      state = FriendListState(
        users: [...state.users, ...newUsers],
        currentPage: page,
        hasMore: newUsers.isNotEmpty,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false);
    }
  }
}