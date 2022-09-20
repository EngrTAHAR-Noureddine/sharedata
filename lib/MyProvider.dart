// ignore_for_file: avoid_print, unnecessary_brace_in_string_interps, constant_identifier_names, non_constant_identifier_names

import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:network_info_plus/network_info_plus.dart';
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

  // text of message
  final textSenderController = TextEditingController();
  bool? asServer = false;
  UDP? server;
  UDP? client;
  int numberPort = 65001;
  // save the client of server in server app
  List<Client> remoteClients = [];
  // save ip address of remote server in client app
  String? remoteServerIP;
  // of messages
  List<Message> listWords = [];

  // status of connect to the server in client app
  ResponseType connexionStatus = ResponseType.INIT;
  String localAddress = "localhost";

  // in this example is name of client in server side.
  String idClient="";


  // get local address
  getAddressIP()async{
    localAddress = (await NetworkInfo().getWifiIP())!;
  }

  // adding client name
  addClient({required String name}){
    remoteClients.add(Client(name: name));
  }

  // begin connection
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

  //get data from client
  _getFromClient(Message message){
    for (var client in remoteClients) {
      if(message.id == client.name){
        message.message;
        listWords.add(Message(id: message.id , message: message.message));
        message.id = "Server:$localAddress";
        message.message = RESPONSE_OK;
      }
    }
  }


  // server side.
  listenToClients()async{

    server = await UDP.bind(Endpoint.any(port: Port(numberPort)));

    //Listen to the client anytime
    server?.asStream().listen((datagram) {

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


      server?.send(jsonEncode(message.toJson()).codeUnits, Endpoint.unicast(datagram.address , port: Port(numberPort)));
      notifyListeners();

    });

  }



  sendData(){

    if(textSenderController.text.isNotEmpty){
      Message message = Message(id: "");
      message.message = textSenderController.text;
      message.id = (asServer == true)? "Server:$localAddress" : idClient;

      print("Send Data from ($localAddress}): ${jsonEncode(message.toJson())}");

      _sendTo(
          aMessage: jsonEncode(message.toJson()),
          address: (asServer == true)? remoteClients[0].addressIP! : remoteServerIP!
            );
      textSenderController.clear();
      notifyListeners();
      }

  }


  // send DATA
  _sendTo({required String address , required String aMessage }){
    (asServer == true)?
      server?.send(
          aMessage.codeUnits,
          Endpoint.unicast(InternetAddress(address) , port: Port(numberPort)))

      :client?.send(
          aMessage.codeUnits,
          Endpoint.unicast(InternetAddress(address) , port: Port(numberPort)));
  }



  //client side.
  lookingForServer({required String name})async{
    idClient = name;
    Message requestServer = Message(id: name, message: CONNECT_MESSAGE_CLIENT );

    // client side.
    client = await UDP.bind(Endpoint.any(port: Port(numberPort)));
    await client?.send(jsonEncode(requestServer.toJson()).codeUnits, Endpoint.broadcast(port: Port(numberPort)));
   // listen to the server
    await connectToRemoteServer();
  }

  connectToRemoteServer()async{

    //Listen to the server anytime
    client?.asStream().listen((datagram) {

      String data = String.fromCharCodes(datagram!.data);
      print("Server hase Spoken : $data ");
      Message message = Message.fromJson(jsonDecode(data));

      switch(message.message){

        case RESPONSE_MESSAGE_SERVER:
          remoteServerIP = datagram.address.address;
          connexionStatus = ResponseType.DONE;
          break;

        case RESPONSE_OK :
          print("the message is OK");
          break;

        default :
          if(remoteServerIP!=null){
            if(message.id == "Server:$remoteServerIP") listWords.add(message);
            connexionStatus = ResponseType.DONE;
          }
          else {
            connexionStatus = ResponseType.ERROR;
          }
          break;

      }

      notifyListeners();

    });
  }


  changeToLoading(){
    connexionStatus = ResponseType.LOADING;
    notifyListeners();
  }


  closeServer(){
     server?.close();
  }
  closeClient(){
    client?.close();
  }


}
