import 'package:flutter/material.dart';

class Test2 extends StatefulWidget {
  final String textFromMain;
  Test2({Key key, @required this.textFromMain}) : super(key: key);
  @override
  _Test2State createState() => _Test2State(textFromMain);
}

class _Test2State extends State<Test2> {
  String textFromMain;
  _Test2State(this.textFromMain);
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Test2 screen')),
      body: Center(
        child: Text("$textFromMain"),
      ),
    );
  }
}
