// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sharedata/Home.dart';
import 'package:sharedata/MyProvider.dart';

class Login extends StatelessWidget {
  const Login({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        height: double.infinity,
        width: double.infinity,
        child: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Expanded(
                child: Container(
                  child: MaterialButton(
                      child: const Text("AS Doctor (Will Be a Server)"),
                      onPressed: ()async{
                        MyProvider().asServer = true;
                        await MyProvider().createServer();
                        Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) => Home()));
                      }),
                ),
              ),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    TextField(
                      controller: MyProvider().iPAddressController,

                      decoration: const InputDecoration(
                          labelText: "Server IP Address",

                      ),
                      onChanged: (val)=>MyProvider().editingTextField(val),
                    ),
                    Container(
                      color: (!context.watch<MyProvider>().isGettingAddressIP) ? Colors.grey: Colors.blue ,
                      padding: const EdgeInsets.all(10),
                      child: MaterialButton(
                          onPressed:(!context.watch<MyProvider>().isGettingAddressIP) ? null : ()async{
                            MyProvider().asServer = false;
                            await MyProvider().createRemoteServer();
                            Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) => Home()));
                          },
                          child: const Text("As Assistant (will be a client)")),
                    ),


                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
