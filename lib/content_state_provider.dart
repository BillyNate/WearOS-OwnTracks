import 'package:flutter/material.dart';

class ContentStateProvider extends ChangeNotifier {
  int _batteryLevel = 0;

  int get batteryLevel => _batteryLevel;

  void changeBatteryLevel(int batteryLevel) {
    _batteryLevel = batteryLevel;
    notifyListeners();
  }
}
