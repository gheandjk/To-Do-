import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TaskService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get the current user's tasks collection reference
  CollectionReference get _tasksCollection {
    final userId = _auth.currentUser?.uid;
    if (userId == null) throw Exception('User not authenticated');
    return _firestore.collection('users').doc(userId).collection('tasks');
  }

  // Stream of tasks and sticky notes for the current user
  Stream<List<Map<String, dynamic>>> getTasks() {
    return _tasksCollection.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {
          'id': doc.id,
          'text': data['text'] ?? '',
          'isDone': data['isDone'] ?? false,
          'createdAt': (data['createdAt'] is Timestamp)
              ? (data['createdAt'] as Timestamp).toDate()
              : null,
          'title': data['title'],
          'description': data['description'],
          'color': data['color'],
          'type': data['type'],
        };
      }).toList();
    });
  }

  // Add a new task
  Future<void> addTask(String text, DateTime createdAt) async {
    await _tasksCollection.add({
      'text': text,
      'isDone': false,
      'createdAt': Timestamp.fromDate(createdAt),
    });
  }

  // Update a task
  Future<void> updateTask(String taskId, String text) async {
    await _tasksCollection.doc(taskId).update({
      'text': text,
    });
  }

  // Delete a task
  Future<void> deleteTask(String taskId) async {
    await _tasksCollection.doc(taskId).delete();
  }

  // Toggle task completion status
  Future<void> toggleTaskStatus(String taskId, bool isDone) async {
    await _tasksCollection.doc(taskId).update({
      'isDone': !isDone,
    });
  }

  // Add a new sticky note
  Future<void> addStickyNote(String title, String description, DateTime createdAt, {String color = "yellow"}) async {
    await _tasksCollection.add({
      'title': title,
      'description': description,
      'createdAt': Timestamp.fromDate(createdAt),
      'color': color,
      'type': 'sticky',
    });
  }
} 