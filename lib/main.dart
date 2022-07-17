import 'package:flutter/material.dart';
import 'package:flutter_wearos_owntracks/screens/main_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      initialRoute: '/',
      routes: {
        '/': (context) => const MyPage(),
      },
    );
  }
}

class MyPage extends StatefulWidget {
  const MyPage({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _MyPageState();
}

class _MyPageState extends State<MyPage> {
  final _mainContentView = const MainContentView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _mainContentView,
    );
  }
}
