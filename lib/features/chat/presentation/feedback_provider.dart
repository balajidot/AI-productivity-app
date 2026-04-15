import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/service_failure.dart';

class FeedbackState {
  final String? message;
  final bool isError;
  final DateTime? timestamp;
  /// When set, the RETRY button on the error snackbar calls this.
  final void Function()? retryCallback;

  FeedbackState({
    this.message,
    this.isError = false,
    this.timestamp,
    this.retryCallback,
  });
}

class FeedbackNotifier extends Notifier<FeedbackState> {
  @override
  FeedbackState build() => FeedbackState();

  void showMessage(String message) {
    state = FeedbackState(
      message: message,
      isError: false,
      timestamp: DateTime.now(),
    );
  }

  void showError(dynamic error, {void Function()? onRetry}) {
    String message;
    if (error is ServiceFailure) {
      message = error.message;
    } else {
      message = error.toString();
    }

    state = FeedbackState(
      message: message,
      isError: true,
      timestamp: DateTime.now(),
      retryCallback: onRetry,
    );
  }
}

final feedbackProvider =
    NotifierProvider<FeedbackNotifier, FeedbackState>(FeedbackNotifier.new);
