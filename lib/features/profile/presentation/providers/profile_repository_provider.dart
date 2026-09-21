import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/supabase_config.dart';
import '../../data/repositories/profile_repository.dart';

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepository(
    SupabaseConfig.client,
  );
});

final userProfileProvider = FutureProvider((ref) {
  final repo = ref.watch(profileRepositoryProvider);
  return repo.getCurrentProfile();
});
