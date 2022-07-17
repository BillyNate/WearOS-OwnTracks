import 'package:battery_plus/battery_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_wearos_owntracks/content_state_provider.dart';
import 'package:flutter_wearos_owntracks/screens/main_screen.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<ContentStateProvider>(
        create: (BuildContext context) => ContentStateProvider(),
        child: MaterialApp(
          initialRoute: '/',
          routes: {
            '/': (context) => const MyPage(),
          },
        ));
  }
}

class MyPage extends StatefulWidget {
  const MyPage({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _MyPageState();
}

class _MyPageState extends State<MyPage> {
  final _mainContentView = const MainContentView();
  final battery = Battery();

  Future<void> setBatteryLevel() async {
    int batteryLevel = await battery.batteryLevel;
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      Provider.of<ContentStateProvider>(context, listen: false)
          .changeBatteryLevel(batteryLevel);
    });
  }

  @override
  void initState() {
    super.initState();
    setBatteryLevel();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _mainContentView,
    );
  }
}
