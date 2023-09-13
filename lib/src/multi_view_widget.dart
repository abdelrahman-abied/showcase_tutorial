import 'package:flutter/material.dart';

class MutliView extends StatelessWidget {
  final Widget child;
  const MutliView({Key? key, required this.child}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: child,
    );
  }
}
