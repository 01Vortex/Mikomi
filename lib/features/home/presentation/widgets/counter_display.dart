import 'package:flutter/material.dart';

class CounterDisplay extends StatelessWidget {
  final int counter;

  const CounterDisplay({super.key, required this.counter});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text('你已经点击按钮次数:'),
        Text('$counter', style: Theme.of(context).textTheme.headlineMedium),
      ],
    );
  }
}
