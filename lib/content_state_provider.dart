import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_activity_recognition/flutter_activity_recognition.dart';
import 'package:flutter_wearos_owntracks/network_info_data.dart';
import 'package:geolocator/geolocator.dart';

class ContentStateProvider extends ChangeNotifier {
  int _batteryLevel = 0;
  Activity _activityState = Activity.unknown;
  ConnectivityResult _connectivityState = ConnectivityResult.none;
  NetworkInfoData? _networkInfoData;
  bool _foregroundTaskRunningState = false;
  bool _gpsListeningState = false;
  Position? _gpsPosition;
  bool _mqttConnectedState = false;

  int get batteryLevel => _batteryLevel;
  Activity get activityState => _activityState;
  ConnectivityResult get connectivityState => _connectivityState;
  NetworkInfoData? get networkInfoData => _networkInfoData;
  bool get foregroundTaskRunningState => _foregroundTaskRunningState;
  bool get gpsListeningState => _gpsListeningState;
  Position? get gpsPosition => _gpsPosition;
  bool get mqttConnectedState => _mqttConnectedState;

  void changeBatteryLevel(int batteryLevel) {
    _batteryLevel = batteryLevel;
    notifyListeners();
  }

  void changeActivityState(Activity activityState) {
    _activityState = activityState;
    notifyListeners();
  }

  void changeConnectivityState(ConnectivityResult connectivityState) {
    _connectivityState = connectivityState;
    notifyListeners();
  }

  void changeNetworkInfo(NetworkInfoData networkInfoData) {
    _networkInfoData = networkInfoData;
    notifyListeners();
  }

  void changeForegroundTaskRunningState(bool foregroundTaskRunningState) {
    _foregroundTaskRunningState = foregroundTaskRunningState;
    notifyListeners();
  }

  void changeGPSListeningState(bool gpsListeningState) {
    _gpsListeningState = gpsListeningState;
    notifyListeners();
  }

  void changeGPSPosition(Position gpsPosition) {
    _gpsPosition = gpsPosition;
    notifyListeners();
  }

  void changeMQTTConnectedState(bool mqttConnectedState) {
    _mqttConnectedState = mqttConnectedState;
    notifyListeners();
  }
}
