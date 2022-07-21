import 'dart:async';
import 'dart:convert';
import 'dart:isolate';
import 'package:battery_plus/battery_plus.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_activity_recognition/flutter_activity_recognition.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_wearos_owntracks/isolate_message.dart';
import 'package:flutter_wearos_owntracks/known_locations.dart';
import 'package:flutter_wearos_owntracks/mqtt_connection.dart';
import 'package:flutter_wearos_owntracks/network_info_data.dart';
import 'package:flutter_wearos_owntracks/owntracks_message.dart';
import 'package:flutter_wearos_owntracks/gps_decider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:network_info_plus/network_info_plus.dart';

class ForegroundTaskhandler extends TaskHandler {
  SendPort? _sendPort;
  int _eventCount = 0;
  int _batteryLevel = 100;
  OwnTracksMessage? _lastOwnTracksMessage;
  final _battery = Battery();
  final _activityRecognition = FlutterActivityRecognition.instance;
  final Connectivity _connectivity = Connectivity();
  final NetworkInfo _networkInfo = NetworkInfo();
  final MQTTConnection _mqttConnection = MQTTConnection();
  final LocationSettings _locationSettings = AndroidSettings(
    accuracy: LocationAccuracy.high,
    forceLocationManager: true,
    intervalDuration: const Duration(seconds: 30),
    distanceFilter: 5,
  );
  late GPSDecider _gpsDecider;
  StreamSubscription<Activity>? _activityStreamSubscription;
  late StreamSubscription<ConnectivityResult> _connectivitySubscription;
  StreamSubscription<Position>? _positionStream;

  @override
  Future<void> onStart(DateTime timestamp, SendPort? sendPort) async {
    _sendPort = sendPort;
    _sendPort?.send(IsolateMessage('Start'));

    _gpsDecider = GPSDecider(onGSPSwitch);

    _activityStreamSubscription = _activityRecognition.activityStream
        .handleError(onActivityRecognitionError)
        .listen(onActivityRecognitionReceive);

    _connectivitySubscription =
        _connectivity.onConnectivityChanged.listen(onConnectivityChanged);

    _mqttConnection.onConnected = onMQTTConnected;
    _mqttConnection.onDisconnected = onMQTTDisconnected;
    _mqttConnection.onAutoReconnected = onMQTTAutoReconnected;
    _mqttConnection.init();
    _mqttConnection.connect();
  }

  Future<void> onGSPSwitch(bool enableGPS) async {
    debugPrint('Turn GPS ${enableGPS ? 'on' : 'off'}');

    FlutterForegroundTask.saveData(key: 'gps', value: enableGPS);
    if (enableGPS && _positionStream == null) {
      _positionStream =
          Geolocator.getPositionStream(locationSettings: _locationSettings)
              .listen(onPositionChanged);
      _sendPort?.send(IsolateMessage('GPS', true));
      //await Geolocator.getCurrentPosition(forceAndroidLocationManager: true);
    } else if (!enableGPS) {
      _positionStream?.cancel();
      _positionStream = null;
      _sendPort?.send(IsolateMessage('GPS', false));

      if (_gpsDecider.connectivityResult == ConnectivityResult.wifi) {
        if (knownLocations
            .containsKey(_gpsDecider.networkInfoData?.wifiBSSID)) {
          if (knownLocations[_gpsDecider.networkInfoData?.wifiBSSID] != null) {
            OwnTracksMessage ownTracksMessage = OwnTracksMessage(
              type: 'location',
              tst: (DateTime.now().millisecondsSinceEpoch / 1000).round(),
              lat: knownLocations[_gpsDecider.networkInfoData?.wifiBSSID]!
                  .latitude,
              lon: knownLocations[_gpsDecider.networkInfoData?.wifiBSSID]!
                  .longitude,
            );

            publishToMQTT(ownTracksMessage);
          }
        }
      } else {
        Position? position = await Geolocator.getLastKnownPosition(
            forceAndroidLocationManager: true);
        if (position != null) {
          OwnTracksMessage ownTracksMessage = OwnTracksMessage(
            type: 'location',
            tst: (DateTime.now().millisecondsSinceEpoch / 1000).round(),
            lat: position.latitude,
            lon: position.longitude,
            acc: position.accuracy.toInt(),
            alt: position.altitude.toInt(),
          );

          publishToMQTT(ownTracksMessage);
        }
      }
    }
  }

