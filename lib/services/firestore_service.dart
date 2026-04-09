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
        final data = doc.data() as Map<String, dynamic>;
        return Task.fromMap({...data, 'id': doc.id});
      }).toList();
    });
  }

  Future<void> saveTask(Task task) {
    return _tasksRef.doc(task.id).set(task.toMap());
  }

  Future<void> deleteTask(String id) {
    return _tasksRef.doc(id).delete();
  }

  // --- Habits ---
  CollectionReference get _habitsRef => 
      _db.collection('users').doc(uid).collection('habits');

  Stream<List<Habit>> getHabits() {
    return _habitsRef.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return Habit.fromMap({...data, 'id': doc.id});
      }).toList();
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
        final data = doc.data() as Map<String, dynamic>;
        return AIMessage.fromMap({...data, 'id': doc.id});
      }).toList();
    });
  }

  Future<void> saveMessage(AIMessage message) {
    return _messagesRef.doc(message.id).set(message.toMap());
  }

  Future<void> clearChatHistory() async {
    final batch = _db.batch();
    final snapshots = await _messagesRef.get();
    for (var doc in snapshots.docs) {
      batch.delete(doc.reference);
    }
    return batch.commit();
  }
}
