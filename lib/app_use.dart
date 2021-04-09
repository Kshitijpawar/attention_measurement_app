import 'package:flutter/material.dart';
import 'package:app_usage/app_usage.dart';

class AppUse extends StatefulWidget {
  final DateTime mainDate;
  // final String text;
  // AppUse({Key key, this.text}) : super(key: key);
  // AppUse({this.text});
  AppUse({Key key, @required this.mainDate}) : super(key: key);

  @override
  _AppUseState createState() => _AppUseState(mainDate);
}

class _AppUseState extends State<AppUse> {
  List<AppUsageInfo> _infos = [];

  DateTime mainDate;
  _AppUseState(this.mainDate);

  @override
  void initState() {
    super.initState();
    // print(mainDate);
  }

  void getUsageStats() async {
    try {
      // print(mainDate);
      DateTime endDate = new DateTime.now();
      // DateTime startDate = endDate.subtract(Duration(hours: 1));
      List<AppUsageInfo> infoList =
          await AppUsage.getAppUsage(mainDate, endDate);
      setState(() {
        _infos = infoList;
      });
      print(mainDate);
      print(endDate);
      if (infoList.isEmpty) {
        print("list is empty");
      }
      for (var info in infoList) {
        print(info.toString());
      }
    } on AppUsageException catch (exception) {
      print(exception);
    }
  }

  @override
  Widget build(BuildContext context) {
    // print(mainDate);
    return Scaffold(
      appBar: AppBar(
        title: const Text('App Usage'),
        backgroundColor: Colors.green,
      ),
      body: ListView.builder(
          itemCount: _infos.length,
          itemBuilder: (context, index) {
            return ListTile(
                title: Text(_infos[index].appName),
                subtitle: Text(_infos[index].packageName),
                trailing: Text(_infos[index].usage.toString()));
          }),
      floatingActionButton: FloatingActionButton(
          onPressed: getUsageStats, child: Icon(Icons.file_download)),
    );
  }
}
