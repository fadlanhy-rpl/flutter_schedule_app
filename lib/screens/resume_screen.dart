import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/schedule_provider.dart';
import '../widgets/custom_widgets.dart';

class ResumeScreen extends StatefulWidget {
  const ResumeScreen({super.key});

  @override
  State<ResumeScreen> createState() => _ResumeScreenState();
}

class _ResumeScreenState extends State<ResumeScreen> {
  String? _resumeContent;
  bool _isLoading = false;

  void _generateResume() async {
    setState(() => _isLoading = true);
    final provider = Provider.of<ScheduleProvider>(context, listen: false);

    final content = await provider.generateWeeklyResume();

    setState(() {
      _resumeContent = content;
      _isLoading = false;
    });
  }

  void _copyToClipboard() {
    if (_resumeContent != null) {
      Clipboard.setData(ClipboardData(text: _resumeContent!));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Resume copied to clipboard!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Weekly Resume AI')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Get a productivity summary of your completed tasks this week.',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            CustomButton(
              text: 'Generate Resume',
              onPressed: _generateResume,
              isLoading: _isLoading,
            ),
            const SizedBox(height: 24),
            if (_resumeContent != null) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Result:",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy, color: Colors.white),
                    onPressed: _copyToClipboard,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1B263B), // Medium Blue
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.withOpacity(0.2)),
                  ),
                  child: SingleChildScrollView(
                    child: Text(
                      _resumeContent!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        height: 1.5,
                      ),
                    ),
                  ),
                ),
              ),
            ] else if (!_isLoading)
              const Expanded(
                child: Center(
                  child: Icon(
                    Icons.analytics_outlined,
                    size: 64,
                    color: Colors.grey,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
