import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_player/video_player.dart';

import 'package:path/path.dart';
import 'package:async/async.dart';
import 'package:http/http.dart' as http;

class FlowersHome extends StatefulWidget {
  @override
  _FlowersHomeState createState() {
    return _FlowersHomeState();
  }
}

/// Returns a suitable camera icon for [direction].
IconData getCameraLensIcon(CameraLensDirection direction) {
  switch (direction) {
    case CameraLensDirection.back:
      return Icons.camera_rear;
    case CameraLensDirection.front:
      return Icons.camera_front;
    case CameraLensDirection.external:
      return Icons.camera;
  }
  throw ArgumentError('Unknown lens direction');
}

void logError(String code, String message) =>
    print('Error: $code\nError Message: $message');

class _FlowersHomeState extends State<FlowersHome> {
  String imagePath;
  String videoPath;
  VideoPlayerController videoController;
  VoidCallback videoPlayerListener;

  

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: const Text('Which flower are you?'),
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            child: Container(
              child: Padding(
                padding: const EdgeInsets.all(1.0),
                child: Center(
                  child: _cameraPreviewWidget(),
                ),
              ),
              decoration: BoxDecoration(
                color: Colors.black,
                border: Border.all(
                  color: controller != null && controller.value.isRecordingVideo
                      ? Colors.redAccent
                      : Colors.grey,
                  width: 3.0,
                ),
              ),
            ),
          ),
          _captureControlRowWidget(context),
       /*    Padding(
            padding: const EdgeInsets.all(5.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: <Widget>[
                _cameraTogglesRowWidget(),
                _thumbnailWidget(),
              ],
            ),
          ), */
        ],
      ),
    );
  }

  /// Display the preview from the camera (or a message if the preview is not available).
  Widget _cameraPreviewWidget() {
    if (controller == null || !controller.value.isInitialized) {
      if (selectedCamera == -1) {
        return const Text(
          'Camera not available',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24.0,
            fontWeight: FontWeight.w900,
          ),
        );
      } else {
        onNewCameraSelected(cameras[selectedCamera]);
        return const Text(
          'Loading camera',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24.0,
            fontWeight: FontWeight.w900,
          ),
        );        
      }
    } else {
      return AspectRatio(
        aspectRatio: controller.value.aspectRatio,
        child: CameraPreview(controller),
      );
    }
  }

   /// Display the control bar with buttons to take pictures and record videos.
  Widget _captureControlRowWidget(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      mainAxisSize: MainAxisSize.max,
      children: <Widget>[
        IconButton(
          icon: const Icon(Icons.camera_alt),
          color: Colors.blue,
          onPressed:
                  controller != null &&
                  controller.value.isInitialized &&
                  !controller.value.isRecordingVideo
                  ? () { 
                          Navigator.push(context, new MaterialPageRoute(builder: (context) => new ShowResults()),);          
                       }  : null,
        ),
        IconButton(
          icon: const Icon(Icons.switch_camera),
          color: Colors.blue,
          onPressed: cameras.length > 1 ? onNextCameraButtonPressed : null,
        ),        
      ],
    );
  }


  void onNewCameraSelected(CameraDescription cameraDescription) async {
    if (controller != null) {
      await controller.dispose();
    }
    controller = CameraController(cameraDescription, ResolutionPreset.high);

    // If the controller is updated then update the UI.
    controller.addListener(() {
      if (mounted) setState(() {});
      if (controller.value.hasError) {
        showInSnackBar('Camera error ${controller.value.errorDescription}');
      }
    });

    try {
      await controller.initialize();
    } on CameraException catch (e) {
      _showCameraException(e);
    }

    if (mounted) {
      setState(() {});
    }
  }

  void onNextCameraButtonPressed() {
    selectedCamera += 1;
    if (selectedCamera >= cameras.length) {
      selectedCamera = 0;
    }
    onNewCameraSelected(cameras[selectedCamera]);
  }

}

  void showInSnackBar(String message) {
    _scaffoldKey.currentState.showSnackBar(SnackBar(content: Text(message)));
  }

  void _showCameraException(CameraException e) {
    logError(e.code, e.description);
    showInSnackBar('Error: ${e.code}\n${e.description}');
  }


class ShowResults extends StatefulWidget {
  @override
  _ShowResultsState createState() {
    return _ShowResultsState();
  }
}

class _ShowResultsState extends State<ShowResults> {
  String timestamp() => DateTime.now().millisecondsSinceEpoch.toString();
  String flowerResult = '';
  String imageFileName = '';

  void awsUpload(File imageFile) async {  
    
    var stream = new http.ByteStream(DelegatingStream.typed(imageFile.openRead()));
    var length = await imageFile.length();

    var uri = Uri.parse('http://flowers-env-pytorch.wffmpcmuy2.us-west-2.elasticbeanstalk.com/predict');

    var request = new http.MultipartRequest("POST", uri);
    var multipartFile = new http.MultipartFile('file', stream, length,
          filename: basename(imageFile.path));
          //contentType: new MediaType('image', 'png'));

    request.files.add(multipartFile);
    var response = await request.send();
    print(response.statusCode);
    response.stream.transform(utf8.decoder).listen((value) {
        print(value);
        if (mounted) {
          if (value != null) {
            setState(() {
              flowerResult =  value;
            });
          }
        }
    });
  }

  Future<String> takePicture() async {
    final Directory extDir = await getApplicationDocumentsDirectory();
    final String dirPath = '${extDir.path}/Pictures/flutter_test';
    await Directory(dirPath).create(recursive: true);
    final String filePath = '$dirPath/${timestamp()}.jpg';

    if (controller.value.isTakingPicture) {
      // A capture is already pending, do nothing.
      return null;
    }

    try {
      await controller.takePicture(filePath);
    } on CameraException catch (e) {
      _showCameraException(e);
      return null;
    }
    return filePath;
  }

  String formatPerc(double n) {
    double n2 = n*100;
    return n2.toStringAsFixed(n2.truncateToDouble() == n2 ? 0 : 2) + '%';
  }

/// Display the thumbnail of the captured image or video.
  Widget pictureWidget() {
    return Expanded(
      child: Align(
        alignment: Alignment.center,
        child: Image.file(File(imageFileName)),
      ),
    );
  }

  Widget resultWidget() {
 
    if (flowerResult == '') {
      return Text('Uploading..');
    }

    List<Widget> result = [];  

    var responseJSON = json.decode(flowerResult);
    for (final responseItem in responseJSON) {
        String category = responseItem['Category'];
        double prob = responseItem['Prob'];
        result.add(Text(category + ' ' + formatPerc(prob)));
        
    }
    return Column( children: result );
  }

  @override
  void initState() { 
    takePicture().then((String filePath) {
      imageFileName = filePath;
      awsUpload(new File(filePath)); 
    });
  }


  @override
  Widget build(BuildContext context)  {
    return new Scaffold(
      appBar: new AppBar(
        title: new Text("Flower classification"),
      ),
      body: Column(
        children: <Widget>[
          pictureWidget(),
          resultWidget(),
        ]
      )
    );
  }
}

class FlowersApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: FlowersHome(),
    );
  }
}

List<CameraDescription> cameras;
CameraController controller;

int selectedCamera = -1;
String lastResult = '';
final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

Future<void> main() async {
  // Fetch the available cameras before initializing the app.
  try {
    cameras = await availableCameras();
    if (cameras.length > 0) {
      selectedCamera = 0;
    }
  } on CameraException catch (e) {
    logError(e.code, e.description);
  }
  runApp(FlowersApp());
}