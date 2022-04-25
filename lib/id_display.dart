import 'package:flutter/material.dart';

class IDDisplay extends StatelessWidget {
  final String id;
  const IDDisplay(this.id, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: id
            .split("") // Split every character
            .map((idItem) => Container(
                  margin: const EdgeInsets.only(right: 8),
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                    child: Text(
                      idItem,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          fontSize: 20),
                    ),
                  ),
                  decoration:
                      BoxDecoration(border: Border.all(color: Colors.white)),
                ))
            .toList());
  }
}
