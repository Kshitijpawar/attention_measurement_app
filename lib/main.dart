import 'package:flutter/material.dart';
// import 'package:mainapp/customlog.dart';
// import 'package:mainapp/finalappuse.dart';
// import 'package:mainapp/noise_detect.dart';
import 'package:mainapp/register.dart';
import 'package:mainapp/test.dart';
// import 'package:mainapp/app_use.dart';
// import 'package:mainapp/debug_sensors.dart';
// import 'package:mainapp/test1.dart';
// import 'package:mainapp/test2.dart';
// import 'package:mainapp/testtimer.dart';

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

class _MyHomePageState extends State<MyHomePage> with WidgetsBindingObserver {
  AppLifecycleState _notificationFromMain;
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    setState(() {
      _notificationFromMain = state;
      // print(_notificationFromMain.toString() + "reporting from main.dart");
    });
  }

  String testString = "No data";
  //logging device ID and Household ID;
  String DEVICE_ID = "N/A";
  String HOUSE_ID = "N/A";
  //logging device ID and Household ID;
  DateTime mainDate;
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    mainDate = DateTime.now();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // void _awaitResultFromTest1(BuildContext context) async {
    //   final result = await Navigator.push(
    //       context,
    //       MaterialPageRoute(
    //         builder: (context) => Test1(),
    //       ));

    //   // after the SecondScreen result comes back update the Text widget with it
    //   setState(() {
    //     testString = result;
    //   });
    // }

    void _awaitResultFromRegister(BuildContext context) async {
      final List<dynamic> infoFromReg = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => Register(),
          ));
      //after the Register page comes back update the results
      setState(() {
        DEVICE_ID = infoFromReg[0];
        HOUSE_ID = infoFromReg[1];
        print(
            "reporting from main.dart received deviceid : ${DEVICE_ID} and houseid: ${HOUSE_ID}");
      });
    }

    return new Scaffold(
      appBar: new AppBar(
        title: new Text(widget.title),
      ),
      body: Center(
        child: Column(
          children: [
            Container(
              margin: EdgeInsets.all(15),
              child: FlatButton(
                // onPressed: () {
                // Navigator.push(context,
                // MaterialPageRoute(builder: (context) => Register()));
                // },
                onPressed: () {
                  _awaitResultFromRegister(context);
                },
                child: Text("Register"),
                textColor: Colors.white,
                color: Colors.blueAccent,
              ),
            ),
            Container(
              margin: EdgeInsets.all(15),
              child: FlatButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => Test(
                        deviceID: DEVICE_ID,
                        houseID: HOUSE_ID,
                      ),
                    ),
                  );
                },
                child: Text("Test"),
                textColor: Colors.white,
                color: Colors.blueAccent,
              ),
            ),
            // Container(
            //   margin: EdgeInsets.all(15),
            //   child: FlatButton(
            //     onPressed: () {
            //       Navigator.push(
            //           context,
            //           MaterialPageRoute(
            //               builder: (context) => FinalAppUse(
            //                     mainDate: mainDate,
            //                   )));
            //     },
            //     child: Text("APPUSAGE"),
            //     textColor: Colors.white,
            //     color: Colors.blueAccent,
            //   ),
            // ),
            // Container(
            //   margin: EdgeInsets.all(25),
            //   child: FlatButton(
            //     onPressed: () {
            //       Navigator.push(
            //           context,
            //           MaterialPageRoute(
            //               builder: (context) => AppUse(mainDate: mainDate)));
            //     },
            //     child: Text("APPUSAGE"),
            //     textColor: Colors.white,
            //     color: Colors.blueAccent,
            //   ),
            // ),
            // Container(
            //   margin: EdgeInsets.all(15),
            //   child: FlatButton(
            //     onPressed: () {
            //       Navigator.push(context,
            //           MaterialPageRoute(builder: (context) => DebugSensor()));
            //     },
            //     child: Text("SENSOR DEBUG"),
            //     textColor: Colors.white,
            //     color: Colors.blueAccent,
            //   ),
            // ),
            // Container(
            //   margin: EdgeInsets.all(15),
            //   child: FlatButton(
            //     onPressed: () {
            //       _awaitResultFromTest1(context);
            //     },
            //     child: Text("Screen1"),
            //     textColor: Colors.white,
            //     color: Colors.blueAccent,
            //   ),
            // ),
            // Container(
            //   margin: EdgeInsets.all(15),
            //   child: FlatButton(
            //     onPressed: () {
            //       Navigator.push(
            //         context,
            //         MaterialPageRoute(
            //           builder: (context) => Test2(
            //             textFromMain: testString,
            //           ),
            //         ),
            //       );
            //     },
            //     child: Text("Screen2"),
            //     textColor: Colors.white,
            //     color: Colors.blueAccent,
            //   ),
            // ),
            // Container(
            //   margin: EdgeInsets.all(15),
            //   child: FlatButton(
            //     onPressed: () {
            //       Navigator.push(context,
            //           MaterialPageRoute(builder: (context) => TestTimer()));
            //     },
            //     child: Text("Timer Test"),
            //     textColor: Colors.white,
            //     color: Colors.blueAccent,
            //   ),
            // ),
          ],
        ),
      ),
    );
  }
}
