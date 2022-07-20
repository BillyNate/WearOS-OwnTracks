import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_activity_recognition/flutter_activity_recognition.dart';
import 'package:flutter_wearos_owntracks/network_info_data.dart';

class ContentStateProvider extends ChangeNotifier {
  int _batteryLevel = 0;
  Activity _activityState = Activity.unknown;
  ConnectivityResult _connectivityState = ConnectivityResult.none;
  NetworkInfoData? _networkInfoData;
  bool _foregroundTaskRunningState = false;
  bool _mqttConnectedState = false;

  int get batteryLevel => _batteryLevel;
  Activity get activityState => _activityState;
  ConnectivityResult get connectivityState => _connectivityState;
  NetworkInfoData? get networkInfoData => _networkInfoData;
  bool get foregroundTaskRunningState => _foregroundTaskRunningState;
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

  void changeMQTTConnectedState(bool mqttConnectedState) {
    _mqttConnectedState = mqttConnectedState;
    notifyListeners();
  }
}
