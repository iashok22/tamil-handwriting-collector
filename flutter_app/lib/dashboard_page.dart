import 'package:flutter/material.dart';

import 'stats_service.dart';
import 'tamil_letters.dart';

/// Shows how many handwriting samples have been collected per letter, so
/// contributors can see at a glance which letters still need more coverage.
/// Sorted ascending by count (lowest first) to surface gaps.
class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final StatsService _statsService = StatsService();
  late Future<LetterStats> _statsFuture;

  @override
  void initState() {
    super.initState();
    _statsFuture = _statsService.fetchStats();
  }

  void _refresh() {
    setState(() => _statsFuture = _statsService.fetchStats());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Collection Stats'),
        actions: [
          IconButton(onPressed: _refresh, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: FutureBuilder<LetterStats>(
        future: _statsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Failed to load stats: ${snapshot.error}'));
          }

          final stats = snapshot.data!;
          // Every letter is included, even ones with zero samples so far,
          // so the "still needs coverage" gap is visible, not just absent.
          final rows = tamilLetters
              .map((letter) => MapEntry(letter, stats.counts[slugForLetter(letter)] ?? 0))
              .toList()
            ..sort((a, b) => a.value.compareTo(b.value));

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Total samples collected: ${stats.total}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: rows.length,
                  itemBuilder: (context, index) {
                    final entry = rows[index];
                    return ListTile(
                      leading: Text(
                        entry.key,
                        style: const TextStyle(fontSize: 24),
                      ),
                      title: Text('${entry.value} sample${entry.value == 1 ? '' : 's'}'),
                      trailing: entry.value == 0
                          ? const Icon(Icons.warning_amber, color: Colors.orange)
                          : null,
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
