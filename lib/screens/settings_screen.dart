import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/llm_service.dart';
import '../services/history_service.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final historyService = context.read<HistoryService>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildAppInfo(context),
          const SizedBox(height: 20),
          _buildDataManagement(context, historyService),
        ],
      ),
    );
  }

  Widget _buildAppInfo(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'About Cultura',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            ListTile(
              leading: const Icon(Icons.info),
              title: const Text('Version'),
              subtitle: const Text('1.0.0'),
            ),
            ListTile(
              leading: const Icon(Icons.code),
              title: const Text('Developed with'),
              subtitle: const Text('Flutter & Google Gemini AI'),
            ),
            ListTile(
              leading: const Icon(Icons.public),
              title: const Text('Data Sources'),
              subtitle: const Text('Wikipedia, Local Knowledge'),
            ),
            ListTile(
              leading: const Icon(Icons.auto_awesome),
              title: const Text('AI Powered'),
              subtitle: const Text('Gemini AI Integration Active'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDataManagement(BuildContext context, HistoryService history) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Data Management',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.delete_outline),
                label: const Text('Clear Visit History'),
                onPressed: () => _showClearHistoryDialog(context, history),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showClearHistoryDialog(BuildContext context, HistoryService history) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Clear History'),
          content: const Text('Are you sure you want to clear all your visit history? This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                history.clearHistory();
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('History cleared')),
                );
              },
              child: const Text('Clear'),
            ),
          ],
        );
      },
    );
  }
}