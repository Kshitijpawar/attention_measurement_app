import 'package:flutter/material.dart';
import 'dart:async';

class TestTimer extends StatefulWidget {
  @override
  _TestTimerState createState() => _TestTimerState();
}

class _TestTimerState extends State<TestTimer> {
  //Testing out timer stuff
  Timer _someTimer;
  // Timer.run()
  _TestTimerState() {
    _someTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      // setState(() {
      print("insider timer");
      print(DateTime.now());
      // });
    });
  }
  // }

  // //Testing out timer stuff
  Widget someWidget = Text('');
  @override
  void initState() {
    super.initState();
    _startTimerActive();
  }

  @override
  void dispose() {
    _timerActive.cancel();
    _someTimer.cancel();
    print("Timer cancel from dispose");
    super.dispose();
  }

  int _counterActive = 30;
  int _counterPassive = 10;
  Timer _timerActive, _timerPassive;

  void _startTimerPassive() {
    if (_timerPassive != null) {
      print("active timer cancelled");
      _timerPassive.cancel();
    }
    _timerPassive = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        if (_counterPassive > 0) {
          _counterPassive--;
        } else {
          _timerPassive.cancel();
        }
      });
    });
  }

  void _startTimerActive() {
    // _counter = 30;
    if (_timerActive != null) {
      print("active timer cancelled");
      _timerActive.cancel();
    }
    _timerActive = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        if (_counterActive > 0) {
          _counterActive--;
          // if (_counterActive % 3 == 0)
          //   someWidget = Text("bruh");
          // else
          //   someWidget = Text('');
        } else {
          _timerActive.cancel();
          _startTimerPassive();
          // _counterActive = 30;
          // _startTimer();
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Timer App"),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            // someWidget,
            (_counterActive % 3 != 0)
                ? Text("")
                : Text(
                    "DONE!",
                    style: TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                      fontSize: 48,
                    ),
                  ),
            Text(
              '$_counterActive',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 48,
              ),
            ),
            Text(
              '$_counterPassive',
              style: TextStyle(
                color: Colors.deepPurpleAccent,
                fontWeight: FontWeight.bold,
                fontSize: 48,
              ),
            ),
            // RaisedButton(
            //   onPressed: () => _startTimer(),
            //   child: Text("Start 10 second count down"),
            // ),
          ],
        ),
      ),
    );
  }
}
