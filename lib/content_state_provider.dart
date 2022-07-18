import 'package:flutter/material.dart';
import 'package:flutter_activity_recognition/flutter_activity_recognition.dart';

class ContentStateProvider extends ChangeNotifier {
  int _batteryLevel = 0;
  Activity _activityState = Activity.unknown;

  int get batteryLevel => _batteryLevel;
  Activity get activityState => _activityState;

  void changeBatteryLevel(int batteryLevel) {
    _batteryLevel = batteryLevel;
    notifyListeners();
  }

  void changeActivityState(Activity activityState) {
    _activityState = activityState;
    notifyListeners();
  }
}
