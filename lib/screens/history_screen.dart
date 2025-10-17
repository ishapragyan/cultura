import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../services/history_service.dart';
import '../services/llm_service.dart';
import '../models/history_entry.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  String? _journeySummary;

  @override
  Widget build(BuildContext context) {
    final historyService = context.watch<HistoryService>();
    final llmService = context.watch<LlmService>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Cultural Journey'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          if (historyService.recentVisits.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.share),
              onPressed: () => _shareJourney(historyService),
            ),
        ],
      ),
      body: _buildContent(context, historyService, llmService),
    );
  }

  Widget _buildContent(BuildContext context, HistoryService history, LlmService llm) {
    if (history.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (history.recentVisits.isEmpty) {
      return _buildEmptyState(context);
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSummarySection(context, history, llm),
          const SizedBox(height: 20),
          _buildHistoryList(context, history),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.travel_explore, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            'No travel history yet',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Visit some locations to build your cultural journey',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildSummarySection(BuildContext context, HistoryService history, LlmService llm) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Journey Summary',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                IconButton(
                  icon: const Icon(Icons.auto_awesome),
                  onPressed: _journeySummary == null
                      ? () => _generateSummary(history, llm)
                      : null,
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (_journeySummary != null) ...[
              Text(_journeySummary!),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.share),
                  label: const Text('Share Journey'),
                  onPressed: () => _shareJourney(history),
                ),
              ),
            ] else if (llm.isLoading) ...[
              const Center(child: CircularProgressIndicator()),
              const SizedBox(height: 8),
              const Text('Generating AI summary...'),
            ] else ...[
              Text(
                'Generate an AI-powered summary of your cultural exploration',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.auto_awesome),
                  label: const Text('Generate AI Summary'),
                  onPressed: () => _generateSummary(history, llm),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryList(BuildContext context, HistoryService history) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Visits',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        ...history.recentVisits.map((visit) => _buildHistoryCard(context, visit)),
      ],
    );
  }

  Widget _buildHistoryCard(BuildContext context, HistoryEntry visit) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  visit.city,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  _formatDate(visit.timestamp),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            Text(
              visit.state,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: visit.keywords.map((keyword) {
                return Chip(
                  label: Text(keyword),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                );
              }).toList(),
            ),
            if (visit.culturalSummary != null) ...[
              const SizedBox(height: 8),
              Text(
                visit.culturalSummary!,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Future<void> _generateSummary(HistoryService history, LlmService llm) async {
    final visits = history.recentVisits
        .map((v) => {
      'city': v.city,
      'keywords': v.keywords,
    })
        .toList();

    final summary = await llm.generateJourneySummary(visits);

    if (summary != null) {
      setState(() {
        _journeySummary = summary;
      });
    }
  }

  Future<void> _shareJourney(HistoryService history) async {
    final String shareText = _buildShareText(history);
    await Share.share(shareText);
  }

  String _buildShareText(HistoryService history) {
    final buffer = StringBuffer();
    buffer.writeln('🌍 My Cultural Journey with Cultura App\n');

    for (final visit in history.recentVisits) {
      buffer.writeln('📍 ${visit.city}, ${visit.state}');
      buffer.writeln('📅 ${_formatDate(visit.timestamp)}');
      buffer.writeln('🏷️ ${visit.keywords.join(', ')}');
      buffer.writeln();
    }

    if (_journeySummary != null) {
      buffer.writeln('📖 Journey Summary:');
      buffer.writeln(_journeySummary!);
    }

    buffer.writeln('\nDownload Cultura App to explore Indian culture!');

    return buffer.toString();
  }
}