import 'dart:async';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:record_example/audio_player.dart';

class AudioStream extends StatefulWidget {
  @override
  _AudioStreamState createState() => _AudioStreamState();
}

class _AudioStreamState extends State<AudioStream> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text("Audio Record"),
        ),
        body: Center(
          child: FutureBuilder(
              future: getPath(),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  if (showPlayer) {
                    return Padding(
                      padding: EdgeInsets.symmetric(horizontal: 25),
                      child: AudioPlayer(
                        path: snapshot.data,
                        onDelete: () {
                          setState(() => showPlayer = false);
                        },
                      ),
                    );
                  } else {
                    return AudioRecorder();
                  }
                }
              }),
        ));
  }
}
