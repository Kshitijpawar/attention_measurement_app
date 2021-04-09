import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'dart:convert';
import 'dart:io';
import 'dart:async';

import 'package:mainapp/detector_painters.dart';
import 'package:mainapp/utils.dart';

import 'package:camera/camera.dart';
import 'package:f_logs/f_logs.dart';
import 'package:quiver/collection.dart';
import 'package:firebase_ml_vision/firebase_ml_vision.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sensors/sensors.dart';
import 'package:tflite_flutter/tflite_flutter.dart' as tfl;
import 'package:image/image.dart' as imglib;

class Test extends StatefulWidget {
  @override
  _TestState createState() => _TestState();
}

init() {
  LogsConfig config = FLog.getDefaultConfigurations()
    ..isDevelopmentDebuggingEnabled = true
    ..timestampFormat = TimestampFormat.TIME_FORMAT_FULL_3
    ..formatType = FormatType.FORMAT_CUSTOM
    ..fieldOrderFormatCustom = [
      FieldName.TIMESTAMP,
      FieldName.LOG_LEVEL,
      FieldName.CLASSNAME,
      FieldName.METHOD_NAME,
      FieldName.TEXT,
      FieldName.EXCEPTION,
      FieldName.STACKTRACE
    ]
    ..customOpeningDivider = "|"
    ..customClosingDivider = "|";

  FLog.applyConfigurations(config);
}

class _TestState extends State<Test> {
  // final PermissionGroup _permissionGroup = PermissionGroup.storage;
  //----------------FACE------------------------------------
  CameraController _camera;
  dynamic _scanResults;
  var interpreter;
  CameraLensDirection _direction = CameraLensDirection.front;
  Directory tempDir;
  File jsonFile;
  dynamic data = {};
  bool _isDetecting = false;
  bool textFlag = false;

  bool _faceFound =
      false; //use this variable when if face is not detected....//
  List e1;
  double threshold = 1.0;

  //----------------FACE------------------------------------
  //----------------TIMER VAR-----------------------------------
  int _totalTimeElapsedSinceInception;
  var _baseStopwatch;
  //----------------TIMER VAR-----------------------------------
  //-----------SENSORS----------------------------------------------------------------------
  List<double> _accelerometerValues;
  List<double> _userAccelerometerValues;
  List<double> _gyroscopeValues;
  List<StreamSubscription<dynamic>> _streamSubscriptions =
      <StreamSubscription<dynamic>>[];
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

    _camera.startImageStream((CameraImage image) {
      if (_camera != null) {
        if (_isDetecting) return;
        _isDetecting = true;
        String res;
        String attention;
        // String theFinal;
        dynamic finalResult = Multimap<String, Face>();
        detect(image, _getDetectionMethod(), rotation).then(
          (dynamic result) async {
            if (result.length == 0) {
              _faceFound = false;
              print("no Person Detected in Frame!!!");
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
                // print("Person is attentive ++");
                attention = " Attentive";
                textFlag = true;
              } else {
                // print("Person is distracted--");
                // print(_face.leftEyeOpenProbability.toStringAsFixed(3));
                // print(_face.rightEyeOpenProbability.toStringAsFixed(3));
                attention = " Distracted";
                textFlag = false;
              }
              // // int endTime = new DateTime.now().millisecondsSinceEpoch;
              // // print("Inference took ${endTime - startTime}ms");
              // // print(res);
              // print(res + attention);
              finalResult.add(res + attention, _face);
              // finalResult.add(res, _face);
            }
            setState(() {
              // print("inside final result");

              // _scanResults = finalResult + " " + _attentionResults;
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
                CameraPreview(_camera),
                _buildResults(),
              ],
            ),
    );
  }

  // void _toggleCameraDirection() async {
  //   if (_direction == CameraLensDirection.back) {
  //     _direction = CameraLensDirection.front;
  //   } else {
  //     _direction = CameraLensDirection.back;
  //   }
  //   await _camera.stopImageStream();
  //   await _camera.dispose();

  //   setState(() {
  //     _camera = null;
  //   });

  //   _initializeCamera();
  // }

  // print(_streamSub)
  @override
  Widget build(BuildContext context) {
    final List<String> accelerometer =
        _accelerometerValues?.map((double v) => v.toStringAsFixed(3))?.toList();
    final List<String> gyroscope =
        _gyroscopeValues?.map((double v) => v.toStringAsFixed(3))?.toList();
    final List<String> userAccelerometer = _userAccelerometerValues
        ?.map((double v) => v.toStringAsFixed(3))
        ?.toList();

    return Scaffold(
      appBar: new AppBar(
        title: new Text("Test"),
      ),
      body: _buildImage(),
      //   body: _buildImage(), Column(
      //     children: [
      //       Padding(
      //         child: Row(
      //           mainAxisAlignment: MainAxisAlignment.spaceBetween,
      //           children: <Widget>[
      //             Text('Accelerometer: $accelerometer'),
      //           ],
      //         ),
      //         padding: const EdgeInsets.all(16.0),
      //       ),
      //       Padding(
      //         child: Row(
      //           mainAxisAlignment: MainAxisAlignment.spaceBetween,
      //           children: <Widget>[
      //             Text('UserAccelerometer: $userAccelerometer'),
      //           ],
      //         ),
      //         padding: const EdgeInsets.all(16.0),
      //       ),
      //       Padding(
      //         child: Row(
      //           mainAxisAlignment: MainAxisAlignment.spaceBetween,
      //           children: <Widget>[
      //             Text('Gyroscope: $gyroscope'),
      //           ],
      //         ),
      //         padding: const EdgeInsets.all(16.0),
      //       ),
      //     ],
      //   ),
      //   floatingActionButton: Column(
      //     mainAxisAlignment: MainAxisAlignment.end,
      //     children: [
      //       FloatingActionButton(
      //         onPressed: () {
      //           FLog.logThis(
      //             className: "HomePage",
      //             methodName: "button_press",
      //             text: "ButtonPressed",
      //             type: LogLevel.INFO,
      //             dataLogType: DataLogType.DEVICE.toString(),
      //           );
      //         },
      //         backgroundColor: Colors.blue,
      //         child: Icon(Icons.analytics_outlined),
      //         heroTag: null,
      //       ),
      //       SizedBox(
      //         height: 10,
      //       ),
      //       FloatingActionButton(
      //         onPressed: () {
      //         },
      //         backgroundColor: Colors.blue,
      //         child: Icon(Icons.ac_unit_outlined),
      //         heroTag: null,
      //       )
      //     ],
      //   ),
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
    // print(minDist.toString() + " " + predRes);
    return predRes;
  }

  @override
  void dispose() {
    for (StreamSubscription<dynamic> subscription in _streamSubscriptions) {
      subscription.cancel();
    }
    print("exiting the test page");
    // interpreter.close();
    print("released Interpreter");

    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations(
        [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);
    _initializeCamera();
    init();
    // _initLogs();
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
}
