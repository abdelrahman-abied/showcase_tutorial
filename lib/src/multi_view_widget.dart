import 'package:flutter/material.dart';

class MultiView extends StatelessWidget {
  final Widget child;
  const MultiView({Key? key, required this.child}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: child,
    );
  }
}
