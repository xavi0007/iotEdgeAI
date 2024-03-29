import 'dart:convert';
import 'package:async/async.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:iotClient/Screens/prediction.dart';
import 'package:path/path.dart';
import 'package:permission_handler/permission_handler.dart';

class Upload extends StatefulWidget {
  @override
  _UploadState createState() => _UploadState();
}

class _UploadState extends State<Upload> {
  File _image;
  final picker = ImagePicker();
  Future<Prediction> _futurePrediction;

  Future getImage() async {
    final pickedFile = await picker.getImage(source: ImageSource.camera);
    setState(() {
      if (pickedFile != null) {
        _image = File(pickedFile.path);
      } else {
        print('No image selected.');
      }
    });
  }

  Future getImageFromGallery() async {
    final pickedFile = await picker.getImage(source: ImageSource.gallery);
    setState(() {
      if (pickedFile != null) {
        _image = File(pickedFile.path);
      } else {
        print('No image selected.');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Upload Image"),
      ),
      body: SingleChildScrollView(
          child: Container(
        child: Center(
            child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            _image == null
                ? new Text("No image selected")
                : new Container(
                    child: Image.file(
                      _image,
                    ),
                  ),
            Container(
                child: RaisedButton(
                    color: Colors.blue,
                    textColor: Colors.white,
                    child: Text(
                      "Take a photo",
                    ),
                    onPressed: () async {
                      if (!await Permission.camera.isGranted) {
                        await Permission.camera.request();
                        getImage();
                      } else {
                        getImage();
                      }
                    })),
            Container(
              child: RaisedButton(
                  color: Colors.blue,
                  textColor: Colors.white,
                  child: Text(
                    "Choose photo from phone",
                  ),
                  onPressed: () async {
                    if (!await Permission.photos.isGranted) {
                      await Permission.photos.request();
                      openAppSettings();
                    } else {
                      getImageFromGallery();
                    }
                  }),
            ),
            SizedBox(height: 20),
            RaisedButton(
              color: Colors.blue,
              textColor: Colors.white,
              child: Text("Upload to server"),
              onPressed: () {
                _futurePrediction = uploadImageToServer(_image);
                CircularProgressIndicator();
              },
            ),
            SizedBox(height: 20),
            if (_futurePrediction != null)
              FutureBuilder<Prediction>(
                future: _futurePrediction,
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    String prediction = snapshot.data.predictedClass;
                    String score = snapshot.data.score;
                    String title = snapshot.data.title;
                    String time = snapshot.data.timeStamp;
                    return Text(
                      'The model is $score confident that the image $title, sent at $time is $prediction',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontWeight: FontWeight.bold),
                    );
                  } else if (snapshot.hasError) {
                    return Text("${snapshot.error}");
                  }
                  return CircularProgressIndicator();
                },
              )
            else
              Text("Upload image to get prediction of the health of the leave")
          ],
        )),
      )),
    );
  }

  Future<Prediction> uploadImageToServer(File imageFile) async {
    print("attempting to connect to server......");
    var stream =
        new http.ByteStream(DelegatingStream.typed(imageFile.openRead()));
    var length = await imageFile.length();

    // var uri = Uri.parse('http://20.198.224.77:80/predict');
    var uri = Uri.parse('http://127.0.0.1/predict');
    //if it is android simulator change to 10.0.2.2
    print("connection established.");
    var request = new http.MultipartRequest("POST", uri);
    print(uri.port);
    var multipartFile = new http.MultipartFile('file', stream, length,
        filename: basename(imageFile.path));

    request.files.add(multipartFile);
    var streamedResponse = await request.send();
    var response = await http.Response.fromStream(streamedResponse);
    if (response.statusCode == 201 || response.statusCode == 200) {
      // If the server did return a 201 CREATED response,
      // then parse the JSON.
      print("Post request responded");
      print(jsonDecode(response.body));
      return Prediction.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load prediction');
    }
  }
}
