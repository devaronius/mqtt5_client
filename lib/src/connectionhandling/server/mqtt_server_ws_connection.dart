/*
 * Package : mqtt5_client
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 10/05/2020
 * Copyright :  S.Hamblett
 */

part of mqtt5_server_client;

/// The MQTT server connection class for the websocket interface
class MqttServerWsConnection extends MqttServerConnection {
  /// Default constructor
  MqttServerWsConnection(events.EventBus eventBus) : super(eventBus);

  /// Initializes a new instance of the MqttConnection class.
  MqttServerWsConnection.fromConnect(
      String server, int port, events.EventBus eventBus)
      : super(eventBus) {
    connect(server, port);
  }

  /// The websocket subprotocol list
  List<String> protocols = MqttClientConstants.protocolsMultipleDefault;

  /// Connect
  @override
  Future<MqttClientConnectionStatus> connect(String server, int port) {
    final completer = Completer<MqttClientConnectionStatus>();
    // Add the port if present
    Uri uri;
    try {
      uri = Uri.parse(server);
    } on Exception {
      final message = 'MqttWsConnection::The URI supplied for the WS '
          'connection is not valid - $server';
      throw MqttNoConnectionException(message);
    }
    if (uri.scheme != 'ws' && uri.scheme != 'wss') {
      final message = 'MqttWsConnection::The URI supplied for the WS has '
          'an incorrect scheme - $server';
      throw MqttNoConnectionException(message);
    }
    if (port != null) {
      uri = uri.replace(port: port);
    }
    final uriString = uri.toString();
    MqttLogger.log(
        'MqttWsConnection:: WS URL is $uriString, protocols are $protocols');
    try {
      // Connect and save the socket.
      WebSocket.connect(uriString,
              protocols: protocols.isNotEmpty ? protocols : null)
          .then((dynamic socket) {
        client = socket;
        readWrapper = MqttReadWrapper();
        messageStream = MqttByteBuffer(typed.Uint8Buffer());
        _startListening();
        completer.complete();
      }).catchError((dynamic e) {
        onError(e);
        completer.completeError(e);
      });
    } on Exception {
      final message = 'MqttWsConnection::The connection to the message broker '
          '{$uriString} could not be made.';
      throw MqttNoConnectionException(message);
    }
    return completer.future;
  }

  /// OnDone listener callback
  @override
  void onDone() {
    _disconnect();
    if (onDisconnected != null) {
      MqttLogger.log(
          'MqttWsConnection::_onDone - calling disconnected callback');
      onDisconnected();
    }
  }

  void _disconnect() {
    if (client != null) {
      client.close();
      client = null;
    }
  }
}