// import 'package:flutter/material.dart';
// import 'dart:async';
// import 'package:usage_stats/usage_stats.dart';

// class FinalAppUse extends StatefulWidget {
//   final DateTime mainDate;
//   FinalAppUse({Key key, @required this.mainDate}) : super(key: key);
//   @override
//   _FinalAppUseState createState() => _FinalAppUseState(mainDate);
// }

// class _FinalAppUseState extends State<FinalAppUse> {
//   List<EventUsageInfo> events = [];
//   DateTime mainDate;
//   _FinalAppUseState(this.mainDate);
//   @override
//   void initState() {
//     super.initState();
//     initUsage();
//   }

//   Future<void> initUsage() async {
//     UsageStats.grantUsagePermission();
//     DateTime endDate = new DateTime.now();
//     DateTime startDate = mainDate;
//     List<EventUsageInfo> queryEvents =
//         await UsageStats.queryEvents(startDate, endDate);
//     this.setState(() {
//       events = queryEvents.reversed.toList();
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text("App Usage"),
//       ),
//       body: Container(
//         child: ListView.separated(
//             itemBuilder: (context, index) {
//               return ListTile(
//                 title: Text(events[index].packageName),
//                 subtitle: Text(
//                     "last time used: ${DateTime.fromMillisecondsSinceEpoch(int.parse(events[index].timeStamp)).toIso8601String()}"),
//                 trailing: Text(events[index].eventType),
//               );
//             },
//             separatorBuilder: (context, index) => Divider(),
//             itemCount: events.length),
//       ),
//       floatingActionButton: FloatingActionButton(
//         onPressed: () => initUsage(),
//         child: Icon(Icons.refresh),
//         mini: true,
//       ),
//     );
//   }
// }
