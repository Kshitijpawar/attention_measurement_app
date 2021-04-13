import 'package:environment_sensors/environment_sensors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'dart:convert';
import 'dart:io';
import 'dart:async';

import 'package:mainapp/detector_painters.dart';
// import 'package:mainapp/mynoise.dart';
import 'package:mainapp/utils.dart';

import 'package:camera/camera.dart';
// import 'package:f_logs/f_logs.dart';
import 'package:quiver/collection.dart';
import 'package:firebase_ml_vision/firebase_ml_vision.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sensors/sensors.dart';
import 'package:tflite_flutter/tflite_flutter.dart' as tfl;
import 'package:image/image.dart' as imglib;

import 'logclass.dart';

class Test extends StatefulWidget {
  String deviceID, houseID;
  Test({Key key, this.deviceID, this.houseID}) : super(key: key);
  @override
  _TestState createState() => _TestState(deviceID, houseID);
}

class _TestState extends State<Test> with WidgetsBindingObserver {
  //deviceID and houseID receiver
  String deviceID, houseID;
  //deviceID and houseID receiver

  //Testing out timer stuff
  Timer _testPageTimer;
  // Timer.run()
  _TestState(this.deviceID, this.houseID) {
    _testPageTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      // print("inside time value of ${_faceFoundInterval}");
      // _faceFoundInterval++;
      print("insider timer");
      // setState(() {
      if (_baseStopwatch.elapsed.inMicroseconds <= 30000000) {
        // print("insider timer");
        // if (_scanResults.length == 0)
        // _faceFoundInterval++;
        // else {
        // print("reset _faceFoundInterval");
        // _faceFoundInterval = 0;
        // }
        // print(DateTime.now());

        // print(_scanResults?.keys.toString());
        doCustomLogging(_scanResults);
      } else {
        print("IN COOLDOWN mODE");
      }
    });
  }
  //Testing out timer stuff
  //APP STATUS
  AppLifecycleState _notificationTest;
  // String notificationMain;
  // _TestState(this.notificationMain);
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // print(state.toString());
    setState(() {
      _notificationTest = state;
      print(_notificationTest.toString() + "inside test.dart");
    });
  }

  //APP STATUS
  // final PermissionGroup _permissionGroup = PermissionGroup.storage;
  //----------------FACE------------------------------------
  int _faceFoundInterval = 0;
  CameraController _camera;
  dynamic _scanResults;
  var interpreter;
  CameraLensDirection _direction = CameraLensDirection.front;
  Directory tempDir, logDir;
  File jsonFile, logJSONFile;
  dynamic data = {};
  bool _isDetecting = false;
  bool textFlag = false;
  var _baseStopwatch = Stopwatch();
  bool _faceFound =
      false; //use this variable when if face is not detected....//
  List e1;
  double threshold = 1.0;

  //----------------FACE------------------------------------
  //----------------LOGGIN BUFFER-----------------------------------
  StringBuffer logBuffer = StringBuffer();
  //----------------LOGGIN BUFFER-----------------------------------
  //-----------SENSORS----------------------------------------------------------------------
  List<double> _accelerometerValues;
  List<double> _userAccelerometerValues;
  List<double> _gyroscopeValues;
  List<StreamSubscription<dynamic>> _streamSubscriptions =
      <StreamSubscription<dynamic>>[];
  bool _isLightAvailable = false;
  double _lightVal;
  final envSensors = EnvironmentSensors();
