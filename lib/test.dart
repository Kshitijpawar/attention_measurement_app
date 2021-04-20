import 'dart:convert';
import 'dart:io';
import 'dart:async';

import 'package:environment_sensors/environment_sensors.dart';
import 'package:phone_state_i/phone_state_i.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:mainapp/detector_painters.dart';
import 'package:mainapp/utils.dart';

import 'package:camera/camera.dart';
import 'package:usage_stats/usage_stats.dart';
import 'package:quiver/collection.dart';
import 'package:firebase_ml_vision/firebase_ml_vision.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sensors/sensors.dart';
import 'package:tflite_flutter/tflite_flutter.dart' as tfl;
import 'package:image/image.dart' as imglib;

import 'logclass.dart';

class Test extends StatefulWidget {
  String deviceID, houseID;
  DateTime dateFromMain;
  Test({Key key, this.deviceID, this.houseID, this.dateFromMain})
      : super(key: key);
  @override
  _TestState createState() => _TestState(deviceID, houseID, dateFromMain);
}

class _TestState extends State<Test> with WidgetsBindingObserver {
  //microphone volume level
  double _theWidgetVolume = -1;
  bool isRecording = false;
  static const platform =
      const MethodChannel('samples.flutter.dev/recordingaudio');
  //microphone volume level
  //deviceID and houseID receiver
  String deviceID, houseID;
  DateTime dateFromMain;
  //deviceID and houseID receiver
  //Phone event boolean connected or not
  bool _isPhone = false;
  //Phone event boolean connected or not

  //Testing out timer stuff
  Timer _testPageTimer;
  // Timer.run()
  _TestState(this.deviceID, this.houseID, this.dateFromMain) {
    _testPageTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (_baseStopwatch.elapsed.inMicroseconds <= 30000000) {
        // print("insider timer");
        if (_scanResults.length == 0 && !_appSleep)
          _faceNotFoundInterval++;
        else if (_scanResults.length > 0 && !_appSleep) {
          print("reset _faceFoundInterval since face was found");
          _faceNotFoundInterval = 0;
        }
        if (!_appSleep) {
          initUsage();
          _getEnvVolume();
          doCustomLogging(_scanResults);
        }
      } else {
        // print(_baseStopwatch.elapsed.inSeconds);
        if (_baseStopwatch.elapsed.inMicroseconds > 42000000) {
          setState(() {
            _baseStopwatch.reset();
            print("inside setstate");
          });
        }
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
      // print(_notificationTest.toString() + "inside test.dart");
    });
  }

  //----------------FACE------------------------------------
  int _faceNotFoundInterval = 0;
  bool _appSleep = false;
  CameraController _camera;
  dynamic _scanResults;
  var interpreter;
  CameraLensDirection _direction = CameraLensDirection.front;
  Directory tempDir, logDir;
  File jsonFile, logOfficialJSONFile, logUnofficialJSONFile;
  dynamic data = {};
  bool _isDetecting = false;
  bool textFlag = false;
  var _baseStopwatch = Stopwatch();
  var _secondaryStopwatch = Stopwatch();
  bool _faceFound =
      false; //use this variable when if face is not detected....//
  List e1;
  double threshold = 1.0;

  //----------------FACE------------------------------------
  //----------------LOGGIN BUFFER-----------------------------------
  StringBuffer logOfficialBuffer = StringBuffer();
  StringBuffer logUnofficialBuffer = StringBuffer();
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
//app use
  List<EventUsageInfo> events;

  Future<void> initUsage() async {
    UsageStats.grantUsagePermission();
    DateTime endDate = new DateTime.now();
    // DateTime startDate = DateTime(dateFromMain);
    List<EventUsageInfo> queryEvents =
        await UsageStats.queryEvents(dateFromMain, endDate);

    this.setState(() {
      events = queryEvents.reversed.toList();
    });
  }

//app use

//microphone level
// start custom recording
  Future<void> _startCustomRecording() async {
    try {
      await platform.invokeMethod('startREC');
    } on PlatformException catch (e) {
      print(e.message);
    }
  }

  // stop custom recording
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

  // get volume custom
  Future<void> _getEnvVolume() async {
    try {
      final double theVolume = await platform.invokeMethod('getVolume');
      // print(theVolume.toStringAsFixed(3) + " got this from channel");
      // setState(() {
      _theWidgetVolume = theVolume;
      // });
    } on PlatformException catch (e) {
      print(e.message + " found error");
    }
  }

