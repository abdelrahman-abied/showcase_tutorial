import 'package:flutter/material.dart';

class MultiView extends StatelessWidget {
  final Widget child;
  const MultiView({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: child,
    );
  }
}
