import 'package:cloud_firestore/cloud_firestore.dart';

class ActivityItem {
  final String title;
  final bool isCompleted;

  ActivityItem({required this.title, this.isCompleted = false});

  Map<String, dynamic> toMap() {
    return {'title': title, 'isCompleted': isCompleted};
  }

  factory ActivityItem.fromMap(Map<String, dynamic> map) {
    return ActivityItem(
      title: map['title'] ?? '',
      isCompleted: map['isCompleted'] ?? false,
    );
  }

  ActivityItem copyWith({String? title, bool? isCompleted}) {
    return ActivityItem(
      title: title ?? this.title,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}

class Schedule {
  final String id;
  final String userId;
  final String title;
  final String description;
  final List<ActivityItem> activities;
  final DateTime datetime;
  final bool isCompleted;
  final DateTime createdAt;
  final DateTime updatedAt;

  Schedule({
    required this.id,
    required this.userId,
    required this.title,
    required this.description,
    required this.activities,
    required this.datetime,
    this.isCompleted = false,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'description': description,
      'activities': activities.map((x) => x.toMap()).toList(),
      'datetime': Timestamp.fromDate(datetime),
      'isCompleted': isCompleted,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory Schedule.fromMap(Map<String, dynamic> map, String docId) {
    DateTime parseTimestamp(dynamic val) {
      if (val is Timestamp) return val.toDate();
      return DateTime.now(); // Default to now if missing/null
    }

    var activityList = <ActivityItem>[];
    if (map['activities'] != null) {
      if (map['activities'] is List) {
        final list = map['activities'] as List;
        if (list.isNotEmpty) {
          if (list.first is String) {
            // Legacy support for List<String>
            activityList = list
                .map((e) => ActivityItem(title: e.toString()))
                .toList();
          } else {
            // New format List<Map>
            activityList = list
                .map((e) => ActivityItem.fromMap(Map<String, dynamic>.from(e)))
                .toList();
          }
        }
      }
    }

    return Schedule(
      id: docId,
      userId: map['userId'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      activities: activityList,
      datetime: parseTimestamp(map['datetime']),
      isCompleted: map['isCompleted'] ?? false,
      createdAt: parseTimestamp(map['createdAt']),
      updatedAt: parseTimestamp(map['updatedAt']),
    );
  }

  Schedule copyWith({
    String? id,
    String? userId,
    String? title,
    String? description,
    List<ActivityItem>? activities,
    DateTime? datetime,
    bool? isCompleted,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Schedule(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      description: description ?? this.description,
      activities: activities ?? this.activities,
      datetime: datetime ?? this.datetime,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
