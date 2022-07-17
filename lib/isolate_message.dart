class IsolateMessage {
  String _type = 'unknown';
  dynamic _data;

  String get type => _type;
  dynamic get data => _data;

  IsolateMessage(String type, [dynamic data]) {
    _type = type;
    _data = data;
  }
}
