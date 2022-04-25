import 'package:flutter/material.dart';
import 'package:videofi/screens/dashboard.dart';
import 'package:videofi/ws.dart';

class Home extends StatefulWidget {
  const Home({Key? key}) : super(key: key);

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  @override
  void initState() {
    super.initState();
    SocketConnection().initialize().then((_) {
      Navigator.pushReplacementNamed(context, Dashboard.routeName);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xff300a24),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.signal_cellular_alt,
              color: Colors.white,
            ),
            SizedBox(height: 12),
            Text('Connecting...', style: TextStyle(color: Colors.white)),
          ],
        ),
      ),
    );
  }
}
