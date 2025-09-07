import 'package:flutter/material.dart';

class PlaceTile extends StatelessWidget {
  final String name;
  final String category;
  final int crowdLevel; // 1–5
  final int waitTime;

  const PlaceTile({
    super.key,
    required this.name,
    required this.category,
    required this.crowdLevel,
    required this.waitTime,
  });

  Color getCrowdColor() {
    switch (crowdLevel) {
      case 1: return Colors.green;
      case 2: return Colors.lightGreen;
      case 3: return Colors.yellow;
      case 4: return Colors.orange;
      case 5: return Colors.red;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text('$name ($category)'),
      subtitle: Text('Wartezeit: $waitTime min'),
      trailing: CircleAvatar(
        backgroundColor: getCrowdColor(),
        radius: 10,
      ),
    );
  }
}
