import 'package:flutter/material.dart';
import 'dart:async';
import 'package:usage_stats/usage_stats.dart';

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
  List<EventUsageInfo> events;

  DateTime mainDate;
  _AppUseState(this.mainDate);

  @override
  void initState() {
    super.initState();
    initUsage();
  }

  Future<void> initUsage() async {
    UsageStats.grantUsagePermission();
    DateTime endDate = new DateTime.now();
    DateTime startDate = mainDate;

    // print(startDate.toString());
    // print(endDate.toString());
    List<EventUsageInfo> queryEvents =
        await UsageStats.queryEvents(startDate, endDate);

    this.setState(() {
      // print(events);
      events = queryEvents.reversed.toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('App Usage'),
          backgroundColor: Colors.green,
        ),
        body: Container(
          child: ListView.separated(
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(events[index].packageName),
                  subtitle: Text(
                      "Last time used: ${DateTime.fromMillisecondsSinceEpoch(int.parse(events[index].timeStamp)).toIso8601String()}"),
                  trailing: Text(events[index].eventType),
                );
              },
              separatorBuilder: (context, index) => Divider(),
              itemCount: events.length),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            initUsage();
          },
          child: Icon(Icons.refresh),
          mini: true,
        ));
  }
}
