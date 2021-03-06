import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:videofi/providers/call_provider.dart';
import 'package:videofi/screens/call.dart';
import 'package:videofi/screens/home.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (context) => CallProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Color(0xff000000),
    ));
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xff300a24),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const Home(),
        Call.routeName: (context) => const Call(),
      },
    );
  }
}
