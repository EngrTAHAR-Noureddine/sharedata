// ignore_for_file: avoid_print, unnecessary_brace_in_string_interps, constant_identifier_names, non_constant_identifier_names

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:ping_discover_network_forked/ping_discover_network_forked.dart';
import 'package:udp/udp.dart';

class Client{
  String name;
  String? addressIP;
  Client({required this.name, this.addressIP});
}

class Message {
  String id;
  String? message;

  Message({required this.id, this.message});

  Message.fromJson(Map<String, dynamic> json)
      : id = json['id'],
        message = json['message'];

  Map<String, dynamic> toJson() => {
    'id': id,
    'message': message,
  };

}

enum ResponseType {LOADING, ERROR, DONE, INIT}
const CONNECT_MESSAGE_CLIENT = "Connexion to server";
const RESPONSE_MESSAGE_SERVER = "Connexion successful";
const RESPONSE_OK = "Response OK; code: 200";
const RESPONSE_FAILURE = "Response Failure; code: 404";

class MyProvider with ChangeNotifier {
  static final MyProvider _singleton = MyProvider._internal();

  factory MyProvider() {
    return _singleton;
  }

  MyProvider._internal();

  final textSenderController = TextEditingController();
  bool? asServer = false;
  UDP? localServer;
  int numberPort = 65001;
  List<Client> remoteClients = [];
  String? remoteServerIP;
  List<Message> listWords = [];
  ResponseType status = ResponseType.INIT;
  String localAddress = "localhost";
  String id="";

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

  getAddressIP()async{
    localAddress = (await NetworkInfo().getWifiIP())!;
  }

  // getInfoNetwork()async{
  //   try {
  //     address = (await NetworkInfo().getWifiIP())!;
  //     List<String> splitter = address.split('.');
  //     for (var element in splitter) {
  //       hexAddress = "$hexAddress${int.parse(element).toRadixString(16)}-";
  //     }
  //     hexAddress = hexAddress.substring(0,hexAddress.length-1);
  //     print(" address is : ${address}");
  //   }catch(e){
  //     hexAddress = "Connection problems";
  //   }
  //   // 192.168.1.43
  //   // final info = NetworkInfo();
  //   // var wifiName = await info.getWifiName(); // FooNetwork
  //   // print("wifiname : ${wifiName}");
  //   // var wifiBSSID = await info.getWifiBSSID(); // 11:22:33:44:55:66
  //   // print("wifiBSSID : ${wifiBSSID}");
  //   // var wifiIPv6 = await info.getWifiIPv6(); // 2001:0db8:85a3:0000:0000:8a2e:0370:7334
  //   // print("wifiIPv6 : ${wifiIPv6}");
  //   // var wifiSubmask = await info.getWifiSubmask(); // 255.255.255.0
  //   // print("wifiSubmask : ${wifiSubmask}");
  //   // var wifiBroadcast = await info.getWifiBroadcast(); // 192.168.1.255
  //   // print("wifiBroadcast : ${wifiBroadcast}");
  //   // broadcast = wifiBroadcast!;
  //   // var wifiGateway = await info.getWifiGatewayIP();
  //   // print("wifiGateway : ${wifiGateway}");
  // }

  addClient({required String name}){
    remoteClients.add(Client(name: name));
  }

  _connexionClients({required Message message ,required String addressIP}){
    for (var client in remoteClients) {
      if(message.id == client.name){
        message.message = RESPONSE_MESSAGE_SERVER;
        message.id = "Server:$localAddress";
        client.addressIP = addressIP;
      }
    }
    if(message.message != RESPONSE_MESSAGE_SERVER) message.message = RESPONSE_FAILURE;
  }

  _getFromClient(Message message){
    for (var client in remoteClients) {
      if(message.id == client.name){
        message.message;
        listWords.add(message);
        message.id = "Server:$localAddress";
        message.message = RESPONSE_OK;
      }
    }
  }

  acknowledgement()async{

    localServer = await UDP.bind(Endpoint.any(port: Port(numberPort)));

    //localAddress = localServer?.socket?.address.address ?? "localhost";


    //Listen to the client anytime
    localServer?.asStream().listen((datagram) {

      String data = String.fromCharCodes(datagram!.data);
      print("client has spoken : $data ");

      Message message = Message.fromJson(jsonDecode(data));

      switch(message.message){
        case CONNECT_MESSAGE_CLIENT :
                    _connexionClients(message: message , addressIP: datagram.address.address);
                  break;
        default :
          _getFromClient(message);
          break;
      }


      localServer?.send(jsonEncode(message.toJson()).codeUnits, Endpoint.unicast(datagram.address , port: Port(numberPort)));
      notifyListeners();

    });

  }



  sendData(){

    if(textSenderController.text.isNotEmpty){
      Message message = Message(id: "");
      message.message = textSenderController.text;
      message.id = (asServer == true)? "Server:$localAddress" : id;

      print("Send Data from ($localAddress}): ${jsonEncode(message.toJson())}");

      _sendTo(
          message: jsonEncode(message.toJson()),
          address: (asServer == true)? remoteClients[0].addressIP! : remoteServerIP!
            );
      textSenderController.clear();
      notifyListeners();
      }

  }


  // send DATA
  _sendTo({required String message, required String address}){

      localServer?.send(
          message.codeUnits,
          Endpoint.unicast(InternetAddress(address) , port: Port(numberPort)));
  }




