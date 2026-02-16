import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/schedule_model.dart';
import '../providers/schedule_provider.dart';
import '../utils/ui_helpers.dart';
import 'add_schedule_screen.dart';

class ScheduleDetailScreen extends StatelessWidget {
  final Schedule initialSchedule;

  const ScheduleDetailScreen({super.key, required this.initialSchedule});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('EEEE, d MMMM yyyy');
    final timeFormat = DateFormat('HH:mm');

    return Consumer<ScheduleProvider>(
      builder: (context, provider, child) {
        // Try to find the latest version of this schedule
        // If not found (deleted?), fallback to initialSchedule
        final schedule = provider.schedules.firstWhere(
          (s) => s.id == initialSchedule.id,
          orElse: () => initialSchedule,
        );

        return Scaffold(
          appBar: AppBar(
            title: const Text('Schedule Details'),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AddScheduleScreen(schedule: schedule),
                    ),
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.redAccent),
                onPressed: () async {
                  final confirm = await showModernDialog(
                    context,
                    title: 'Delete Schedule',
                    content:
                        'Are you sure you want to delete this schedule? This action cannot be undone.',
                    confirmText: 'Delete',
                    confirmColor: Colors.red,
                  );

                  if (confirm == true) {
                    Navigator.pop(context); // Go back to dashboard
                    await provider.deleteSchedule(schedule.id);
                  }
                },
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  schedule.title,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(
                      Icons.calendar_today,
                      size: 16,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      dateFormat.format(schedule.datetime),
                      style: const TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(width: 16),
                    const Icon(Icons.access_time, size: 16, color: Colors.grey),
                    const SizedBox(width: 8),
                    Text(
                      timeFormat.format(schedule.datetime),
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const Text(
                  'Description',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E2A38),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    schedule.description.isNotEmpty
                        ? schedule.description
                        : 'No description provided.',
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Activities',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                if (schedule.activities.isEmpty)
                  const Text(
                    'No activities listed.',
                    style: TextStyle(color: Colors.grey),
                  )
                else
                  ...schedule.activities.asMap().entries.map((entry) {
                    final index = entry.key;
                    final activity = entry.value;
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: CheckboxListTile(
                        title: Text(
                          activity.title,
                          style: TextStyle(
                            decoration: activity.isCompleted
                                ? TextDecoration.lineThrough
                                : null,
                            color: activity.isCompleted ? Colors.grey : null,
                          ),
                        ),
                        value: activity.isCompleted,
                        onChanged: (val) {
                          if (val != null) {
                            provider.toggleActivity(schedule.id, index, val);
                          }
                        },
                        secondary: Icon(
                          activity.isCompleted
                              ? Icons.check_circle
                              : Icons.circle_outlined,
                          color: activity.isCompleted
                              ? Colors.green
                              : Colors.grey,
                        ),
                      ),
                    );
                  }),
              ],
            ),
          ),
        );
      },
    );
  }
}
