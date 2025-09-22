import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/gift_item.dart';
import '../../data/network/api_client_provider.dart';
import '../../data/repository/gift_repository.dart';

final giftRepositoryProvider = Provider<GiftRepository>((ref) {
  final api = ref.read(apiClientProvider);
  return GiftRepository(api);
});

class GiftListNotifier extends StateNotifier<AsyncValue<List<GiftItemModel>>> {
  GiftListNotifier(this._repo) : super(const AsyncValue.loading());

  final GiftRepository _repo;

  Future<void> loadIfEmpty() async {
    if (_repo.hasCache) {
      state = AsyncValue.data(_repo.cached);
      return;
    }
    await refresh();
  }

  Future<void> loadIfStale([Duration ttl = const Duration(minutes: 10)]) async {
    if (_repo.hasCache && !_repo.isStale(ttl)) {
      state = AsyncValue.data(_repo.cached);
      return;
    }
    await refresh();
  }

  Future<void> refresh() async {
    try {
      state = const AsyncValue.loading();
      final list = await _repo.fetchGiftList(force: true);
      state = AsyncValue.data(list);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final giftListProvider = StateNotifierProvider<GiftListNotifier, AsyncValue<List<GiftItemModel>>>(
      (ref) => GiftListNotifier(ref.read(giftRepositoryProvider)),
);

/// 快捷禮物：直接從 repo 的快取取，若無則用全部過濾作為 fallback
final quickGiftListProvider = Provider<AsyncValue<List<GiftItemModel>>>((ref) {
  final base = ref.watch(giftListProvider);
  return base.whenData((all) {
    final repo = ref.read(giftRepositoryProvider);
    if (repo.cachedQuick.isNotEmpty) return repo.cachedQuick;
    // Fallback（首次還未觸發 repo 分類時）
    return all.where((g) => g.isQuick == 1).toList(growable: false);
  });
});

/// 一般禮物
final normalGiftListProvider = Provider<AsyncValue<List<GiftItemModel>>>((ref) {
  final base = ref.watch(giftListProvider);
  return base.whenData((all) {
    final repo = ref.read(giftRepositoryProvider);
    if (repo.cachedNormal.isNotEmpty) return repo.cachedNormal;
    return all.where((g) => g.isQuick != 1).toList(growable: false);
  });
});