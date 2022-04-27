import 'package:flutter/material.dart';

class ConnectingOverlay extends StatelessWidget {
  const ConnectingOverlay({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(
            Icons.signal_cellular_alt,
            color: Colors.white,
          ),
          SizedBox(height: 12),
          Text('Connecting...', style: TextStyle(color: Colors.white)),
        ],
      ),
    );
  }
}
