import 'package:flutter_riverpod/flutter_riverpod.dart';

final callAbortProvider =
StateNotifierProvider<CallAbortNotifier, Set<String>>((ref) {
  return CallAbortNotifier();
});

class CallAbortNotifier extends StateNotifier<Set<String>> {
  CallAbortNotifier() : super(<String>{});

  void abort(String channel) => state = {...state, channel};
  void clear(String channel)  => state = {...state}..remove(channel);
  bool isAborted(String channel) => state.contains(channel);
}
