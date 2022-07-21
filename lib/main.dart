import 'dart:convert';
import 'package:battery_plus/battery_plus.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_activity_recognition/flutter_activity_recognition.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_wearos_owntracks/content_state_provider.dart';
import 'package:flutter_wearos_owntracks/foreground_task.dart';
import 'package:flutter_wearos_owntracks/isolate_message.dart';
import 'package:flutter_wearos_owntracks/network_info_data.dart';
import 'package:flutter_wearos_owntracks/screens/main_screen.dart';
import 'package:geolocator/geolocator.dart';
import 'package:network_info_plus/network_info_plus.dart';
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
  final NetworkInfo _networkInfo = NetworkInfo();

  Future<bool> _requestPermissions() async {
    final bool systemAlertWindowPermissionGranted =
        await Permission.systemAlertWindow.request().isGranted;
    final bool activityRecognitionPermissionGranted =
        await Permission.activityRecognition.request().isGranted;
    final bool locationAlwaysPermissionGranted =
        await Permission.locationAlways.request().isGranted;

    return (systemAlertWindowPermissionGranted &&
        activityRecognitionPermissionGranted &&
        locationAlwaysPermissionGranted);
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
      case 'GPS':
        debugPrint('gps: ${message.data.toString()}');
        WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
          Provider.of<ContentStateProvider>(context, listen: false)
              .changeGPSListeningState(message.data);
        });
        break;
      case 'MQTTConnected':
        debugPrint('MQTTConnected: ${message.data}');
        WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
          Provider.of<ContentStateProvider>(context, listen: false)
              .changeMQTTConnectedState(message.data);
        });
        break;
      case 'NetworkInfo':
        debugPrint(
            'NetworkInfo ${message.data != null ? ': ${message.data?.wifiName}' : ''}');
        WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
          Provider.of<ContentStateProvider>(context, listen: false)
              .changeNetworkInfo(message.data);
        });
        break;
      case 'NotificationPressed':
        debugPrint('Notification pressed');
        Navigator.of(context).pushNamed('/');
        break;
      case 'Position':
        debugPrint(
            'GPS position: ${message.data.longitude.toString()}, ${message.data.latitude.toString()}');
        WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
          Provider.of<ContentStateProvider>(context, listen: false)
              .changeGPSPosition(message.data);
        });
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
    late NetworkInfoData networkInfoData;

    try {
      result = await _connectivity.checkConnectivity();
      if (result == ConnectivityResult.wifi) {
        networkInfoData = NetworkInfoData(
            wifiName: await _networkInfo.getWifiName(),
            wifiBSSID: await _networkInfo.getWifiBSSID());
      }

      WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
        Provider.of<ContentStateProvider>(context, listen: false)
            .changeConnectivityState(result);
        if (result == ConnectivityResult.wifi) {
          Provider.of<ContentStateProvider>(context, listen: false)
              .changeNetworkInfo(networkInfoData);
        }
      });
    } on PlatformException catch (error) {
      debugPrint('Couldn\'t check connectivity status $error');
      return false;
    }
    return true;
  }

  Future<void> restoreContent() async {
    String? lastactivityData =
        await FlutterForegroundTask.getData(key: 'lastactivity');

    bool? mqttConnected =
        await FlutterForegroundTask.getData(key: 'mqttconnected');

    bool? gpsTurnedOn = await FlutterForegroundTask.getData(key: 'gps');
    String? gpsposition =
        await FlutterForegroundTask.getData(key: 'gpsposition');

    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      Provider.of<ContentStateProvider>(context, listen: false)
          .changeForegroundTaskRunningState(true);

      if (lastactivityData != null) {
        debugPrint('lastactivity: $lastactivityData');
        Map<String, dynamic> lastactivity = json.decode(lastactivityData);
        Activity activity = Activity(
          getActivityTypeFromString(lastactivity['type']),
          getActivityConfidenceFromString(lastactivity['confidence']),
        );

        Provider.of<ContentStateProvider>(context, listen: false)
            .changeActivityState(activity);
      }

      if (mqttConnected != null) {
        Provider.of<ContentStateProvider>(context, listen: false)
            .changeMQTTConnectedState(mqttConnected);
      }

      if (gpsTurnedOn != null) {
        Provider.of<ContentStateProvider>(context, listen: false)
            .changeGPSListeningState(gpsTurnedOn);
      }

      if (gpsposition != null) {
        debugPrint('gpsposition: $gpsposition');
        Provider.of<ContentStateProvider>(context, listen: false)
            .changeGPSPosition(Position.fromMap(json.decode(gpsposition)));
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
