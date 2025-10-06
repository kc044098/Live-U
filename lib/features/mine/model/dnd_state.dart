import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../l10n/l10n.dart';
import '../user_repository.dart';
import '../user_repository_provider.dart';


/* ------------------------- 狀態 & 控制器 ------------------------- */

/// 1~6 對應時長；0=關閉
Map<int, String> kDndOptionsOf(BuildContext context) {
  final s = S.of(context);
  return <int, String>{
    1: s.dnd15m,
    2: s.dnd30m,
    3: s.dnd1h,
    4: s.dnd6h,
    5: s.dnd12h,
    6: s.dnd24h,
  };
}

final dndProvider = StateNotifierProvider<DndController, DndState>((ref) {
  final repo = ref.read(userRepositoryProvider);
  return DndController(repo)..load();
});

class DndState {
  /// 0=關閉；1~6=對應 kDndOptions
  final int selectedId;
  const DndState({this.selectedId = 0});

  bool get isActive => selectedId != 0;
}

class DndController extends StateNotifier<DndState> {
  static const _kPrefId = 'dnd_selected_id';
  final UserRepository repo;

  DndController(this.repo) : super(const DndState());

  /// 從本地載入（啟動時/Provider 初始化）
  Future<void> load() async {
    final sp = await SharedPreferences.getInstance();
    final id = sp.getInt(_kPrefId) ?? 0;
    state = DndState(selectedId: id);
  }

  /// 進頁時呼叫：讀後端最新設定覆蓋本地（若後端沒回就保留本地）
  Future<void> fetchRemote() async {
    final remoteId = await repo.readDnd();
    if (remoteId == null) return;
    state = DndState(selectedId: remoteId);
    final sp = await SharedPreferences.getInstance();
    await sp.setInt(_kPrefId, remoteId);
  }

  /// 設定 id（0=關閉；1~6=時長）
  Future<void> setById(int id, {BuildContext? ctx}) async {
    final ok = await repo.setDndById(id);
    if (!ok) {
      final msg = ctx != null ? S.of(ctx).dndSetFailed : '設定失敗，請稍後再試';
      Fluttertoast.showToast(msg: msg);
      return;
    }
    state = DndState(selectedId: id);
    final sp = await SharedPreferences.getInstance();
    await sp.setInt(_kPrefId, id);
  }

  /// 開關切換；若要開且目前是 0，就預設選 1(15分鐘)
  Future<void> toggle(bool enable, BuildContext? ctx) async {
    final targetId = enable ? (state.selectedId == 0 ? 1 : state.selectedId) : 0;
    await setById(targetId, ctx: ctx);
  }
}