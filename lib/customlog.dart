import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'logclass.dart';

class CustomLog extends StatefulWidget {
  @override
  _CustomLogState createState() => _CustomLogState();
}

class _CustomLogState extends State<CustomLog> {
  StringBuffer sc = StringBuffer();

  // @override
  // void initState() {
  // super.initState();
  // initUsage();
  // StringBuffer sc = StringBuffer();
  // }

  Future<String> getFilePath() async {
    Directory appDocumentsDirectory = await getExternalStorageDirectory(); // 1
    String appDocumentsPath = appDocumentsDirectory.path; // 2
    String filePath = '$appDocumentsPath/demoTextFile.txt'; // 3
    print(filePath);
    return filePath;
  }

  void saveFile() async {
    print("inside cl widget");
    File file = File(await getFilePath()); // 1
    // file.writeAsString(
        // "This is my demo text that will be saved to : demoTextFile.txt"); // 2
    file.writeAsString(sc.toString());
  }

  void writeToBuffer() async {
    LogClass myObject =
        LogClass(DateTime.now(), 1,"Kshitij", "Attentive", "203940", "382392");
    sc.write(myObject.toString());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Custom Logging"),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text("Save to file"),
          FlatButton(
              onPressed: () => writeToBuffer(), child: Text("Write some data")),
          FlatButton(
            onPressed: () => saveFile(),
            child: Text("Savefile"),
          ),
        ],
      ),
    );
  }
}
