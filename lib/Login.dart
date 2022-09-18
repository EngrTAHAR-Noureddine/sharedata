// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sharedata/Home.dart';
import 'package:sharedata/MyProvider.dart';

class Login extends StatelessWidget {
   Login({Key? key}) : super(key: key);

  final _nameAssistantController = TextEditingController();

   final _nameToConnectController = TextEditingController();

   final _formKey = GlobalKey<FormState>();
   final _formKeyToConnect = GlobalKey<FormState>();

   isValid(){
     if(_nameAssistantController.text.isEmpty ){
       return "Field is Empty";
     }
     return null;
   }
   isValidConnectToServer(){
     if(_nameToConnectController.text.isEmpty){
       return "Field is Empty";
     }
     return null;
   }


  List<Widget> _asServer(context){
    return [

      Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                validator: (value) => isValid() ,
                controller: _nameAssistantController,
                decoration: const InputDecoration(
                  labelText: "Name of Assistant"
                ),
              ),
              Container(
                color: Colors.orange,
                padding: const EdgeInsets.all(10),
                child: MaterialButton(
                  child: const Text('Submit'),
                  onPressed: (){
                    if (_formKey.currentState!.validate()) {

                      MyProvider().addClient(name: _nameAssistantController.text );

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Data Saved')),
                      );
                    }
                  },
                ),

              )
            ],
          )
      ),

      Container(
        color: Colors.blue,
        padding:const EdgeInsets.all(10),
        child: MaterialButton(
            child: const Text("AS Doctor (Will Be a Server)"),
            onPressed: ()async{
              MyProvider().asServer = true;
              await MyProvider().getAddressIP();

              MyProvider().acknowledgement();

              Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) => Home()));
            }),
      ),
    ];
  }

  Widget _fieldSubmit(BuildContext context){
     switch(context.watch<MyProvider>().status){
       case ResponseType.LOADING:
         return const CircularProgressIndicator();
       case ResponseType.ERROR:
         return const Center(child: Text("ERROR"),);
       case ResponseType.DONE:
         return const Center(child: Text("DONE"),);
       case ResponseType.INIT:
         return  Container(
           color: Colors.orange,
           padding: const EdgeInsets.all(10),
           child: MaterialButton(
             child: const Text('Submit'),
             onPressed: (){
               if (_formKeyToConnect.currentState!.validate()) {

                 MyProvider().lookingForServer(name: _nameToConnectController.text);
                 MyProvider().changeToLoading();

               }
             },
           ),
         );
     }

  }

   List<Widget> _asClient(BuildContext context){
     return [
       Form(
           key: _formKeyToConnect,
           child: Column(
             children: [
               TextFormField(
                 validator:(value) =>  isValidConnectToServer() ,
                 controller: _nameToConnectController,
                 decoration: const InputDecoration(
                     labelText: "Name of Assistant"
                 ),
               ),

               Center(child: _fieldSubmit(context))

             ],
           )
       ),
       Container(
         color: (context.watch<MyProvider>().status == ResponseType.DONE) ? Colors.blue: Colors.grey ,
         padding: const EdgeInsets.all(10),
         child: MaterialButton(
             onPressed:(context.watch<MyProvider>().status == ResponseType.DONE) ?  ()async{
               MyProvider().asServer = false;
               await MyProvider().getAddressIP();

               MyProvider().closeServer();

               MyProvider().lookingForServer(name: MyProvider().id);

               Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) => Home()));
             } : null,
             child: const Text("As Assistant (will be a client)")),
       ),


     ];
   }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SizedBox(
        height: double.infinity,
        width: double.infinity,
        child: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Expanded(
                child: Column(
                  children: _asServer(context),
                )
              ),
              Container(
                height: double.infinity,
                width: 20,
                color: Colors.red,
              ),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: _asClient(context)
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
