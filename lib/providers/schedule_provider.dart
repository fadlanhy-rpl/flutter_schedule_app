import 'dart:async';
import 'package:flutter/material.dart';
import '../models/schedule_model.dart';
import '../services/firebase_service.dart';
import '../services/gemini_service.dart';

class ScheduleProvider with ChangeNotifier {
  final FirebaseService _firebaseService;
  final GeminiService _geminiService;

  List<Schedule> _schedules = [];
  bool _isLoading = false;
  String? _error;

  List<Schedule> get schedules => _schedules;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Filtered Getters
  List<Schedule> get ongoingSchedules =>
      _schedules.where((s) => !s.isCompleted).toList();
  List<Schedule> get completedSchedules =>
      _schedules.where((s) => s.isCompleted).toList();

  StreamSubscription<List<Schedule>>? _subscription;

  ScheduleProvider({
    required FirebaseService firebaseService,
    required GeminiService geminiService,
  }) : _firebaseService = firebaseService,
       _geminiService = geminiService {
    _init();
  }

  void _init() {
    _subscription = _firebaseService.getSchedules().listen(
      (schedules) {
        _schedules = schedules;
        notifyListeners();
      },
      onError: (e) {
        _error = e.toString();
        notifyListeners();
      },
    );

    // Run cleanup in background on startup
    _cleanupOldSchedules();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  Future<void> _cleanupOldSchedules() async {
    try {
      await _firebaseService.deleteOldCompletedSchedules();
    } catch (e) {
      // Create a silent error log or ignore, as it's a background task
      print("Error cleaning up old schedules: $e");
    }
  }

  Future<void> addSchedule(
    String title,
    String description,
    DateTime date,
    List<ActivityItem> activities,
  ) async {
    try {
      _isLoading = true;
      notifyListeners();

      final userId = _firebaseService.currentUser?.uid;
      if (userId == null || userId.isEmpty) {
        throw Exception("User ID is null. Cannot save schedule.");
      }

      print("DEBUG: Adding schedule for user: $userId");

      final newSchedule = Schedule(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: userId,
        title: title,
        description: description,
        activities: activities,
        datetime: date,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _firebaseService.addSchedule(newSchedule);
      print("DEBUG: Schedule added to Firestore");

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      print("DEBUG: Error adding schedule: $e");
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> updateSchedule(Schedule schedule) async {
    try {
      _isLoading = true;
      notifyListeners();

      final updatedSchedule = schedule.copyWith(updatedAt: DateTime.now());

      await _firebaseService.updateSchedule(updatedSchedule);

      // Optimistic update in local list
      final index = _schedules.indexWhere((s) => s.id == schedule.id);
      if (index != -1) {
        _schedules[index] = updatedSchedule;
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> toggleCompletion(String id, bool currentValue) async {
    // Optimistic Update
    final index = _schedules.indexWhere((s) => s.id == id);
    if (index != -1) {
      final oldSchedule = _schedules[index];
      final newValue = !currentValue;

      // Update all activities to match the new schedule status
      var newActivities = <ActivityItem>[];
      if (oldSchedule.activities.isNotEmpty) {
        newActivities = oldSchedule.activities
            .map((a) => a.copyWith(isCompleted: newValue))
            .toList();
      }

      final updatedSchedule = oldSchedule.copyWith(
        isCompleted: newValue,
        activities: newActivities,
        updatedAt: DateTime.now(),
      );

      _schedules[index] = updatedSchedule;
      notifyListeners();

      try {
        // Use updateSchedule instead of toggleCompletion to ensure activities are saved
        await _firebaseService.updateSchedule(updatedSchedule);
      } catch (e) {
        // Revert on error
        _schedules[index] = oldSchedule;
        notifyListeners();
        _error = "Failed to update status";
      }
    }
  }

  Future<void> toggleActivity(
    String scheduleId,
    int activityIndex,
    bool isCompleted,
  ) async {
    final index = _schedules.indexWhere((s) => s.id == scheduleId);
    if (index != -1) {
      final schedule = _schedules[index];
      if (activityIndex >= 0 && activityIndex < schedule.activities.length) {
        // Create new list to trigger notifyListeners
        final newActivities = List<ActivityItem>.from(schedule.activities);
        newActivities[activityIndex] = newActivities[activityIndex].copyWith(
          isCompleted: isCompleted,
        );

        // Check if all activities are completed
        bool allCompleted =
            newActivities.isNotEmpty &&
            newActivities.every((a) => a.isCompleted);

        final updatedSchedule = schedule.copyWith(
          activities: newActivities,
          // Sync schedule status: if all completed -> true, if any unchecked -> false (ongoing)
          isCompleted: allCompleted,
          updatedAt: DateTime.now(),
        );

        _schedules[index] = updatedSchedule;
        notifyListeners(); // Immediate UI update

        try {
          await _firebaseService.updateSchedule(updatedSchedule);
        } catch (e) {
          _error = "Failed to update activity";
          notifyListeners();
        }
      }
    }
  }

  Future<void> deleteSchedule(String id) async {
    // Optimistic
    final existing = _schedules.firstWhere((s) => s.id == id);
    _schedules.removeWhere((s) => s.id == id);
    notifyListeners();

    try {
      await _firebaseService.deleteSchedule(id);
    } catch (e) {
      _schedules.add(existing);
      notifyListeners();
      _error = "Failed to delete";
    }
  }

  Future<void> bulkDelete(List<String> ids) async {
    // Optimistic
    final backup = _schedules.where((s) => ids.contains(s.id)).toList();
    _schedules.removeWhere((s) => ids.contains(s.id));
    notifyListeners();

    try {
      await _firebaseService.bulkDelete(ids);
    } catch (e) {
      _schedules.addAll(backup);
      notifyListeners();
      _error = "Failed to bulk delete";
    }
  }

  Future<List<String>> generateAIActivities(String title) async {
    try {
      return await _geminiService.generateActivities(title);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return [];
    }
  }

  Future<String> generateWeeklyResume() async {
    try {
      _isLoading = true;
      notifyListeners();

      // Filter for this week's completed schedules
      final now = DateTime.now();
      // Calculate start of week (Monday) at 00:00:00
      final startOfWeek = DateTime(
        now.year,
        now.month,
        now.day,
      ).subtract(Duration(days: now.weekday - 1));

      final weekSchedules = _schedules.where((s) {
        return s.datetime.isAfter(startOfWeek) && s.isCompleted;
      }).toList();

      if (weekSchedules.isEmpty) {
        _isLoading = false;
        notifyListeners();
        return "No completed schedules found for this week to generate a resume.";
      }

      final resume = await _geminiService.generateWeeklyResume(weekSchedules);

      _isLoading = false;
      notifyListeners();
      return resume;
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      return "Error generating resume.";
    }
  }
}
