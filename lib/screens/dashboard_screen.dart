import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/schedule_provider.dart';
import '../models/schedule_model.dart';
import '../widgets/custom_widgets.dart';
import '../utils/ui_helpers.dart';
import 'add_schedule_screen.dart';
import 'resume_screen.dart';
import 'schedule_detail_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _isBulkMode = false;
  final Set<String> _selectedIds = {};
  bool _hasShownWelcome = false;

  @override
  void initState() {
    super.initState();
    // Show welcome message with ongoing count once per session
    // We delay to ensuring Provider is loaded
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_hasShownWelcome) {
        final provider = Provider.of<ScheduleProvider>(context, listen: false);
        // We might need to wait for data to load.
        // For now, let's just trigger it if not loading.
        if (!provider.isLoading && provider.ongoingSchedules.isNotEmpty) {
          showModernSnackBar(
            context,
            "Welcome back! You have ${provider.ongoingSchedules.length} ongoing schedules.",
          );
          _hasShownWelcome = true;
        }
      }
    });
  }

  void _toggleBulkMode() {
    setState(() {
      _isBulkMode = !_isBulkMode;
      _selectedIds.clear();
    });
  }

  void _toggleSelection(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
    });
  }

  void _deleteSelected() async {
    if (_selectedIds.isEmpty) return;

    final confirm = await showModernDialog(
      context,
      title: "Delete Schedules",
      content:
          "Are you sure you want to delete ${_selectedIds.length} selected schedules?",
      confirmText: "Delete",
      confirmColor: Colors.red,
    );

    if (confirm == true && mounted) {
      await Provider.of<ScheduleProvider>(
        context,
        listen: false,
      ).bulkDelete(_selectedIds.toList());
      _toggleBulkMode();
      if (mounted) showModernSnackBar(context, "Schedules deleted.");
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheduleProvider = Provider.of<ScheduleProvider>(context);

    // Update welcome state if data loads later
    if (!_hasShownWelcome &&
        !scheduleProvider.isLoading &&
        scheduleProvider.ongoingSchedules.isNotEmpty) {
      // Using a microtask to avoid setState during build
      Future.microtask(() {
        if (mounted && !_hasShownWelcome) {
          showModernSnackBar(
            context,
            "Welcome back! You have ${scheduleProvider.ongoingSchedules.length} ongoing schedules.",
          );
          setState(() => _hasShownWelcome = true);
        }
      });
    }

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('My Schedules'),
          actions: [
            if (_isBulkMode)
              IconButton(
                icon: const Icon(Icons.delete),
                onPressed: _deleteSelected,
              )
            else
              IconButton(
                icon: const Icon(Icons.logout),
                onPressed: () =>
                    Provider.of<AuthProvider>(context, listen: false).signOut(),
              ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Ongoing'),
              Tab(text: 'Completed'),
            ],
          ),
        ),
        drawer: Drawer(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              const DrawerHeader(
                decoration: BoxDecoration(color: Color(0xFF0D1B2A)),
                child: Text(
                  'Menu',
                  style: TextStyle(color: Colors.white, fontSize: 24),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.analytics),
                title: const Text('Weekly Resume AI'),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ResumeScreen()),
                  );
                },
              ),
            ],
          ),
        ),
        body: Column(
          children: [
            if (scheduleProvider.error != null)
              Container(
                color: Colors.red,
                width: double.infinity,
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  'Error: ${scheduleProvider.error}',
                  style: const TextStyle(color: Colors.white),
                  textAlign: TextAlign.center,
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Expanded(
                    child: StatCard(
                      title: 'Ongoing',
                      value: scheduleProvider.ongoingSchedules.length
                          .toString(),
                      icon: Icons.timer,
                      color: Colors.orange,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: StatCard(
                      title: 'Completed',
                      value: scheduleProvider.completedSchedules.length
                          .toString(),
                      icon: Icons.check_circle,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _buildScheduleList(scheduleProvider.ongoingSchedules),
                  _buildScheduleList(scheduleProvider.completedSchedules),
                ],
              ),
            ),
          ],
        ),
        floatingActionButton: _isBulkMode
            ? FloatingActionButton(
                onPressed: _toggleBulkMode,
                backgroundColor: Colors.red,
                child: const Icon(Icons.close),
              )
            : FloatingActionButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const AddScheduleScreen(),
                    ),
                  );
                },
                child: const Icon(Icons.add),
              ),
      ),
    );
  }

  Widget _buildScheduleList(List<Schedule> schedules) {
    if (schedules.isEmpty) {
      return const Center(child: Text('No schedules found.'));
    }

    return ListView.builder(
      itemCount: schedules.length,
      itemBuilder: (context, index) {
        final schedule = schedules[index];
        final isSelected = _selectedIds.contains(schedule.id);

        return Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: ScheduleCard(
            title: schedule.title,
            date: schedule.datetime,
            isCompleted: schedule.isCompleted,
            isSelected: isSelected,
            onTap: () {
              if (_isBulkMode) {
                _toggleSelection(schedule.id);
              } else {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        ScheduleDetailScreen(initialSchedule: schedule),
                  ),
                );
              }
            },
            onLongPress: () {
              if (!_isBulkMode) {
                _toggleBulkMode();
                _toggleSelection(schedule.id);
              }
            },
            onCheckboxChanged: (val) async {
              if (val == null) return;

              // Optimistically show feedback if completing
              if (!schedule.isCompleted && val) {
                showModernSnackBar(context, "Great Job! Schedule Completed!");
              }

              await Provider.of<ScheduleProvider>(
                context,
                listen: false,
              ).toggleCompletion(schedule.id, schedule.isCompleted);
            },
          ),
        );
      },
    );
  }
}
