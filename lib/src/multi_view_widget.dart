import 'package:flutter/material.dart';

class MultiViewWidget extends RepaintBoundary {
  final Widget child;
  const MultiViewWidget({Key? key, required this.child}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: child,
    );
  }
}
