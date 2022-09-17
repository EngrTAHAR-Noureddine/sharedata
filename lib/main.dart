
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sharedata/Login.dart';
import 'package:sharedata/MyProvider.dart';

void main() async{

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
