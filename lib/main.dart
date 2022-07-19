import 'package:battery_plus/battery_plus.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_activity_recognition/flutter_activity_recognition.dart';
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
  final Connectivity _connectivity = Connectivity();

  Future<bool> _requestPermissions() async {
    final bool systemAlertWindowPermissionGranted =
        await Permission.systemAlertWindow.request().isGranted;
    final bool activityRecognitionPermissionGranted =
        await Permission.activityRecognition.request().isGranted;
    return (systemAlertWindowPermissionGranted &&
        activityRecognitionPermissionGranted);
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
        WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
          Provider.of<ContentStateProvider>(context, listen: false)
              .changeForegroundTaskRunningState(true);
        });
        break;
      case 'Activity':
        debugPrint('activity: ${message.data}');
        WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
          Provider.of<ContentStateProvider>(context, listen: false)
              .changeActivityState(message.data);
        });
        break;
      case 'Connectivity':
        debugPrint('connectivity: ${message.data}');
        WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
          Provider.of<ContentStateProvider>(context, listen: false)
              .changeConnectivityState(message.data);
        });
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
      default:
        debugPrint('Received unknown message of type ${message.type}');
        break;
    }
  }

  Future<void> setupForegroundTask() async {
    ForegroundTask.foregroundMessageReceiver = _foregroundMessageReceiver;
    ForegroundTask.initForegroundTask();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) async {
      if (await FlutterForegroundTask.isRunningService) {
        await ForegroundTask.resumeForegroundTask();
        await restoreContent();
      } else {
        await ForegroundTask.startForegroundTask();
      }
    });
  }

  Future<bool> getConnectivity() async {
    late ConnectivityResult result;

    try {
      result = await _connectivity.checkConnectivity();

      WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
        Provider.of<ContentStateProvider>(context, listen: false)
            .changeConnectivityState(result);
      });
    } on PlatformException catch (error) {
      debugPrint('Couldn\'t check connectivity status $error');
      return false;
    }
    return true;
  }

  Future<void> restoreContent() async {
    final lastactivitytype =
        await FlutterForegroundTask.getData(key: 'lastactivitytype');
    final lastactivityconfidence =
        await FlutterForegroundTask.getData(key: 'lastactivityconfidence');

    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      Provider.of<ContentStateProvider>(context, listen: false)
          .changeForegroundTaskRunningState(true);

      if (lastactivitytype != null && lastactivityconfidence != null) {
        final activity = Activity(getActivityTypeFromString(lastactivitytype),
            getActivityConfidenceFromString(lastactivityconfidence));

        Provider.of<ContentStateProvider>(context, listen: false)
            .changeActivityState(activity);
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _requestPermissions();
    setBatteryLevel();
    getConnectivity();
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
