// call_session_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../message/chat_message.dart';

class CallSessionState {
  final List<ChatMessage> messages;
  final String draft;                   // 輸入框草稿
  const CallSessionState({
    this.messages = const [],
    this.draft = '',
  });

  CallSessionState copyWith({
    List<ChatMessage>? messages,
    String? draft,
  }) => CallSessionState(
    messages: messages ?? this.messages,
    draft: draft ?? this.draft,
  );
}

class CallSessionController extends StateNotifier<CallSessionState> {
  CallSessionController() : super(const CallSessionState());

  // 用於去重（uuid）
  final Set<String> _seen = {};

  void setDraft(String v) {
    if (v == state.draft) return;
    state = state.copyWith(draft: v);
  }

  void addIncoming(ChatMessage m) {
    final u = m.uuid;
    if (u != null && u.isNotEmpty) {
      if (_seen.contains(u)) return;
      _seen.add(u);
    }
    state = state.copyWith(messages: [...state.messages, m]);
  }

  void addOptimistic(ChatMessage m) {
    final u = m.uuid;
    if (u != null && u.isNotEmpty) _seen.add(u);
    state = state.copyWith(messages: [...state.messages, m]);
  }

  void updateSendState(String uuid, SendState s) {
    final list = [...state.messages];
    final i = list.indexWhere((e) => e.uuid == uuid);
    if (i >= 0) list[i] = list[i].copyWith(sendState: s);
    state = state.copyWith(messages: list);
  }

  void clearAll() {
    _seen.clear();
    state = const CallSessionState();
  }
}

// 不要 autoDispose，避免頁面暫時沒訂閱時把資料回收
final callSessionProvider = StateNotifierProvider.family<
    CallSessionController, CallSessionState, String>((ref, roomId) {
  return CallSessionController();
});