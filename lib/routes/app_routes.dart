import 'package:flutter/cupertino.dart';

class AppRoutes {
  static const login = '/';
  static const home = '/home';
  static const audience = '/audience';
  static const broadcaster = '/broadcaster';
  static const incomingCall = '/incoming_call';
  static const videoRecorder = '/video_recorder';
  static const live_video = '/live_video';
}

final RouteObserver<ModalRoute<void>> routeObserver =
RouteObserver<ModalRoute<void>>();
