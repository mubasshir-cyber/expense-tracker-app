import 'dart:async';
import 'package:flutter/foundation.dart';
import '../features/auth/domain/models/auth_user.dart';

class AuthRouterRefreshNotifier extends ChangeNotifier {
  AuthRouterRefreshNotifier(Stream<AuthUser?> authStream) {
    _subscription = authStream.listen((_) {
      notifyListeners();
    });
  }

  late final StreamSubscription<AuthUser?> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