  lookingForServer({required String name})async{
    id = name;
    Message requestServer = Message(id: name, message: CONNECT_MESSAGE_CLIENT );

    var sender = await UDP.bind(Endpoint.any(port: Port(numberPort)));
    await sender.send(jsonEncode(requestServer.toJson()).codeUnits, Endpoint.broadcast(port: Port(numberPort)));

    sender.asStream(timeout: const Duration(minutes: 1)).listen((datagram) {
      var statusStr = String.fromCharCodes(datagram!.data);
      print("looking for server has spoken : $statusStr ");
      Message message = Message.fromJson(jsonDecode(statusStr));

      if(message.message == RESPONSE_MESSAGE_SERVER){
        remoteServerIP = datagram.address.address;
        status = ResponseType.DONE;
        notifyListeners();
      }else{
        status = ResponseType.ERROR;
        notifyListeners();
      }
    })
    .onDone(() {
      if(remoteServerIP !=null){
        status = ResponseType.DONE;
      }else{
        status = ResponseType.ERROR;
      }

      sender.close();
      notifyListeners();
    });

    //sender.close();
  }

  connectToRemoteServer()async{
    print("send to server of adress : ${InternetAddress(remoteServerIP!).address}");

    localServer = await UDP.bind(Endpoint.any(port: Port(numberPort)));
    //localAddress = localServer?.socket?.address.address ?? "localhost";

    //Listen to the server anytime
    localServer?.asStream().listen((datagram) {
      String data = String.fromCharCodes(datagram!.data);
      print("Server hase Spoken : $data ");
      Message message = Message.fromJson(jsonDecode(data));
      if(message.message != RESPONSE_OK && message.id == "Server:$remoteServerIP"){
        listWords.add(message);
      }
      notifyListeners();
    });
  }


  changeToLoading(){
    status = ResponseType.LOADING;
    notifyListeners();
  }






  // // Server with Dart Socket
  // Future<void> createServer() async {
  //   await  getInfoNetwork();
  //   server = await ServerSocket.bind(address, 4567);
  //   if (server != null) {
  //     print("server created ; IP : ${server!.address}:${server!.port} ");
  //     listenToClient();
  //   }
  // }
  //
  // void listenToClient() {
  //   server?.listen((newClient) {
  //     remoteClient = newClient;
  //     handleConnection();
  //   });
  // }
  //
  // void handleConnection() {
  //   print(
  //       'Connection from ${remoteClient?.remoteAddress.address}:${remoteClient?.remotePort}');
  //
  //   // listen for events from the client
  //   remoteClient?.listen(
  //     // handle data from the client
  //     (Uint8List data) async {
  //       listWords.add(Message(
  //           from:
  //               "${remoteClient?.remoteAddress.address}:${remoteClient?.remotePort}",
  //           message: String.fromCharCodes(data)));
  //       notifyListeners();
  //     },
  //
  //     // handle errors
  //     onError: (error) {
  //       print(error);
  //       remoteClient?.close();
  //     },
  //
  //     // handle the client closing the connection
  //     onDone: () {
  //       print('Client left');
  //       remoteClient?.close();
  //     },
  //   );
  // }
  //
  //
  // //Connect to the server
  // Future<void> createRemoteServer() async {
  //   await getInfoNetwork();
  //
  //   List<String> list = remoteServerIPHex.split('-');
  //
  //   remoteServerIPHex = "${int.parse(list[0],radix: 16)}.";
  //   remoteServerIPHex = "$remoteServerIPHex${int.parse(list[1],radix: 16)}.";
  //   remoteServerIPHex = "$remoteServerIPHex${int.parse(list[2],radix: 16)}.";
  //   remoteServerIPHex = "$remoteServerIPHex${int.parse(list[3],radix: 16)}";
  //
  //   print("Remote server is : ${remoteServerIPHex.split('')}");
  //
  //   remoteServer = await Socket.connect(remoteServerIPHex, 4567);
  //   print(
  //       'Connected to: ${remoteServer?.remoteAddress.address}:${remoteServer?.remotePort}');
  //   listenToRemoteServer();
  // }
  // void listenToRemoteServer() {
  //   remoteServer?.listen(
  //     // handle data from the server
  //    (Uint8List data) {
  //       final serverResponse = String.fromCharCodes(data);
  //       print('Server: $serverResponse');
  //       listWords.add(Message(
  //           from:
  //           "Server :${remoteServer?.remoteAddress.address}:${remoteServer?.remotePort}",
  //           message: serverResponse));
  //       notifyListeners();
  //     },
  //
  //     // handle errors
  //     onError: (error) {
  //       print(error);
  //       remoteServer?.destroy();
  //     },
  //
  //     // handle server ending connection
  //     onDone: () {
  //       print('Server left.');
  //       remoteServer?.destroy();
  //     },
  //   );
  // }
  //
  // void sendData()async{
  //   print("Send Data : ${textSenderController.text}");
  //
  //   //send from server to client
  //   remoteClient?.write("send :  ${textSenderController.text}");
  //   //send from client to server
  //   remoteServer?.write("send :  ${textSenderController.text}");
  //
  //   textSenderController.clear();
  //   notifyListeners();
  // }
  //
  // void editingTextField(String val){
  //
  //   //print("edit : ${iPAddressController.text}");
  //   if(val.isNotEmpty && val.length == 11){
  //     isGettingAddressIP = true;
  //     print("Val : $val");
  //     remoteServerIPHex = val;
  //   }else{
  //     isGettingAddressIP = false;
  //   }
  //
  //
  //   notifyListeners();
  // }


}
