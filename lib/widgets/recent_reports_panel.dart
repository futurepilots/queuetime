import 'package:flutter/material.dart';
import 'place_tile.dart';

class RecentReportsPanel extends StatelessWidget {
  final List<Map<String, dynamic>> reports;

  const RecentReportsPanel({super.key, required this.reports});

  @override
  Widget build(BuildContext context) {
    if (reports.isEmpty) return const Text('Noch keine Meldungen');
    return Column(
      children: reports.map((r) => PlaceTile(
        name: r['name'],
        category: r['category'],
        crowdLevel: r['crowdLevel'],
        waitTime: r['waitTime'],
      )).toList(),
    );
  }
}
