import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/app_models.dart';
import '../models/message_model.dart';

class FirestoreService {
  final String uid;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  FirestoreService({required this.uid});

  // --- Tasks ---
  CollectionReference get _tasksRef => 
      _db.collection('users').doc(uid).collection('tasks');

  Stream<List<Task>> getTasks() {
    return _tasksRef.orderBy('date', descending: true).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>?;
        if (data == null) return null;
        return Task.fromMap({...data, 'id': doc.id});
      }).whereType<Task>().toList();
    });
  }

  Future<void> saveTask(Task task) {
    return _tasksRef.doc(task.id).set(task.toMap());
  }

  Future<void> deleteTask(String id) {
    return _tasksRef.doc(id).delete();
  }

  Future<void> deleteTasksBatch(List<String> ids) async {
    if (ids.isEmpty) return;
    
    // Batch operations are limited to 500 documents
    for (var i = 0; i < ids.length; i += 500) {
      final batch = _db.batch();
      final chunk = ids.skip(i).take(500);
      for (var id in chunk) {
        batch.delete(_tasksRef.doc(id));
      }
      await batch.commit().timeout(
        const Duration(seconds: 15),
        onTimeout: () => throw Exception('Delete operation timed out. Please check your connection.'),
      );
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
    return _habitsRef.doc(habit.id).set(habit.toMap());
  }

  Future<void> deleteHabit(String id) {
    return _habitsRef.doc(id).delete();
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
    return _messagesRef.doc(message.id).set(message.toMap());
  }

  Future<void> clearChatHistory() async {
    final snapshots = await _messagesRef.get();
    if (snapshots.docs.isEmpty) return;

    // Use chunks to respect Firestore 500 items limit per batch
    for (var i = 0; i < snapshots.docs.length; i += 500) {
      final batch = _db.batch();
      final chunk = snapshots.docs.skip(i).take(500);
      for (var doc in chunk) {
        batch.delete(doc.reference);
      }
      await batch.commit().timeout(
        const Duration(seconds: 15),
        onTimeout: () => throw Exception('Clear history timed out. Some items may not have been deleted.'),
      );
    }
  }
}
