import 'dart:async';
import 'dart:isolate';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_activity_recognition/flutter_activity_recognition.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_wearos_owntracks/isolate_message.dart';
import 'package:flutter_wearos_owntracks/mqtt_connection.dart';
import 'package:flutter_wearos_owntracks/network_info_data.dart';
import 'package:network_info_plus/network_info_plus.dart';

class ForegroundTaskhandler extends TaskHandler {
  SendPort? _sendPort;
  int _eventCount = 0;
  final _activityRecognition = FlutterActivityRecognition.instance;
  final Connectivity _connectivity = Connectivity();
  final NetworkInfo _networkInfo = NetworkInfo();
  final MQTTConnection _mqttConnection = MQTTConnection();
  StreamSubscription<Activity>? _activityStreamSubscription;
  late StreamSubscription<ConnectivityResult> _connectivitySubscription;

  @override
  Future<void> onStart(DateTime timestamp, SendPort? sendPort) async {
    _sendPort = sendPort;
    _sendPort?.send(IsolateMessage('Start'));

    _activityStreamSubscription = _activityRecognition.activityStream
        .handleError(onActivityRecognitionError)
        .listen(onActivityRecognitionReceive);

    _connectivitySubscription =
        _connectivity.onConnectivityChanged.listen(onConnectivityChanged);

    _mqttConnection.onConnected = onMQTTConnected;
    _mqttConnection.onDisconnected = onMQTTDisconnected;
    _mqttConnection.init();
    _mqttConnection.connect();
  }

  void onActivityRecognitionReceive(Activity activity) {
    debugPrint('ActivityEvent: $activity');
    FlutterForegroundTask.saveData(
        key: 'lastactivitytype', value: activity.type.name);
    FlutterForegroundTask.saveData(
        key: 'lastactivityconfidence', value: activity.confidence.name);
    _sendPort?.send(IsolateMessage('Activity', activity));
  }

  void onActivityRecognitionError(Object error) {
    debugPrint('ActivityError: $error');
  }

  Future<void> onConnectivityChanged(ConnectivityResult result) async {
    _sendPort?.send(IsolateMessage('Connectivity', result));
    if (result == ConnectivityResult.wifi) {
      NetworkInfoData networkInfoData = NetworkInfoData(
          wifiName: await _networkInfo.getWifiName(),
          wifiBSSID: await _networkInfo.getWifiBSSID());
      _sendPort?.send(IsolateMessage('NetworkInfo', networkInfoData));
    } else {
      _sendPort?.send(IsolateMessage('NetworkInfo', null));
    }
  }

  void onMQTTConnected() {
    debugPrint('MQTT connected!');
    _sendPort?.send(IsolateMessage('MQTTConnected', true));
  }

  void onMQTTDisconnected() {
    debugPrint('MQTT disconnected!');
    _sendPort?.send(IsolateMessage('MQTTConnected', false));
  }

  @override
  Future<void> onEvent(DateTime timestamp, SendPort? sendPort) async {
    FlutterForegroundTask.updateService(
        notificationTitle: 'ForegroundTaskhandler',
        notificationText: 'eventCount: $_eventCount');

    // Send data to the main isolate.
    sendPort?.send(IsolateMessage('EventCount', _eventCount));

    _eventCount++;
  }

  @override
  void onNotificationPressed() {
    // Called when the notification itself on the Android platform is pressed.
    //
    // "android.permission.SYSTEM_ALERT_WINDOW" permission must be granted for
    // this function to be called.

    // Note that the app will only route to "/resume-route" when it is exited so
    // it will usually be necessary to send a message through the send port to
    // signal it to restore state when the app is already started.
    FlutterForegroundTask.launchApp('/');
    _sendPort?.send(IsolateMessage('NotificationPressed'));
  }

  @override
  Future<void> onDestroy(DateTime timestamp, SendPort? sendPort) async {
    // You can use the clearAllData function to clear all the stored data.
    _activityStreamSubscription?.cancel();
    _connectivitySubscription.cancel();
    await FlutterForegroundTask.clearAllData();
  }
}
