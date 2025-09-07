import 'package:flutter/material.dart';

class DayPlanner extends StatelessWidget {
  final List<Map<String,dynamic>> places;

  const DayPlanner({super.key, required this.places});

  List<Map<String,dynamic>> optimizeDay(List<Map<String,dynamic>> places) {
    // Sehr einfache Sortierung: nach geringster Wartezeit zuerst
    List<Map<String,dynamic>> sorted = List.from(places);
    sorted.sort((a,b) => (a['waitTime'] ?? 0).compareTo(b['waitTime'] ?? 0));
    return sorted;
  }

  @override
  Widget build(BuildContext context) {
    final plan = optimizeDay(places);
    return Column(
      children: plan.map((p) => ListTile(
        title: Text(p['name']),
        subtitle: Text('Wartezeit: ${p['waitTime']} min | ${p['category']}'),
      )).toList(),
    );
  }
}
