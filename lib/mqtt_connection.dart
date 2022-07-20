import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_wearos_owntracks/mqtt_credentials.dart';
import 'package:flutter_wearos_owntracks/owntracks_message.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

class MQTTConnection extends MqttServerClient {
  MQTTConnection()
      : super.withPort(MQTTCredentials.url, MQTTCredentials.clientid,
            MQTTCredentials.port);
  String _pubTopic = 'owntracks';

  void onPong() {
    debugPrint('MQTT pong');
  }

  Future<void> init() async {
    debugPrint('Init MQQT!');

    setProtocolV311();
    useWebSocket = MQTTCredentials.websocket;
    if (useWebSocket) {
      debugPrint('Using websocket!');
      websocketProtocols = MqttClientConstants.protocolsSingleDefault;
      //useAlternateWebSocketImplementation = true;
    } else {
      secure = MQTTCredentials.secure;
    }
    keepAlivePeriod = 60;
    disconnectOnNoResponsePeriod = 30;
    autoReconnect = true;

    //onDisconnected = onDisconnected;
    //onConnected = onConnected;
    //onSubscribed = onSubscribed;
    //onAutoReconnect = onAutoReconnect;
    //onAutoReconnected = onAutoReconnected;
    pongCallback = onPong;

    _pubTopic = 'owntracks/${MQTTCredentials.user}/${MQTTCredentials.clientid}';

    connectionMessage = MqttConnectMessage()
        .authenticateAs(MQTTCredentials.user, MQTTCredentials.password)
        .withWillMessage(OwnTracksMessage.willJson())
        .withWillTopic(_pubTopic);
  }

  @override
  Future<MqttClientConnectionStatus?> connect(
      [String? username, String? password]) async {
    debugPrint(
        'MQTT client connecting to ${MQTTCredentials.url}:${MQTTCredentials.port}....');

    try {
      await super.connect(); // Assume no credentials XD
    } on NoConnectionException catch (e) {
      // Raised by the client when connection fails.
      debugPrint('Client exception - $e');
      disconnect();
    } on SocketException catch (e) {
      // Raised by the socket layer
      debugPrint('Socket exception - $e');
      disconnect();
    }

    if (connectionStatus!.state == MqttConnectionState.connected) {
      debugPrint('MQTT client connected');
    } else {
      /// Use status here rather than state if you also want the broker return code.
      debugPrint(
          'MQTT client connection failed - disconnecting, status is $connectionStatus');
      disconnect();
    }
    return connectionStatus;
  }

  publishOwnTracksMessage(OwnTracksMessage ownTracksMessage) {
    debugPrint('Publishing MQTT message');
    final builder = MqttClientPayloadBuilder();
    builder.addString(ownTracksMessage.toJson());
    publishMessage(_pubTopic, MqttQos.exactlyOnce, builder.payload!);
  }
}
