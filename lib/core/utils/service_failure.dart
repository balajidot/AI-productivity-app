enum FailureType {
  network,
  firestore,
  auth,
  ai,
  notifications,
  unknown
}

class ServiceFailure {
  final String message;
  final FailureType type;
  final dynamic originalError;

  ServiceFailure({
    required this.message,
    this.type = FailureType.unknown,
    this.originalError,
  });

  @override
  String toString() => 'ServiceFailure($type): $message';
  
  factory ServiceFailure.fromFirestore(dynamic e) {
    return ServiceFailure(
      message: e.toString().contains('permission-denied') 
          ? 'You do not have permission to perform this action.' 
          : 'Database connection failed. Changes will sync when online.',
      type: FailureType.firestore,
      originalError: e,
    );
  }

  factory ServiceFailure.fromAI(dynamic e) {
    return ServiceFailure(
      message: 'AI assistant is currently unavailable. Please try again later.',
      type: FailureType.ai,
      originalError: e,
    );
  }

  factory ServiceFailure.fromAuth(dynamic e) {
    return ServiceFailure(
      message: e.toString().contains('network-request-failed')
          ? 'Network error. Please check your connection.'
          : 'Authentication failed. Please try again.',
      type: FailureType.auth,
      originalError: e,
    );
  }
}
