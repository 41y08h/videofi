import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:videofi/id_display.dart';
import 'package:videofi/ws.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({Key? key}) : super(key: key);
  static const String routeName = '/dashboard';

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  @override
  void initState() {
    super.initState();
    initialize();
  }

  void initialize() async {
    final socket = await SocketConnection().initialize();
    socket.emit("join");

    socket.on("join/callback", (data) {
      print("join/callback");
      print(data);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Image.asset(
            'images/globe.png',
            height: 221,
          ),
          Text(
            'Your ID',
            style: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 20),
          IDDisplay('254975'),
          SizedBox(height: 20),
          Container(
            width: 285,
            child: Material(
              shadowColor: Colors.white,
              child: TextField(
                maxLength: 6,
                inputFormatters: <TextInputFormatter>[
                  FilteringTextInputFormatter.digitsOnly,
                ],
                keyboardType: TextInputType.number,
                cursorColor: Colors.white,
                style: const TextStyle(color: Colors.white, fontSize: 20),
                decoration: InputDecoration(
                  counterText: '',
                  hintText: "Connect to ID",
                  hintStyle: TextStyle(
                      color: Colors.grey,
                      fontFamily: 'SpaceMono',
                      fontSize: 20),
                  fillColor: Theme.of(context).scaffoldBackgroundColor,
                  filled: true,
                  enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.zero,
                      borderSide: BorderSide(color: Colors.white)),
                  focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.zero,
                      borderSide: BorderSide(color: Colors.white)),
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}