//microphone level
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

    //Initialize Official Log File
    logDir = await getExternalStorageDirectory();
    String _logOfficialPath =
        logDir.path + '/Official_${DateTime.now()}_demoLog.txt';
    logOfficialJSONFile = File(_logOfficialPath);
    //Initialize Official Log File

    //Initialize UnOfficial Log File
    logDir = await getExternalStorageDirectory();
    String _logUnofficialPath =
        logDir.path + '/Unoffcial_${DateTime.now()}_demoLog.txt';
    logUnofficialJSONFile = File(_logUnofficialPath);
    //Initialize Official Log File

    _camera.startImageStream((CameraImage image) {
      if (_camera != null) {
        if (_isDetecting) return;
        _isDetecting = true;
        String res;
        String attention;
        dynamic finalResult = Multimap<String, Face>();
        detect(image, _getDetectionMethod(), rotation, _baseStopwatch, _isPhone)
            .then(
          (dynamic result) async {
            if (result.length == 0) {
              _faceFound = false;
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
      if (_isPhone)
        return false;
      else {
        if (_faceNotFoundInterval > 3) {
          // print("face not found for 9 seconds");
          if (!_secondaryStopwatch.isRunning) {
            // print("Starting secondary stopwatch");
            _secondaryStopwatch.start();
            _secondaryStopwatch.reset();
          }

          _appSleep = true;
          if (_secondaryStopwatch.elapsed.inSeconds < 60) {
            // print("secondary stopwatch: " +
            //     _secondaryStopwatch.elapsed.inSeconds.toString());
            return false;
          }
          // print/("face not found for 9 seconds");
          _baseStopwatch.reset();
          // print("SECONDARY STOPWATCH RESET");
          _secondaryStopwatch.stop();
          _appSleep = false;
          _faceNotFoundInterval = 0;
          return true;
        }

        return true;
      }
    } else if (_baseStopwatch.elapsed.inMicroseconds < 40000000) {
      if (_secondaryStopwatch.elapsed.inSeconds > 60 &&
          _secondaryStopwatch.isRunning) {
        _secondaryStopwatch.stop();
        _appSleep = false;
        _faceNotFoundInterval = 0;
      }
      return false;
    } else if (_baseStopwatch.elapsed.inMicroseconds > 40000000) {
      if (_secondaryStopwatch.elapsed.inSeconds > 60 &&
          _secondaryStopwatch.isRunning) {
        _secondaryStopwatch.stop();
        _appSleep = false;
        _faceNotFoundInterval = 0;
      }
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
    // _someTimer.cancel();
    _stopCustomRecording();
    logOfficialJSONFile.writeAsString(
        logOfficialBuffer.toString()); // write string buffer to a file
    logOfficialBuffer.clear(); // clear the buffer
    logUnofficialJSONFile.writeAsString(
        logUnofficialBuffer.toString()); // write string buffer to a file
    logUnofficialBuffer.clear(); // clear the buffer
    _testPageTimer.cancel();
    // interpreter.close();
    _camera.dispose();

    for (StreamSubscription<dynamic> subscription in _streamSubscriptions) {
      subscription.cancel();
    }
    print("exiting the test page");
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _startCustomRecording();
    isRecording = true;
    SystemChrome.setPreferredOrientations(
        [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);
    _initializeCamera();
    //app use
    initUsage();
    //app use
    //added phone call listener
    _streamSubscriptions
        .add(phoneStateCallEvent.listen((PhoneStateCallEvent event) {
      print('Call is Incoming or Connected' + event.stateC);
      if (event.stateC == "true") {
        LogClass callObject = LogClass(
            DateTime.now(),
            _scanResults.length,
            _scanResults.keys.map((ele) => ele.split(",")[0]).toString(),
            "Call Detected",
            deviceID,
            houseID);
        print(callObject.toString());
        logOfficialBuffer.write(callObject);
        logUnofficialBuffer.write(callObject);
      }
      setState(() {
        // if (event.stateC == "true")
        _isPhone = event.stateC.toLowerCase() == "true";
        // if (_isPhone) print("hihihi");
      });
    }));
    //added phone call listener
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
    // WidgetsBinding.instance.addPostFrameCallback((_) {
    //   print("inside init state");

    // });
  }

  //-----------------------------------dispose and init state----------------------------------------
  //=========================ALL LOGGING FUNCTIONS===================================================
  doCustomLogging([dynamic myScanResult]) {
    String logPersonName;
    String logPersonAttention = "unintialized";
    List<String> _appPackageNames;
    List<String> _restrictedApps = ["zoom", "instagram", "whatsapp"];
    List<String> _foundAppResult = [];
    if (myScanResult.length == 0) {
      if (_userAccelerometerValues[0].abs().toStringAsFixed(1) == "0.0" &&
          _userAccelerometerValues[1].abs().toStringAsFixed(1) == "0.0" &&
          _userAccelerometerValues[2].abs().toStringAsFixed(1) == "0.0" &&
          _gyroscopeValues[0].abs().toStringAsFixed(1) == "0.0" &&
          _gyroscopeValues[1].abs().toStringAsFixed(1) == "0.0" &&
          _gyroscopeValues[2].abs().toStringAsFixed(1) == "0.0") {
        //microphone value
        if (_theWidgetVolume != -1 && !_theWidgetVolume.isInfinite) {
          if (_theWidgetVolume > 80) {
            logPersonAttention = "USER INACTIVE(Sensor), Noise level high";
          } else {
            //not noisy
            // print("$_theWidgetVolume is noise level");
            logPersonAttention = "USER INACTIVE(Sensor), Noise level low";
          }
        } else
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
      //if app usage is found
      if (events.length != 0) {
        dateFromMain = DateTime.now();
        //check if restricted apps present in app usage list
        _appPackageNames = events.map((el) => el.packageName).toSet().toList();
        _appPackageNames.forEach((pName) {
          _restrictedApps.forEach((aName) {
            if (pName.contains(aName)) {
              _foundAppResult.add(aName);
            }
          });
        });
        // _foundAppResult = _foundAppResult.toSet().toList();
        //reset mainDate for latest app usage and clear _appPackageNames and events
        _appPackageNames.clear();
        events.clear();
        //log person attention as inattentive and using apps
        if (_foundAppResult.isNotEmpty)
          logPersonAttention =
              "Inattentive Using Apps: " + _foundAppResult.toString();
        //now log this
        LogClass _tempOfficialObj = LogClass(
            DateTime.now(),
            myScanResult.length,
            logPersonName,
            logPersonAttention,
            deviceID,
            houseID);
        LogClass _tempUnofficialObj = LogClass(
            DateTime.now(),
            myScanResult.length,
            logPersonName + " LightVal: " + _lightVal.toString(),
            logPersonAttention,
            deviceID,
            houseID);
        print(_tempOfficialObj.toString());
        logOfficialBuffer.write(_tempOfficialObj.toString());
        logUnofficialBuffer.write(_tempUnofficialObj.toString());
      } else {
        LogClass _tempOfficialObj = LogClass(
            DateTime.now(),
            myScanResult.length,
            logPersonName,
            logPersonAttention,
            deviceID,
            houseID);
        String gyroVal = " Gyro[X, Y, Z]: " + _gyroscopeValues.toString();
        String accVal =
            " User Acc[X, Y, Z]:" + _userAccelerometerValues.toString();
        String volVal =
            " Volume(in Db): " + _theWidgetVolume.toStringAsFixed(3);
        LogClass _tempUnofficialObj = LogClass(
            DateTime.now(),
            myScanResult.length,
            logPersonName + " LightVal: " + _lightVal.toString(),
            logPersonAttention + gyroVal + accVal + volVal,
            deviceID,
            houseID);
        print(_tempOfficialObj.toString());
        logOfficialBuffer.write(_tempOfficialObj.toString());
        logUnofficialBuffer.write(_tempUnofficialObj.toString());
      }
    } else {
      //if app usage is found
      if (events.length != 0) {
        dateFromMain = DateTime.now();
        //check if restricted apps present in app usage list
        _appPackageNames = events.map((el) => el.packageName).toSet().toList();
        _appPackageNames.forEach((pName) {
          _restrictedApps.forEach((aName) {
            if (pName.contains(aName)) {
              _foundAppResult.add(aName);
            }
          });
        });
        // _foundAppResult = _foundAppResult.toSet().toList();
        //reset mainDate for latest app usage and clear _appPackageNames and events
        _appPackageNames.clear();
        events.clear();
        //log person attention as inattentive and using apps
        if (_foundAppResult.isNotEmpty)
          logPersonAttention =
              "Inattentive Using Apps: " + _foundAppResult.toString();
        //now log this
        List<dynamic> getNames =
            myScanResult.keys.map((ele) => ele.split(",")[0]).toList();
        LogClass _tempOfficialObj = LogClass(
            DateTime.now(),
            myScanResult.length,
            getNames.toString(),
            logPersonAttention,
            deviceID,
            houseID);
        print(_tempOfficialObj.toString());
        logOfficialBuffer.write(_tempOfficialObj.toString());
      } else {
        List<dynamic> getNames =
            myScanResult.keys.map((ele) => ele.split(",")[0]).toList();
        LogClass _tempOfficialObj = LogClass(
            DateTime.now(),
            myScanResult.length,
            getNames.toString(),
            myScanResult.keys.toString(),
            deviceID,
            houseID);
        print(_tempOfficialObj.toString());
        logOfficialBuffer.write(_tempOfficialObj.toString());
      }
    }
  }
}
