import 'package:battery_plus/battery_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_wearos_owntracks/content_state_provider.dart';
import 'package:flutter_wearos_owntracks/foreground_task.dart';
import 'package:flutter_wearos_owntracks/isolate_message.dart';
import 'package:flutter_wearos_owntracks/screens/main_screen.dart';
import 'package:permission_handler/permission_handler.dart';
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

  Future<bool> _requestPermissions() async {
    final bool systemAlertWindowPermissionGranted =
        await Permission.systemAlertWindow.request().isGranted;
    return systemAlertWindowPermissionGranted;
  }

  Future<void> setBatteryLevel() async {
    int batteryLevel = await battery.batteryLevel;
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      Provider.of<ContentStateProvider>(context, listen: false)
          .changeBatteryLevel(batteryLevel);
    });
  }

  void _foregroundMessageReceiver(IsolateMessage message) {
    switch (message.type) {
      case 'Start':
        debugPrint('Foreground task started');
        break;
      case 'NotificationPressed':
        debugPrint('Notification pressed');
        Navigator.of(context).pushNamed('/');
        break;
      case 'EventCount':
        debugPrint('eventCount: ${message.data}');
        setBatteryLevel();
        break;
      case 'Timestamp':
        debugPrint('timestamp: ${message.toString()}');
        break;
    }
  }

  Future<void> setupForegroundTask() async {
    ForegroundTask.foregroundMessageReceiver = _foregroundMessageReceiver;
    ForegroundTask.managePermissions();
    ForegroundTask.initForegroundTask();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) async {
      if (await FlutterForegroundTask.isRunningService) {
        await ForegroundTask.resumeForegroundTask();
      } else {
        await ForegroundTask.startForegroundTask();
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _requestPermissions();
    setBatteryLevel();
    setupForegroundTask();
  }

  @override
  Widget build(BuildContext context) {
    return WithForegroundTask(
      child: Scaffold(
        body: _mainContentView,
      ),
    );
  }
}
