import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/network/api_client_provider.dart';
import '../auth_repository.dart';


final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return AuthRepository(apiClient);
});
