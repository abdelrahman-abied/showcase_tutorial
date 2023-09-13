import 'package:flutter/material.dart';
import 'package:showcase_tutorial/showcase_tutorial.dart';

class ShipToolTip extends StatelessWidget {
  final BuildContext parentContext;
  const ShipToolTip({
    Key? key,
    required this.parentContext,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        GestureDetector(
          onTap: () {
            ShowCaseWidget.of(parentContext).dismiss();
          },
          child: const Text(
            "Skip ",
            style: TextStyle(color: Colors.black),
          ),
        ),
        const SizedBox(width: 100),
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
              border: Border.all(color: Colors.black, width: 2),
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(50.0)),
          alignment: Alignment.center,
          child: IconButton(
            padding: EdgeInsets.zero,
            onPressed: () {
              ShowCaseWidget.of(parentContext).previous();
            },
            icon: const Icon(
              Icons.arrow_back_outlined,
              size: 21,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
              border: Border.all(color: Colors.black, width: 2),
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(50.0)),
          alignment: Alignment.center,
          child: IconButton(
            padding: EdgeInsets.zero,
            onPressed: () {
              ShowCaseWidget.of(parentContext).next();
            },
            icon: const Icon(
              Icons.arrow_forward_outlined,
              size: 21,
            ),
          ),
        ),
      ],
    );
  }
}