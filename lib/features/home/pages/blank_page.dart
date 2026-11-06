import 'package:flutter/material.dart';

/// A lightweight blank page for sidebar destinations currently under development.
class BlankPage extends StatelessWidget {
  const BlankPage({super.key, this.title});

  final String? title;

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: Color(0xFF12111A),
      child: SizedBox.expand(),
    );
  }
}
