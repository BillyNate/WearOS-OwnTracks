import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_activity_recognition/flutter_activity_recognition.dart';
import 'package:flutter_wearos_owntracks/known_locations.dart';
import 'package:flutter_wearos_owntracks/network_info_data.dart';

class GPSDecider {
  late Function callback;
  Activity? _activity;
  ConnectivityResult? _connectivityResult;
  NetworkInfoData? _networkInfoData;
  bool _pleaseEnableGPS = false;

  GPSDecider(this.callback);

  void makeDecision() {
    if ((_activity?.type == ActivityType.STILL ||
            (_connectivityResult == ConnectivityResult.wifi &&
                knownLocations.containsKey(_networkInfoData?.wifiBSSID))) !=
        !_pleaseEnableGPS) {
      _pleaseEnableGPS = !_pleaseEnableGPS;
      callback(_pleaseEnableGPS);
    }
  }

  Activity? get activity => _activity;

  set activity(Activity? activity) {
    _activity = activity;
    makeDecision();
  }

  ConnectivityResult? get connectivityResult => _connectivityResult;

  set connectivityResult(ConnectivityResult? connectivityResult) {
    _connectivityResult = connectivityResult;
    makeDecision();
  }

  NetworkInfoData? get networkInfoData => _networkInfoData;

  set networkInfoData(NetworkInfoData? networkInfoData) {
    _networkInfoData = networkInfoData;
    makeDecision();
  }
}
