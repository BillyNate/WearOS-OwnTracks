import 'dart:isolate';
import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_wearos_owntracks/foreground_taskhandler.dart';

void foregroundCallback() {
  // The setTaskHandler function must be called to handle the task in the background.
  FlutterForegroundTask.setTaskHandler(ForegroundTaskhandler());
}

class ForegroundTask {
  static ReceivePort? _receivePort;
  static Function? foregroundMessageReceiver;

  static Future<void> initForegroundTask() async {
    await FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'flutter_wearos_owntracks_channel_id',
        channelName: 'OwnTracks',
        channelDescription:
            'This notification appears when the foreground service is running.',
        channelImportance: NotificationChannelImportance.LOW,
        priority: NotificationPriority.LOW,
        iconData: const NotificationIconData(
          resType: ResourceType.mipmap,
          resPrefix: ResourcePrefix.ic,
          name: 'launcher',
          backgroundColor: Colors.orange,
        ),
      ),
      foregroundTaskOptions: const ForegroundTaskOptions(
        interval: 5000,
        autoRunOnBoot: true,
        allowWifiLock: true,
      ),
      printDevLog: true,
    );
  }

  static Future<bool> startForegroundTask() async {
    return _registerReceivePort(await FlutterForegroundTask.startService(
      notificationTitle: 'Foreground Service is running',
      notificationText: 'Tap to return to the app',
      callback: foregroundCallback,
    ));
  }

  static Future<bool> restartForegroundTask() async {
    return _registerReceivePort(await FlutterForegroundTask.restartService());
  }

  static Future<bool> resumeForegroundTask() async {
    return _registerReceivePort(await FlutterForegroundTask.receivePort);
  }

  static Future<bool> stopForegroundTask() async {
    return await FlutterForegroundTask.stopService();
  }

  static bool _registerReceivePort(ReceivePort? receivePort) {
    _closeReceivePort();

    if (receivePort != null) {
      _receivePort = receivePort;
      _receivePort?.listen((message) {
        foregroundMessageReceiver?.call(message);
      });

      return true;
    }

    return false;
  }

  static void _closeReceivePort() {
    _receivePort?.close();
    _receivePort = null;
  }
}
