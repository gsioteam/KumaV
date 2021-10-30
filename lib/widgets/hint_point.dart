
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class HintPoint extends StatelessWidget {
  final double size;

  HintPoint({
    Key? key,
    this.size = 24,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.red,
        border: Border.all(
          color: Colors.white,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor,
            offset: Offset(0, 1),
            blurRadius: 2,
          ),
        ],
        borderRadius: BorderRadius.circular(size/2)
      ),
    );
  }
}