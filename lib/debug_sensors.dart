// import 'dart:async';

// import 'package:environment_sensors/environment_sensors.dart';
// import 'package:flutter/material.dart';
// import 'package:f_logs/f_logs.dart';
// import 'package:sensors/sensors.dart';
// // import 'package:flutter_sensors/flutter_sensors.dart';

// class DebugSensor extends StatefulWidget {
//   @override
//   _DebugSensorState createState() => _DebugSensorState();
// }

// init() {
//   LogsConfig config = FLog.getDefaultConfigurations()
//     ..isDevelopmentDebuggingEnabled = true
//     ..timestampFormat = TimestampFormat.TIME_FORMAT_FULL_3
//     ..formatType = FormatType.FORMAT_CUSTOM
//     ..fieldOrderFormatCustom = [
//       FieldName.TIMESTAMP,
//       FieldName.LOG_LEVEL,
//       FieldName.CLASSNAME,
//       FieldName.METHOD_NAME,
//       FieldName.TEXT,
//       FieldName.EXCEPTION,
//       FieldName.STACKTRACE
//     ]
//     ..customOpeningDivider = "|"
//     ..customClosingDivider = "|";

//   FLog.applyConfigurations(config);
// }

// class _DebugSensorState extends State<DebugSensor> {
//   bool _isLightAvailable = false;
//   String _lightVal;
//   final envSensors = EnvironmentSensors();
//   List<double> _accelerometerValues;
//   List<double> _userAccelerometerValues;
//   List<double> _gyroscopeValues;
//   List<StreamSubscription<dynamic>> _streamSubscriptions =
//       <StreamSubscription<dynamic>>[];

//   // void _checkLightStatus() async {
//   //   await SensorManager().isSensorAvailable(TYPE_LIGHT).then((result) async {
//   //     print("inside check light");
//   //     print(result);
//   //     lightStream = await SensorManager().sensorUpdates(sensorId: TYPE_LIGHT);
//   //     setState(() {
//   //       _isLightAvailable = result;
//   //     });
//   //   });
//   // }

//   @override
//   void dispose() {
//     super.dispose();
//     FLog.clearLogs();
//     for (StreamSubscription<dynamic> subscription in _streamSubscriptions) {
//       subscription.cancel();
//     }
//   }

//   @override
//   void initState() {
//     super.initState();
//     initPlatformState();
//     init();
//     FLog.clearLogs();

//     _streamSubscriptions.add(envSensors.light.listen((double lightv) {
//       setState(() {
//         _lightVal = lightv.toString();
//       });
//     }));

//     _streamSubscriptions
//         .add(accelerometerEvents.listen((AccelerometerEvent event) {
//       setState(() {
//         _accelerometerValues = <double>[event.x, event.y, event.z];
//       });
//     }));
//     _streamSubscriptions.add(gyroscopeEvents.listen((GyroscopeEvent event) {
//       setState(() {
//         _gyroscopeValues = <double>[event.x, event.y, event.z];
//       });
//     }));
//     _streamSubscriptions
//         .add(userAccelerometerEvents.listen((UserAccelerometerEvent event) {
//       setState(() {
//         _userAccelerometerValues = <double>[event.x, event.y, event.z];
//       });
//     }));
//   }

//   Future<void> initPlatformState() async {
//     bool lightAvailable;

//     lightAvailable =
//         await envSensors.getSensorAvailable(SensorType.Light);

//     setState(() {
//       _isLightAvailable = lightAvailable;
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     final List<String> accelerometer =
//         _accelerometerValues?.map((double v) => v.toStringAsFixed(1))?.toList();
//     final List<String> gyroscope =
//         _gyroscopeValues?.map((double v) => v.toStringAsFixed(1))?.toList();
//     final List<String> userAccelerometer = _userAccelerometerValues
//         ?.map((double v) => v.toStringAsFixed(1))
//         ?.toList();

//     // final List<String> lightThe =
//     // _lightValues?.map((double v) => v.toStringAsFixed(2))?.toList();
//     // FLog.logThis(
//     //   className: "DebugSensor",
//     //   methodName: "accelerometer",
//     //   text: accelerometer.toString(),
//     //   type: LogLevel.INFO,
//     //   dataLogType: DataLogType.DEVICE.toString(),
//     // );
//     // FLog.logThis(
//     //   className: "DebugSensor",
//     //   methodName: "gyroscope",
//     //   text: gyroscope.toString(),
//     //   type: LogLevel.INFO,
//     //   dataLogType: DataLogType.DEVICE.toString(),
//     // );
//     // FLog.logThis(
//     //   className: "DebugSensor",
//     //   methodName: "user_accelerometer",
//     //   text: userAccelerometer.toString(),
//     //   type: LogLevel.INFO,
//     //   dataLogType: DataLogType.DEVICE.toString(),
//     // );

//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Sensor Example'),
//       ),
//       body: Column(
//         mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//         children: <Widget>[
//           Padding(
//             child: Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: <Widget>[
//                 Text('Accelerometer: $accelerometer'),
//               ],
//             ),
//             padding: const EdgeInsets.all(16.0),
//           ),
//           Padding(
//             child: Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: <Widget>[
//                 Text('UserAccelerometer: $userAccelerometer'),
//               ],
//             ),
//             padding: const EdgeInsets.all(16.0),
//           ),
//           Padding(
//             child: Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: <Widget>[
//                 Text('Gyroscope: $gyroscope'),
//               ],
//             ),
//             padding: const EdgeInsets.all(16.0),
//           ),
//           Padding(
//             child: Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: <Widget>[
//                 Text('Light Values: $_lightVal'),
//               ],
//             ),
//             padding: const EdgeInsets.all(16.0),
//           ),
//         ],
//       ),
//       floatingActionButton: Column(
//         mainAxisAlignment: MainAxisAlignment.end,
//         children: [
//           FloatingActionButton(
//             onPressed: () {
//               FLog.logThis(
//                 className: "DebugSensor",
//                 methodName: "button_press",
//                 text: "ButtonPressed",
//                 type: LogLevel.INFO,
//                 dataLogType: DataLogType.DEVICE.toString(),
//               );
//             },
//             backgroundColor: Colors.blue,
//             child: Icon(Icons.radio_button_on),
//             heroTag: null,
//           ),
//           SizedBox(
//             height: 10,
//           ),
//           FloatingActionButton(
//             onPressed: () {
//               FLog.exportLogs();
//             },
//             backgroundColor: Colors.blue,
//             child: Icon(Icons.file_download),
//             heroTag: null,
//           )
//         ],
//       ),
//     );
//   }
// }
