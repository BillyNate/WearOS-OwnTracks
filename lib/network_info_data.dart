class NetworkInfoData {
  late String? wifiName;
  late String? wifiBSSID;
  late String? wifiIP;
  late String? wifiIPv6;
  late String? wifiSubmask;
  late String? wifiBroadcast;
  late String? wifiGateway;
  NetworkInfoData(
      {this.wifiName,
      this.wifiBSSID,
      this.wifiIP,
      this.wifiIPv6,
      this.wifiSubmask,
      this.wifiBroadcast,
      this.wifiGateway});
}
