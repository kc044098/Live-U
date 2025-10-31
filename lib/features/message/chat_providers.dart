import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/network/api_client_provider.dart';
import 'chat_repository.dart';

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  final api = ref.read(apiClientProvider);
  return ChatRepository(api);
});