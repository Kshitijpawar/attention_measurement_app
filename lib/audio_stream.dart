import 'dart:async';

import 'package:flutter/material.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:flutter/services.dart';

class AudioStream extends StatefulWidget {
  @override
  _AudioStreamState createState() => _AudioStreamState();
}

class _AudioStreamState extends State<AudioStream> {
  double _theWidgetVolume = -1;
  bool isRecording = false;
  bool result = false;
  static const platform =
      const MethodChannel('samples.flutter.dev/recordingaudio');

  Timer _audioTimer;

  _AudioStreamState() {
    _audioTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _getEnvVolume();
    });
  }

  //start recording in init state
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      print("inside init state");
      _startCustomRecording();
      isRecording = true;
    });
  }

  @override
  void dispose() {
    _audioTimer.cancel();
    _stopCustomRecording();

    super.dispose();
  }

  // Future<void> _printVolume() async {
  //   await Record.getVolume();
  // }

  // start kshitij recording
  Future<void> _startCustomRecording() async {
    try {
      await platform.invokeMethod('startREC');
    } on PlatformException catch (e) {
      print(e.message);
    }
  }

  // stop kshitij recording
  Future<void> _stopCustomRecording() async {
    if (isRecording) {
      try {
        isRecording = false;
        await platform.invokeMethod('stopREC');
      } on PlatformException catch (e) {
        print(e.message);
      }
    }
  }

  // get volume kshitij
  Future<void> _getEnvVolume() async {
    try {
      final double theVolume = await platform.invokeMethod('getVolume');
      print(theVolume.toString() + " got this from channel");
      setState(() {
        _theWidgetVolume = theVolume;
      });
    } on PlatformException catch (e) {
      print(e.message + " bruh");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("audio input"),
      ),
      body: Column(
        children: [
          // Container(
          //   margin: EdgeInsets.all(15),
          //   child: FlatButton(
          //     onPressed: _startRecording,
          //     child: Text("Audio input start recording"),
          //     textColor: Colors.white,
          //     color: Colors.blueAccent,
          //   ),
          // ),
          // Container(
          //   margin: EdgeInsets.all(15),
          //   child: FlatButton(
          //     onPressed: _stopRecording,
          //     child: Text("Audio input stop recording"),
          //     textColor: Colors.white,
          //     color: Colors.blueAccent,
          //   ),
          // ),
          // Container(
          //   margin: EdgeInsets.all(15),
          //   child: FlatButton(
          //     onPressed: _startCustomRecording,
          //     child: Text("Kshitij start rec"),
          //     textColor: Colors.white,
          //     color: Colors.blueAccent,
          //   ),
          // ),
          // Container(
          //   margin: EdgeInsets.all(15),
          //   child: FlatButton(
          //     onPressed: _stopCustomRecording,
          //     child: Text("Kshitij stop rec"),
          //     textColor: Colors.white,
          //     color: Colors.blueAccent,
          //   ),
          // ),
          // Container(
          //   margin: EdgeInsets.all(15),
          //   child: FlatButton(
          //     onPressed: _getEnvVolume,
          //     child: Text("Kshitij get volume"),
          //     textColor: Colors.white,
          //     color: Colors.blueAccent,
          //   ),
          // ),
          Container(
              margin: EdgeInsets.all(15),
              child: Text("current volume $_theWidgetVolume")),
          // Container(
          //   margin: EdgeInsets.all(15),
          //   child: FlatButton(
          //     onPressed: _printVolume,
          //     child: Text("Get Volume"),
          //     textColor: Colors.white,
          //     color: Colors.blueAccent,
          //   ),
          // ),
        ],
      ),
    );
  }
}
