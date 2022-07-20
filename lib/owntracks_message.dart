import 'dart:convert';

class OwnTracksMessage {
  OwnTracksMessage(
      {required this.type,
      required this.lat,
      required this.lon,
      required this.tst,
      this.bssid,
      this.ssid,
      this.acc,
      this.alt,
      this.batt,
      this.bs,
      this.conn,
      this.createdAt,
      this.m,
      this.t});
  final String type;
  final double lat; // latitude
  final double lon; // longitude
  final int tst; // UNIX epoch timestamp in seconds of the location fix
  late String? bssid;
  late String? ssid;
  late int? acc; // Accuracy of the reported location in meters
  late int? alt; // Altitude measured above sea level
  late int? batt = -1; // Device battery level
  late int? bs = 0; //Battery Status 0=unknown, 1=unplugged, 2=charging, 3=full
  late String? conn; // Internet connectivity status w=wifi, o=offline, m=mobile
  late int? createdAt;
  late int? m; // Monitoring mode at which the message is constructed
  late String? t; // Trigger for the location report
  /*
  tid; // Tracker ID used to display the initials of a user
  vac; // Vertical accuracy of the alt element
  vel; // Velocity
  u;
  */

  String toJson() {
    return jsonEncode({
      '_type': type,
      'tst': tst,
      'lat': lat,
      'lon': lon,
      // here we use collection-if to account for null values
      if (bssid != null) 'BSSID': bssid,
      if (ssid != null) 'SSID': ssid,
      if (acc != null) 'acc': acc,
      if (alt != null) 'alt': alt,
      if (batt != null) 'batt': batt,
      if (bs != null) 'bs': bs,
      if (conn != null) 'conn': conn,
      if (createdAt != null) 'created_at': createdAt,
      if (m != null) 'm': m,
      if (t != null) 't': t,
    });
  }

  static String willJson() {
    return jsonEncode({
      '_type': 'lwt',
      'tst': (DateTime.now().millisecondsSinceEpoch / 1000).round()
    });
  }
}
