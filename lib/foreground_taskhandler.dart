import 'dart:async';
import 'dart:isolate';
import 'package:flutter/material.dart';
import 'package:flutter_activity_recognition/flutter_activity_recognition.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_wearos_owntracks/isolate_message.dart';

class ForegroundTaskhandler extends TaskHandler {
  SendPort? _sendPort;
  int _eventCount = 0;
  final _activityRecognition = FlutterActivityRecognition.instance;
  StreamSubscription<Activity>? _activityStreamSubscription;

  @override
  Future<void> onStart(DateTime timestamp, SendPort? sendPort) async {
    _sendPort = sendPort;
    _sendPort?.send(IsolateMessage('Start'));

    _activityStreamSubscription = _activityRecognition.activityStream
        .handleError(onActivityRecognitionError)
        .listen(onActivityRecognitionReceive);
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
    await FlutterForegroundTask.clearAllData();
  }
}
