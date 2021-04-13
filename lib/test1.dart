import 'package:flutter/material.dart';

class Test1 extends StatefulWidget {
  @override
  _Test1State createState() => _Test1State();
}

class _Test1State extends State<Test1> {
  TextEditingController textFieldController = TextEditingController();

  void _sendDataBack(BuildContext context) {
    String textToSendBack = textFieldController.text;
    Navigator.pop(context, textToSendBack);
  }

  Future<bool> _pressBack() {
    String textToSendBack = textFieldController.text;
    Navigator.pop(context, textToSendBack); 
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _pressBack,
      child: Scaffold(
        appBar: AppBar(title: Text('Test1 screen')),
        body: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.all(32.0),
              child: TextField(
                controller: textFieldController,
                style: TextStyle(
                  fontSize: 24,
                  color: Colors.black,
                ),
              ),
            ),
            // RaisedButton(
            //   child: Text(
            //     'Send text back',
            //     style: TextStyle(fontSize: 24),
            //   ),
            //   onPressed: () {
            //     _sendDataBack(context);
            //   },
            // )
          ],
        ),
      ),
    );
  }
}