//-----------SENSORS----------------------------------------------------------------------

  Future loadModel() async {
    try {
      final gpuDelegateV2 = tfl.GpuDelegateV2(
          options: tfl.GpuDelegateOptionsV2(
        false,
        tfl.TfLiteGpuInferenceUsage.fastSingleAnswer,
        tfl.TfLiteGpuInferencePriority.minLatency,
        tfl.TfLiteGpuInferencePriority.auto,
        tfl.TfLiteGpuInferencePriority.auto,
      ));

      var interpreterOptions = tfl.InterpreterOptions()
        ..addDelegate(gpuDelegateV2);
      interpreter = await tfl.Interpreter.fromAsset('mobilefacenet.tflite',
          options: interpreterOptions);
    } on Exception {
      print('Failed to load model.');
    }
  }

  void _initializeCamera() async {
    await loadModel();
    _baseStopwatch.start();
    CameraDescription description = await getCamera(_direction);

    ImageRotation rotation = rotationIntToImageRotation(
      description.sensorOrientation,
    );

    _camera =
        CameraController(description, ResolutionPreset.low, enableAudio: false);
    await _camera.initialize();
    // print("waiting for 500ms");
    await Future.delayed(Duration(milliseconds: 500));
    // print("Done waiting for 500ms");
    tempDir = await getApplicationDocumentsDirectory();
    String _embPath = tempDir.path + '/emb.json';
    jsonFile = new File(_embPath);
    if (jsonFile.existsSync()) data = json.decode(jsonFile.readAsStringSync());

    //Initialize Log File
    logDir = await getExternalStorageDirectory();
    String _logPath = logDir.path +
        '/${DateTime.now()}_demoLog.txt'; // Change filename to have timestamp of main.dart
    logJSONFile = File(_logPath);
    //Initialize Log File

    _camera.startImageStream((CameraImage image) {
      if (_camera != null) {
        if (_isDetecting) return;
        _isDetecting = true;
        String res;
        String attention;
        // String theFinal;
        dynamic finalResult = Multimap<String, Face>();
        detect(image, _getDetectionMethod(), rotation, _baseStopwatch).then(
          (dynamic result) async {
            if (result.length == 0) {
              _faceFound = false;
              // if (_baseStopwatch.elapsed.inMicroseconds <= 30000000 &&
              //     _baseStopwatch.elapsed.inSeconds % 3 == 0) {
              //   print("b4 customLogging");
              //   doCustomLogging();
              // }
              // print("No Person found in frame");
            } else
              _faceFound = true;
            Face _face;
            imglib.Image convertedImage =
                _convertCameraImage(image, _direction);
            for (_face in result) {
              double x, y, w, h;
              x = (_face.boundingBox.left - 10);
              y = (_face.boundingBox.top - 10);
              w = (_face.boundingBox.width + 10);
              h = (_face.boundingBox.height + 10);
              imglib.Image croppedImage = imglib.copyCrop(
                  convertedImage, x.round(), y.round(), w.round(), h.round());
              croppedImage = imglib.copyResizeCropSquare(croppedImage, 112);
              // int startTime = new DateTime.now().millisecondsSinceEpoch;
              res = _recog(croppedImage, _face);
              if (_face.headEulerAngleY.abs() < 10.0 &&
                  _face.headEulerAngleZ.abs() < 10.0) {
                attention = ",Attentive";
                textFlag = true;
              } else {
                attention = ",Distracted";
                textFlag = false;
              }
              finalResult.add(res + attention, _face);
            }
            // if (result.length > 0 &&
            //     _baseStopwatch.elapsed.inMicroseconds <= 30000000 &&
            //     _baseStopwatch.elapsed.inSeconds % 3 == 0) {
            //   // print("INSIDE PRINTFACE FOUND");
            //   doCustomLogging(finalResult);
            //   // FLog.logThis(
            //   //   className: "FromTest",
            //   //   methodName: "printFaceFound",
            //   //   text: "number of faces " +
            //   //       result.length.toString() +
            //   //       finalResult.keys.toString(),
            //   //   type: LogLevel.INFO,
            //   //   dataLogType: DataLogType.DEVICE.toString(),
            //   // );
            // }
            setState(() {
              _scanResults = finalResult;
            });

            _isDetecting = false;
          },
        ).catchError(
          (_) {
            _isDetecting = false;
          },
        );
      }
    });
  }

  HandleDetection _getDetectionMethod() {
    final faceDetector = FirebaseVision.instance.faceDetector(
      FaceDetectorOptions(
        mode: FaceDetectorMode.accurate,
        // enableTracking: true,
        // enableLandmarks: true,
        // enableContours: true,
        // enableClassification: true,
      ),
    );
    return faceDetector.processImage;
  }

  Widget _buildResults() {
    const Text noResultsText = const Text('');
    if (_scanResults == null ||
        _camera == null ||
        !_camera.value.isInitialized) {
      return noResultsText;
    }
    CustomPainter painter;

    final Size imageSize = Size(
      _camera.value.previewSize.height,
      _camera.value.previewSize.width,
    );
    painter = FaceDetectorPainter(
      imageSize,
      _scanResults,
    );
    return CustomPaint(
      painter: painter,
    );
  }

  bool _timeInterval() {
    if (_baseStopwatch.elapsed.inMicroseconds <= 30000000) {
      // print(_baseStopwatch.elapsed.inSeconds.toString() + "in active");
      return true;
    } else if (_baseStopwatch.elapsed.inMicroseconds < 40000000) {
      // print(_baseStopwatch.elapsed.inSeconds.toString() + "in cooldown");
      return false;
    } else if (_baseStopwatch.elapsed.inMicroseconds > 40000000) {
      print(_baseStopwatch.elapsed.inSeconds.toString() + "cyclecomplete");
      _baseStopwatch.reset();
      return true;
    }
  }

  Widget _buildImage() {
    if (_camera == null || !_camera.value.isInitialized) {
      return Center(
        child: CircularProgressIndicator(),
      );
    }

    return Container(
      constraints: const BoxConstraints.expand(),
      child: _camera == null
          ? const Center(child: null)
          : Stack(
              fit: StackFit.expand,
              children: <Widget>[
                _timeInterval()
                    ? CameraPreview(_camera)
                    : Text('Camera in Cooldown'),
                _timeInterval() ? _buildResults() : Text(''),
              ],
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // print(widget.notificationMain.toString() + "reporting from test.dart");
    // final List<String> accelerometer =
    //     _accelerometerValues?.map((double v) => v.toStringAsFixed(3))?.toList();
    // final List<String> gyroscope =
    //     _gyroscopeValues?.map((double v) => v.toStringAsFixed(3))?.toList();
    // final List<String> userAccelerometer = _userAccelerometerValues
    //     ?.map((double v) => v.toStringAsFixed(3))
    //     ?.toList();

    return Scaffold(
      appBar: new AppBar(
        title: new Text("Test"),
      ),
      body: _buildImage(),
    );
  }

  imglib.Image _convertCameraImage(
      CameraImage image, CameraLensDirection _dir) {
    int width = image.width;
    int height = image.height;
    // imglib -> Image package from https://pub.dartlang.org/packages/image
    var img = imglib.Image(width, height); // Create Image buffer
    const int hexFF = 0xFF000000;
    final int uvyButtonStride = image.planes[1].bytesPerRow;
    final int uvPixelStride = image.planes[1].bytesPerPixel;
    for (int x = 0; x < width; x++) {
      for (int y = 0; y < height; y++) {
        final int uvIndex =
            uvPixelStride * (x / 2).floor() + uvyButtonStride * (y / 2).floor();
        final int index = y * width + x;
        final yp = image.planes[0].bytes[index];
        final up = image.planes[1].bytes[uvIndex];
        final vp = image.planes[2].bytes[uvIndex];
        // Calculate pixel color
        int r = (yp + vp * 1436 / 1024 - 179).round().clamp(0, 255);
        int g = (yp - up * 46549 / 131072 + 44 - vp * 93604 / 131072 + 91)
            .round()
            .clamp(0, 255);
        int b = (yp + up * 1814 / 1024 - 227).round().clamp(0, 255);
        // color: 0x FF  FF  FF  FF
        //           A   B   G   R
        img.data[index] = hexFF | (b << 16) | (g << 8) | r;
      }
    }
    var img1 = (_dir == CameraLensDirection.front)
        ? imglib.copyRotate(img, -90)
        : imglib.copyRotate(img, 90);
    return img1;
  }

  String _recog(imglib.Image img, Face _face) {
    List input = imageToByteListFloat32(img, 112, 128, 128);
    input = input.reshape([1, 112, 112, 3]);
    List output = List(1 * 192).reshape([1, 192]);
    interpreter.run(input, output);
    output = output.reshape([192]);
    e1 = List.from(output);
    return compare(e1).toUpperCase();
  }

  String compare(List currEmb) {
    if (data.length == 0) return "No Face saved";
    double minDist = 999;
    double currDist = 0.0;
    String predRes = "NOT RECOGNIZED";
    for (String label in data.keys) {
      currDist = euclideanDistance(data[label], currEmb);
      if (currDist <= threshold && currDist < minDist) {
        minDist = currDist;
        predRes = label;
      }
    }
    return predRes;
  }

  //-----------------------------------dispose and init state----------------------------------------
  @override
  void dispose() {
    // FLog.exportLogs();
    // FLog.clearLogs();
    // _someTimer.cancel();
    logJSONFile
        .writeAsString(logBuffer.toString()); // write string buffer to a file
    logBuffer.clear(); // clear the buffer
    _testPageTimer.cancel();
    // interpreter.close();
    _camera.dispose();

    // FLog.clearLogs();

    for (StreamSubscription<dynamic> subscription in _streamSubscriptions) {
      subscription.cancel();
    }
    print("exiting the test page");
    // interpreter.close();
    // print("released Interpreter");

    super.dispose();
  }

  @override
  void initState() {
    super.initState();

    SystemChrome.setPreferredOrientations(
        [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);
    _initializeCamera();
    _streamSubscriptions.add(envSensors.light.listen((double lightv) {
      setState(() {
        _lightVal = lightv;
      });
    }));
    _streamSubscriptions
        .add(accelerometerEvents.listen((AccelerometerEvent event) {
      setState(() {
        _accelerometerValues = <double>[event.x, event.y, event.z];
      });
    }));
    _streamSubscriptions.add(gyroscopeEvents.listen((GyroscopeEvent event) {
      setState(() {
        _gyroscopeValues = <double>[event.x, event.y, event.z];
      });
    }));
    _streamSubscriptions
        .add(userAccelerometerEvents.listen((UserAccelerometerEvent event) {
      setState(() {
        _userAccelerometerValues = <double>[event.x, event.y, event.z];
      });
    }));
  }

  //-----------------------------------dispose and init state----------------------------------------
  //=========================ALL LOGGING FUNCTIONS===================================================
  doCustomLogging([dynamic myScanResult]) {
    String logPersonName;
    String logPersonAttention;
    if (myScanResult.length == 0) {
      // print("NO FACE FOUND NOW INSIDE doCustomLogging");
      // no one found in image so check light and then Sensors
      if (_userAccelerometerValues[0].abs().toStringAsFixed(1) == "0.0" &&
          _userAccelerometerValues[1].abs().toStringAsFixed(1) == "0.0" &&
          _userAccelerometerValues[2].abs().toStringAsFixed(1) == "0.0" &&
          _gyroscopeValues[0].abs().toStringAsFixed(1) == "0.0" &&
          _gyroscopeValues[1].abs().toStringAsFixed(1) == "0.0" &&
          _gyroscopeValues[2].abs().toStringAsFixed(1) == "0.0") {
        logPersonAttention = "USER INACTIVE(Sensor) ";
      } else {
        logPersonAttention = "USER ACTIVE(Sensor)";
      }
      if (_lightVal <= 15) {
        // lowlight env so calculate sensor data to find attention
        logPersonName = "Low Light Environment";
      } else if (_lightVal > 15) {
        logPersonName = "NO Face found in frame";
      }
      LogClass _tempObj = LogClass(DateTime.now(), myScanResult.length,
          logPersonName, logPersonAttention, deviceID, houseID);
      print(_tempObj.toString());
      logBuffer.write(_tempObj.toString());
    } else {
      // print("TODO FOR WHEN FACE IS FOUND");
      List<dynamic> getNames =
          myScanResult.keys.map((ele) => ele.split(",")[0]).toList();
      // List<String> getAttention = myScanResult.keys.map((ele) => ele.split(", "))
      LogClass _tempObj = LogClass(DateTime.now(), myScanResult.length,
          getNames.toString(), myScanResult.keys.toString(), deviceID, houseID);
      print(_tempObj.toString());
      logBuffer.write(_tempObj.toString());
      // for (var ele in finalResult) {}
    }
  }

  // String printNoFace() {
  //   // FLog.logThis(
  //   //   className: "FromTest",
  //   //   methodName: "printNoFace",
  //   //   text: "NO PERSON IN FRAME FLOG",
  //   //   type: LogLevel.INFO,
  //   //   dataLogType: DataLogType.DEVICE.toString(),
  //   // );
  //   if (_lightVal < 15) {
  //     return "Lowlight Environment";
  //   }
  //   return "No Person in Frame";
  // }

  // void printLightVal() {
  //   String _lightLog;
  //   if (_lightVal < 15) {
  //     _lightLog = "Lowlight Environment";
  //   } else {
  //     _lightLog = "BrightLight Environment";
  //   }
  //   // FLog.logThis(
  //   //   className: "FromTest",
  //   //   methodName: "printLightVal",
  //   //   text: _lightLog,
  //   //   type: LogLevel.INFO,
  //   //   dataLogType: DataLogType.DEVICE.toString(),
  //   // );
  // }

  // void printSensorVal() {
  //   String _resultFromSensor;
  //   if (_userAccelerometerValues[0].abs().toStringAsFixed(1) == "0.0" &&
  //       _userAccelerometerValues[1].abs().toStringAsFixed(1) == "0.0" &&
  //       _userAccelerometerValues[2].abs().toStringAsFixed(1) == "0.0" &&
  //       _gyroscopeValues[0].abs().toStringAsFixed(1) == "0.0" &&
  //       _gyroscopeValues[1].abs().toStringAsFixed(1) == "0.0" &&
  //       _gyroscopeValues[2].abs().toStringAsFixed(1) == "0.0") {
  //     _resultFromSensor = "USER INACTIVE(Sensor)";
  //   } else {
  //     _resultFromSensor = "USER ACTIVE(Sensor)";
  //   }
  //   FLog.logThis(
  //     className: "FromTest",
  //     methodName: "printFaceFound",
  //     text: _resultFromSensor,
  //     type: LogLevel.INFO,
  //     dataLogType: DataLogType.DEVICE.toString(),
  //   );
  // }

  // void printFaceFound(int noOfFaces, dynamic finalResult) {
  //   List<String> allFaces;
  //   for (String facelabel in finalResult.keys) {
  //     allFaces.add(facelabel);
  //   }
  //   print("INSIDE PRINTFACE FOUND");
  //   FLog.logThis(
  //     className: "FromTest",
  //     methodName: "printFaceFound",
  //     text: noOfFaces.toString() + allFaces.toString(),
  //     type: LogLevel.INFO,
  //     dataLogType: DataLogType.DEVICE.toString(),
  //   );
  // }
  //=========================ALL LOGGING FUNCTIONS===================================================

}
