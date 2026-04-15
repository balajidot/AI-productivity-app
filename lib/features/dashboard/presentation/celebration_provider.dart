import 'package:flutter_riverpod/flutter_riverpod.dart';

class CelebrationEvent {
  final DateTime timestamp;

  const CelebrationEvent(this.timestamp);
}

class CelebrationNotifier extends Notifier<CelebrationEvent?> {
  @override
  CelebrationEvent? build() => null;

  void trigger() {
    state = CelebrationEvent(DateTime.now());
  }
}

final celebrationProvider =
    NotifierProvider<CelebrationNotifier, CelebrationEvent?>(
      CelebrationNotifier.new,
    );
