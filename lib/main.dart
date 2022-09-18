
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sharedata/Login.dart';
import 'package:sharedata/MyProvider.dart';
import 'package:udp/udp.dart';

void main() async{

  var sender = await UDP.bind(Endpoint.any(port: const Port(65000)));
  var dataLength = await sender.send("HI BRO".codeUnits, Endpoint.broadcast(port: const Port(65001)));

  stdout.write("$dataLength bytes sent.");

  // creates a new UDP instance and binds it to the local address and the port
  // 65002.
  var receiver = await UDP.bind(Endpoint.loopback(port: const Port(65002)));

  // receiving\listening
  receiver.asStream(timeout: const Duration(seconds: 20)).listen((datagram) {
    var str = String.fromCharCodes(datagram!.data);
    stdout.write(str);
  });


  runApp(
      MultiProvider(
        providers: [
          // this for root Changes
          ChangeNotifierProvider(create: (_) => MyProvider())
        ],
        child: const MyApp(),
      )
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      themeMode: ThemeMode.dark,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const Login(),
    );
  }
}