  void onActivityRecognitionReceive(Activity activity) {
    _gpsDecider.activity = activity;
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
    _gpsDecider.connectivityResult = result;
    _sendPort?.send(IsolateMessage('Connectivity', result));
    if (result == ConnectivityResult.wifi) {
      NetworkInfoData networkInfoData = NetworkInfoData(
          wifiName: await _networkInfo.getWifiName(),
          wifiBSSID: await _networkInfo.getWifiBSSID());
      _gpsDecider.networkInfoData = networkInfoData;
      _sendPort?.send(IsolateMessage('NetworkInfo', networkInfoData));
    } else {
      _gpsDecider.networkInfoData = null;
      _sendPort?.send(IsolateMessage('NetworkInfo', null));
    }
  }

  void onPositionChanged(Position? position) {
    if (position != null) {
      debugPrint(
          'Location: ${position.latitude.toString()}, ${position.longitude.toString()}');

      _sendPort?.send(IsolateMessage('Position', position));
      FlutterForegroundTask.saveData(
          key: 'gpsposition', value: json.encode(position.toJson()));

      OwnTracksMessage ownTracksMessage = OwnTracksMessage(
        type: 'location',
        tst: (DateTime.now().millisecondsSinceEpoch / 1000).round(),
        lat: position.latitude,
        lon: position.longitude,
        acc: position.accuracy.toInt(),
        alt: position.altitude.toInt(),
      );
      publishToMQTT(ownTracksMessage);
    }
  }

  void onMQTTConnected() {
    debugPrint('MQTT connected!');
    _sendPort?.send(IsolateMessage('MQTTConnected', true));
    FlutterForegroundTask.saveData(key: 'mqttconnected', value: true);
    if (_lastOwnTracksMessage != null) {
      _mqttConnection.publishOwnTracksMessage(_lastOwnTracksMessage!);
      _lastOwnTracksMessage = null;
    }
  }

  void onMQTTDisconnected() {
    debugPrint('MQTT disconnected!');
    _sendPort?.send(IsolateMessage('MQTTConnected', false));
    FlutterForegroundTask.saveData(key: 'mqttconnected', value: false);
  }

  void onMQTTAutoReconnected() {
    debugPrint('MQTT auto reconnected!');
    _sendPort?.send(IsolateMessage('MQTTConnected', true));
    FlutterForegroundTask.saveData(key: 'mqttconnected', value: true);
    if (_lastOwnTracksMessage != null) {
      _mqttConnection.publishOwnTracksMessage(_lastOwnTracksMessage!);
      _lastOwnTracksMessage = null;
    }
  }

  @override
  Future<void> onEvent(DateTime timestamp, SendPort? sendPort) async {
    FlutterForegroundTask.updateService(
        notificationTitle: 'ForegroundTaskhandler',
        notificationText: 'eventCount: $_eventCount');

    // Send data to the main isolate.
    sendPort?.send(IsolateMessage('EventCount', _eventCount));

    _batteryLevel = await _battery.batteryLevel;

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

  void publishToMQTT(OwnTracksMessage ownTracksMessage) {
    ownTracksMessage.batt = _batteryLevel;

    if ([ConnectivityResult.wifi, ConnectivityResult.ethernet]
        .contains(_gpsDecider.connectivityResult)) {
      ownTracksMessage.conn = 'w';
      if (_gpsDecider.networkInfoData?.wifiName != null) {
        ownTracksMessage.ssid = _gpsDecider.networkInfoData?.wifiName;
      }
      if (_gpsDecider.networkInfoData?.wifiBSSID != null) {
        ownTracksMessage.bssid = _gpsDecider.networkInfoData?.wifiBSSID;
      }
    } else if ([ConnectivityResult.mobile, ConnectivityResult.bluetooth]
        .contains(_gpsDecider.connectivityResult)) {
      ownTracksMessage.conn = 'm';
    } else if (_gpsDecider.connectivityResult == ConnectivityResult.none) {
      ownTracksMessage.conn = 'o';
    }

    if (_mqttConnection.connectionStatus!.state ==
        MqttConnectionState.connected) {
      _mqttConnection.publishOwnTracksMessage(ownTracksMessage);
    } else {
      _lastOwnTracksMessage = ownTracksMessage;
    }
  }
}
