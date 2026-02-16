import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/schedule_model.dart';

class FirebaseService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Auth Methods
  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Firestore Methods - Schedules
  CollectionReference<Map<String, dynamic>> _schedulesRef() {
    return _firestore.collection('schedules');
  }

  Stream<List<Schedule>> getSchedules() {
    final user = currentUser;
    if (user == null) return Stream.value([]);

    return _schedulesRef()
        .where('userId', isEqualTo: user.uid)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => Schedule.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }

  Future<void> addSchedule(Schedule schedule) async {
    await _schedulesRef().doc(schedule.id).set(schedule.toMap());
  }

  Future<void> updateSchedule(Schedule schedule) async {
    await _schedulesRef().doc(schedule.id).update(schedule.toMap());
  }

  Future<void> deleteSchedule(String scheduleId) async {
    await _schedulesRef().doc(scheduleId).delete();
  }

  Future<void> bulkDelete(List<String> scheduleIds) async {
    final batch = _firestore.batch();
    for (var id in scheduleIds) {
      batch.delete(_schedulesRef().doc(id));
    }
    await batch.commit();
  }

  Future<void> toggleCompletion(String scheduleId, bool isCompleted) async {
    await _schedulesRef().doc(scheduleId).update({
      'isCompleted': isCompleted,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Auth Error Helper
  String getAuthErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No user found for that email.';
      case 'wrong-password':
        return 'Wrong password provided.';
      case 'email-already-in-use':
        return 'The account already exists for that email.';
      case 'invalid-email':
        return 'The email address is invalid.';
      case 'weak-password':
        return 'The password provided is too weak.';
      default:
        return 'An error occurred. Please try again.';
    }
  }

  Future<void> deleteOldCompletedSchedules() async {
    final user = currentUser;
    if (user == null) return;

    final cutoffDate = DateTime.now().subtract(const Duration(days: 30));

    // Query for completed schedules that are older than 30 days
    // Note: To use multiple where clauses, we might need a composite index on Firestore.
    // If we can't create one easily, we can fetch all completed schedules and filter locally to avoid indexing issues for now.
    // But let's try to query by date.
    // Since we don't know if the user has created the index, a safer approach for this MVP is:
    // 1. Get all completed schedules for the user.
    // 2. Filter by date in memory.
    // 3. Batch delete.

    final querySnapshot = await _schedulesRef()
        .where('userId', isEqualTo: user.uid)
        .where('isCompleted', isEqualTo: true)
        .get();

    final batch = _firestore.batch();
    bool needsCommit = false;

    for (var doc in querySnapshot.docs) {
      final data = doc.data();
      // Safely parse datetime from Timestamp
      DateTime? scheduleDate;
      if (data['datetime'] is Timestamp) {
        scheduleDate = (data['datetime'] as Timestamp).toDate();
      } else if (data['datetime'] is String) {
        // Fallback if stored as string (shouldn't be, but good for safety)
        scheduleDate = DateTime.tryParse(data['datetime']);
      }

      if (scheduleDate != null && scheduleDate.isBefore(cutoffDate)) {
        batch.delete(doc.reference);
        needsCommit = true;
      }
    }

    if (needsCommit) {
      await batch.commit();
    }
  }
}
