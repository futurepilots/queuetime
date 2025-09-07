import 'package:flutter/material.dart';

class Sparkline extends StatelessWidget {
  final List<int> data;
  const Sparkline({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) return const SizedBox.shrink();
    final maxVal = data.reduce((a,b) => a>b?a:b).toDouble();
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: data.map((val) => Expanded(
        child: Container(
          height: (val/maxVal)*100,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          color: Colors.purple,
        ),
      )).toList(),
    );
  }
}
