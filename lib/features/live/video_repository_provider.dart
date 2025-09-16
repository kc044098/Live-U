import 'package:dio/dio.dart';

import '../../config/providers/app_config_provider.dart';
import '../../data/network/api_client_interface.dart';
import '../../data/network/api_client.dart';
import '../profile/profile_controller.dart';
import 'data_model/friend_list_state.dart';
import 'data_model/music_track.dart';
import 'video_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/network/api_client_provider.dart';

final videoRepositoryProvider = Provider<VideoRepository>((ref) {
  final api = ref.watch(apiClientProvider);
  final config = ref.watch(appConfigProvider);
  return VideoRepository(api, config, ref);
});

final friendListProvider = StateNotifierProvider<FriendListNotifier, FriendListState>((ref) {
  final repo = VideoRepository(ref.read(apiClientProvider), ref.watch(appConfigProvider), ref);
  return FriendListNotifier(repo);
});

final musicListProvider = FutureProvider<List<MusicTrack>>((ref) async {
  final repo = ref.read(videoRepositoryProvider);
  return repo.fetchMusicList();
});
