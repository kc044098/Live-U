import 'package:djs_live_stream/features/live/video_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error_handler.dart';
import '../../../data/models/user_model.dart';

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
    } on ApiException catch (e) {
      // ✅ 後台用錯誤表示「沒資料」→ 視為空資料，結束分頁、不彈錯
      if (e.code == 404 || e.code == 100) {
        state = FriendListState(
          users: state.users,
          currentPage: page,
          hasMore: false,
          isLoading: false,
        );
        return;
      }
      // 其它錯誤 → 用字典顯示中文 Toast
      AppErrorToast.show(e);
      state = state.copyWith(isLoading: false);
    } catch (e) {
      // 非 ApiException（如 DioException/解析錯誤）→ 也走統一吐司
      AppErrorToast.show(e);
      state = state.copyWith(isLoading: false);
    }
  }
}