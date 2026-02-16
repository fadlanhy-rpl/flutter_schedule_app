import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/schedule_model.dart';
import '../providers/schedule_provider.dart';
import '../widgets/custom_widgets.dart';
import '../utils/ui_helpers.dart';

class AddScheduleScreen extends StatefulWidget {
  final Schedule? schedule;

  const AddScheduleScreen({super.key, this.schedule});

  @override
  State<AddScheduleScreen> createState() => _AddScheduleScreenState();
}

class _AddScheduleScreenState extends State<AddScheduleScreen> {
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  final TextEditingController _activityController = TextEditingController();
  late DateTime _selectedDate;
  late TimeOfDay _selectedTime;
  List<ActivityItem> _activities = [];
  bool _isGenerating = false;

  @override
  void initState() {
    super.initState();
    final schedule = widget.schedule;
    if (schedule != null) {
      _titleController = TextEditingController(text: schedule.title);
      _descriptionController = TextEditingController(
        text: schedule.description,
      );
      _selectedDate = schedule.datetime;
      _selectedTime = TimeOfDay.fromDateTime(schedule.datetime);
      _activities = List.from(schedule.activities);
    } else {
      _titleController = TextEditingController();
      _descriptionController = TextEditingController();
      _selectedDate = DateTime.now();
      _selectedTime = TimeOfDay.now();
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _activityController.dispose();
    super.dispose();
  }

  void _generateActivities() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a title first')),
      );
      return;
    }

    setState(() => _isGenerating = true);
    final provider = Provider.of<ScheduleProvider>(context, listen: false);

    try {
      final result = await provider.generateAIActivities(title);
      setState(() {
        // Append new activities
        _activities.addAll(result.map((e) => ActivityItem(title: e)).toList());
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to generate: $e')));
      }
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  void _addManualActivity() {
    final text = _activityController.text.trim();
    if (text.isNotEmpty) {
      setState(() {
        _activities.add(ActivityItem(title: text));
        _activityController.clear();
      });
    }
  }

  void _editActivity(int index) {
    final controller = TextEditingController(text: _activities[index].title);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Activity'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Activity name'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final newTitle = controller.text.trim();
              if (newTitle.isNotEmpty) {
                setState(() {
                  _activities[index] = _activities[index].copyWith(
                    title: newTitle,
                  );
                });
              }
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _saveSchedule() async {
    final title = _titleController.text.trim();
    final description = _descriptionController.text.trim();
    if (title.isEmpty) {
      showModernSnackBar(context, 'Please enter a title', isError: true);
      return;
    }

    // Confirmation for Update
    if (widget.schedule != null) {
      final confirm = await showModernDialog(
        context,
        title: 'Update Schedule',
        content: 'Are you sure you want to save changes to this schedule?',
        confirmText: 'Update',
        confirmColor: Colors.blue,
      );
      if (confirm != true) return;
    }

    final fullDateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );

    try {
      final provider = Provider.of<ScheduleProvider>(context, listen: false);
      if (widget.schedule != null) {
        // Update existing
        final updatedSchedule = widget.schedule!.copyWith(
          title: title,
          description: description,
          datetime: fullDateTime,
          activities: _activities,
        );
        await provider.updateSchedule(updatedSchedule);
        if (mounted) {
          showModernSnackBar(context, 'Schedule updated successfully!');
          Navigator.pop(context); // Return to details
        }
      } else {
        // Add new
        await provider.addSchedule(
          title,
          description,
          fullDateTime,
          _activities,
        );
        if (mounted) {
          showModernSnackBar(context, 'Schedule added successfully!');
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) {
        showModernSnackBar(context, 'Failed to save: $e', isError: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.schedule != null;
    return Scaffold(
      appBar: AppBar(title: Text(isEditing ? 'Edit Schedule' : 'Add Schedule')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Activity Title',
                  hintText: 'e.g., Morning Routine',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Keterangan (Description)',
                  hintText: 'e.g., Detail activities...',
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _selectedDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2030),
                        );
                        if (picked != null) {
                          setState(() => _selectedDate = picked);
                        }
                      },
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Date',
                          border: OutlineInputBorder(),
                        ),
                        child: Text(
                          "${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}",
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: InkWell(
                      onTap: () async {
                        final picked = await showTimePicker(
                          context: context,
                          initialTime: _selectedTime,
                        );
                        if (picked != null) {
                          setState(() => _selectedTime = picked);
                        }
                      },
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Time',
                          border: OutlineInputBorder(),
                        ),
                        child: Text(_selectedTime.format(context)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _activityController,
                      decoration: const InputDecoration(
                        labelText: 'Add Manual Activity',
                        hintText: 'e.g., Read 10 pages',
                      ),
                      onSubmitted: (_) => _addManualActivity(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: _addManualActivity,
                    icon: const Icon(
                      Icons.add_circle,
                      size: 32,
                      color: Colors.blue,
                    ),
                    tooltip: 'Add Activity',
                  ),
                ],
              ),
              const SizedBox(height: 16),
              CustomButton(
                text: _isGenerating
                    ? 'Generating Activities...'
                    : 'Generate Activities with AI',
                onPressed: _generateActivities,
                isLoading: _isGenerating,
              ),
              const SizedBox(height: 16),
              const Text(
                "Activities List (Tap to Edit):",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 200, // Fixed height for list inside scroll view
                child: _activities.isEmpty
                    ? const Center(
                        child: Text(
                          'No activities yet.',
                          style: TextStyle(color: Colors.grey),
                        ),
                      )
                    : ListView.builder(
                        itemCount: _activities.length,
                        itemBuilder: (ctx, i) {
                          final activity = _activities[i];
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            onTap: () => _editActivity(i),
                            leading: Icon(
                              activity.isCompleted
                                  ? Icons.check_circle
                                  : Icons.check_circle_outline,
                              size: 20,
                              color: activity.isCompleted ? Colors.green : null,
                            ),
                            title: Text(activity.title),
                            trailing: IconButton(
                              icon: const Icon(
                                Icons.delete,
                                size: 20,
                                color: Colors.grey,
                              ),
                              onPressed: () {
                                setState(() => _activities.removeAt(i));
                              },
                            ),
                          );
                        },
                      ),
              ),
              const SizedBox(height: 16),
              CustomButton(
                text: isEditing ? 'Update Schedule' : 'Save Schedule',
                onPressed: _saveSchedule,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
