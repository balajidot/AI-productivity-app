import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../data/auth_service.dart';


final authServiceProvider = Provider<AuthService>((ref) => AuthService());

class ProfileRefreshNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void bump() => state++;
}

final profileRefreshProvider = NotifierProvider<ProfileRefreshNotifier, int>(
  ProfileRefreshNotifier.new,
);

final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authServiceProvider).authStateChanges;
});

final currentUserProvider = Provider<User?>((ref) {
  ref.watch(profileRefreshProvider);
  final authStateAsync = ref.watch(authStateProvider);
  final authStateUser = authStateAsync.maybeWhen(
    data: (user) => user,
    orElse: () => null,
  );
  return ref.read(authServiceProvider).currentUser ?? authStateUser;
});

final userNameProvider = Provider<String>((ref) {
  final user = ref.watch(currentUserProvider);
  return user?.displayName ?? 'User';
});

final userEmailProvider = Provider<String>((ref) {
  final user = ref.watch(currentUserProvider);
  return user?.email ?? 'No Email';
});

final userPhotoProvider = Provider<String?>((ref) {
  final user = ref.watch(currentUserProvider);
  return user?.photoURL;
});
