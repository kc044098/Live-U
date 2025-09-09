import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'rtc_engine_manager.dart';

final rtcManagerProvider = Provider<RtcEngineManager>((ref) {
  return RtcEngineManager();
});