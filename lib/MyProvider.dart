// ignore_for_file: avoid_print, unnecessary_brace_in_string_interps

import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:ping_discover_network_forked/ping_discover_network_forked.dart';

class Message {
  String from;
  String message;

  Message({required this.from, required this.message});
}

class MyProvider with ChangeNotifier {
  static final MyProvider _singleton = MyProvider._internal();

  factory MyProvider() {
    return _singleton;
  }

  MyProvider._internal();

  final textSenderController = TextEditingController();
  final iPAddressController = TextEditingController();
  String remoteServerIPHex = "";
  bool? asServer = false;
  bool isGettingAddressIP = false;
  ServerSocket? server;
  Socket? remoteClient;
  Socket? remoteServer;
  String address = "localhost";
  String hexAddress = '';
  //String broadcast= "";
  List<Message> listWords = [];

  // getAddress() async {
  //   for (var interface in await NetworkInterface.list()) {
  //     print('== Interface: ${interface.name} ==');
  //     for (var addr in interface.addresses) {
  //       print(
  //           '${addr.address} ${addr.host} ${addr.isLoopback} ${addr.rawAddress} ${addr.type.name}');
  //
  //       if (addr.type.name == "IPv4") address = addr.address;
  //     }
  //   }
  // }

  // getListOnNetwork(){
  //   const port = 4567;
  //   final stream = NetworkAnalyzer.discover2(
  //     '192.168.168.0', port,
  //     timeout: const Duration(milliseconds: 5000),
  //   );
  //
  //   int found = 0;
  //   stream.listen((NetworkAddress addr) {
  //     if (addr.exists) {
  //       found++;
  //       print('Found device: ${addr.ip}:$port');
  //     }
  //   }).onDone(() => print('Finish. Found $found device(s)'));
  // }

  getInfoNetwork()async{
    try {
      address = (await NetworkInfo().getWifiIP())!;
      List<String> splitter = address.split('.');
      for (var element in splitter) {
        hexAddress = "$hexAddress${int.parse(element).toRadixString(16)}-";
      }
      hexAddress = hexAddress.substring(0,hexAddress.length-1);
      print(" address is : ${address}");
    }catch(e){
      hexAddress = "Connection problems";
    }
    // 192.168.1.43
    // final info = NetworkInfo();
    // var wifiName = await info.getWifiName(); // FooNetwork
    // print("wifiname : ${wifiName}");
    // var wifiBSSID = await info.getWifiBSSID(); // 11:22:33:44:55:66
    // print("wifiBSSID : ${wifiBSSID}");
    // var wifiIPv6 = await info.getWifiIPv6(); // 2001:0db8:85a3:0000:0000:8a2e:0370:7334
    // print("wifiIPv6 : ${wifiIPv6}");
    // var wifiSubmask = await info.getWifiSubmask(); // 255.255.255.0
    // print("wifiSubmask : ${wifiSubmask}");
    // var wifiBroadcast = await info.getWifiBroadcast(); // 192.168.1.255
    // print("wifiBroadcast : ${wifiBroadcast}");
    // broadcast = wifiBroadcast!;
    // var wifiGateway = await info.getWifiGatewayIP();
    // print("wifiGateway : ${wifiGateway}");
  }

  // Server with Dart Socket
  Future<void> createServer() async {
    await  getInfoNetwork();
    server = await ServerSocket.bind(address, 4567);
    if (server != null) {
      print("server created ; IP : ${server!.address}:${server!.port} ");
      listenToClient();
    }
  }

  void listenToClient() {
    server?.listen((newClient) {
      remoteClient = newClient;
      handleConnection();
    });
  }

  void handleConnection() {
    print(
        'Connection from ${remoteClient?.remoteAddress.address}:${remoteClient?.remotePort}');

    // listen for events from the client
    remoteClient?.listen(
      // handle data from the client
      (Uint8List data) async {
        listWords.add(Message(
            from:
                "${remoteClient?.remoteAddress.address}:${remoteClient?.remotePort}",
            message: String.fromCharCodes(data)));
        notifyListeners();
      },

      // handle errors
      onError: (error) {
        print(error);
        remoteClient?.close();
      },

      // handle the client closing the connection
      onDone: () {
        print('Client left');
        remoteClient?.close();
      },
    );
  }


  //Connect to the server
  Future<void> createRemoteServer() async {
    await getInfoNetwork();

    List<String> list = remoteServerIPHex.split('-');

    remoteServerIPHex = "${int.parse(list[0],radix: 16)}.";
    remoteServerIPHex = "$remoteServerIPHex${int.parse(list[1],radix: 16)}.";
    remoteServerIPHex = "$remoteServerIPHex${int.parse(list[2],radix: 16)}.";
    remoteServerIPHex = "$remoteServerIPHex${int.parse(list[3],radix: 16)}";

    print("Remote server is : ${remoteServerIPHex.split('')}");

    remoteServer = await Socket.connect(remoteServerIPHex, 4567);
    print(
        'Connected to: ${remoteServer?.remoteAddress.address}:${remoteServer?.remotePort}');
    listenToRemoteServer();
  }
  void listenToRemoteServer() {
    remoteServer?.listen(
      // handle data from the server
     (Uint8List data) {
        final serverResponse = String.fromCharCodes(data);
        print('Server: $serverResponse');
        listWords.add(Message(
            from:
            "Server :${remoteServer?.remoteAddress.address}:${remoteServer?.remotePort}",
            message: serverResponse));
        notifyListeners();
      },

      // handle errors
      onError: (error) {
        print(error);
        remoteServer?.destroy();
      },

      // handle server ending connection
      onDone: () {
        print('Server left.');
        remoteServer?.destroy();
      },
    );
  }

  void sendData()async{
    print("Send Data : ${textSenderController.text}");

    //send from server to client
    remoteClient?.write("send :  ${textSenderController.text}");
    //send from client to server
    remoteServer?.write("send :  ${textSenderController.text}");

    textSenderController.clear();
    notifyListeners();
  }

  void editingTextField(String val){

    //print("edit : ${iPAddressController.text}");
    if(val.isNotEmpty && val.length == 8){
      isGettingAddressIP = true;
      print("Val : $val");
      remoteServerIPHex = val;
    }else{
      isGettingAddressIP = false;
    }


    notifyListeners();
  }


}
