import 'package:flutter/material.dart';
import 'package:mainapp/register.dart';
import 'package:mainapp/test.dart';
import 'package:mainapp/app_use.dart';
import 'package:mainapp/debug_sensors.dart';

void main() => runApp(new MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      title: 'Flutter Demo',
      theme: new ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: new MyHomePage(title: 'Main App'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);
  final String title;

  @override
  _MyHomePageState createState() => new _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  DateTime mainDate;
  void initState() {
    super.initState();
    print("inside initState of Main Page");
    mainDate = DateTime.now();
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: new AppBar(
        title: new Text(widget.title),
      ),
      // floatingActionButton: FloatingActionButton(
      //   onPressed: () {
      //     Navigator.push(
      //         context, MaterialPageRoute(builder: (context) => Register()));
      //   },
      // ),
      body: Center(
        child: Column(
          children: [
            Container(
              margin: EdgeInsets.all(25),
              child: FlatButton(
                onPressed: () {
                  Navigator.push(context,
                      MaterialPageRoute(builder: (context) => Register()));
                },
                child: Text("Register"),
                textColor: Colors.white,
                color: Colors.blueAccent,
              ),
            ),
            Container(
              margin: EdgeInsets.all(25),
              child: FlatButton(
                onPressed: () {
                  Navigator.push(
                      context, MaterialPageRoute(builder: (context) => Test()));
                },
                child: Text("Test"),
                textColor: Colors.white,
                color: Colors.blueAccent,
              ),
            ),
            Container(
              margin: EdgeInsets.all(25),
              child: FlatButton(
                onPressed: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => AppUse(mainDate: mainDate)));
                },
                child: Text("APPUSAGE"),
                textColor: Colors.white,
                color: Colors.blueAccent,
              ),
            ),
            Container(
              margin: EdgeInsets.all(25),
              child: FlatButton(
                onPressed: () {
                  Navigator.push(context,
                      MaterialPageRoute(builder: (context) => DebugSensor()));
                },
                child: Text("SENSOR DEBUG"),
                textColor: Colors.white,
                color: Colors.blueAccent,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
