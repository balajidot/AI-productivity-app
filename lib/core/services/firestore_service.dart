import 'package:cloud_firestore/cloud_firestore.dart';
import '../../features/tasks/domain/task.dart';
import '../../features/habits/domain/habit.dart';
import '../../features/chat/domain/message_model.dart';


class FirestoreService {
  final String uid;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  FirestoreService({required this.uid});

  // Helper for resilient writes
  Future<T> _withRetry<T>(Future<T> Function() operation, {int maxAttempts = 3}) async {
    int attempts = 0;
    while (true) {
      try {
        attempts++;
        return await operation().timeout(
          const Duration(seconds: 10),
          onTimeout: () => throw Exception('Operation timed out after 10s'),
        );
      } catch (e) {
        if (attempts >= maxAttempts) rethrow;
        // Exponential backoff: 1s, 2s, 4s
        await Future.delayed(Duration(seconds: 1 << (attempts - 1)));
      }
    }
  }

  // --- Tasks (Paginated) ---
  CollectionReference get _tasksRef => 
      _db.collection('users').doc(uid).collection('tasks');

  // New: Cursor-based pagination for the main list
  Future<QuerySnapshot> getTasksPage({int limit = 20, DocumentSnapshot? startAfter}) async {
    return _withRetry(() async {
      Query query = _tasksRef.orderBy('date', descending: true);
      if (startAfter != null) query = query.startAfterDocument(startAfter);
      return query.limit(limit).get();
    });
  }

  // New: Dedicated metrics query (Last 90 days)
  Stream<List<Task>> getRecentMetricsTasks({int days = 90}) {
    final cutoff = DateTime.now().subtract(Duration(days: days));
    final cutoffStr = cutoff.toIso8601String();
    
    return _tasksRef
        .where('date', isGreaterThanOrEqualTo: cutoffStr)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>?;
        if (data == null) return null;
        return Task.fromMap({...data, 'id': doc.id});
      }).whereType<Task>().toList();
    });
  }

  // New: Range query for calendar
  Stream<List<Task>> getTasksForRange(DateTime start, DateTime end) {
    return _tasksRef
        .where('date', isGreaterThanOrEqualTo: start.toIso8601String())
        .where('date', isLessThanOrEqualTo: end.toIso8601String())
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>?;
        if (data == null) return null;
        return Task.fromMap({...data, 'id': doc.id});
      }).whereType<Task>().toList();
    });
  }

  Future<void> saveTask(Task task) {
    return _withRetry(() => _tasksRef.doc(task.id).set(task.toMap()));
  }

  Future<void> deleteTask(String id) {
    return _withRetry(() => _tasksRef.doc(id).delete());
  }

  Future<void> deleteTasksBatch(List<String> ids) async {
    if (ids.isEmpty) return;
    
    for (var i = 0; i < ids.length; i += 500) {
      final chunk = ids.skip(i).take(500);
      await _withRetry(() async {
        final batch = _db.batch();
        for (var id in chunk) {
          batch.delete(_tasksRef.doc(id));
        }
        await batch.commit();
      });
    }
  }

  // --- Habits ---
  CollectionReference get _habitsRef => 
      _db.collection('users').doc(uid).collection('habits');

  Stream<List<Habit>> getHabits() {
    return _habitsRef.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>?;
        if (data == null) return null;
        return Habit.fromMap({...data, 'id': doc.id});
      }).whereType<Habit>().toList();
    });
  }

  Future<void> saveHabit(Habit habit) {
    return _withRetry(() => _habitsRef.doc(habit.id).set(habit.toMap()));
  }

  Future<void> deleteHabit(String id) {
    return _withRetry(() => _habitsRef.doc(id).delete());
  }

  // --- Messages (AI Chat History) ---
  CollectionReference get _messagesRef => 
      _db.collection('users').doc(uid).collection('messages');

  Stream<List<AIMessage>> getMessages() {
    return _messagesRef.orderBy('timestamp', descending: false).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>?;
        if (data == null) return null;
        return AIMessage.fromMap({...data, 'id': doc.id});
      }).whereType<AIMessage>().toList();
    });
  }

  Future<void> saveMessage(AIMessage message) {
    return _withRetry(() => _messagesRef.doc(message.id).set(message.toMap()));
  }

  Future<void> clearChatHistory() async {
    while (true) {
      // Fetch only 100 documents at a time to stay safe on memory
      final snapshots = await _messagesRef.limit(100).get();
      if (snapshots.docs.isEmpty) break;

      await _withRetry(() async {
        final batch = _db.batch();
        for (var doc in snapshots.docs) {
          batch.delete(doc.reference);
        }
        await batch.commit();
      });

      // Brief delay to allow Firestore to process
      await Future.delayed(const Duration(milliseconds: 100));
    }
  }
}

