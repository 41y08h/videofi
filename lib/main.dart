import 'package:flutter/material.dart';
import 'package:videofi/screens/dashboard.dart';
import 'package:videofi/screens/home.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Color(0xff300a24),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const Home(),
        '/dashboard': (context) => const Dashboard(),
      },
    );
  }
}
