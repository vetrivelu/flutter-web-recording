import 'dart:html' as html;
import 'dart:html';
import 'dart:js' as js;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:video_recorder_app/firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late html.VideoElement _preview;
  late html.MediaRecorder _recorder;
  late html.VideoElement _result;

  @override
  void initState() {
    super.initState();
    _preview = html.VideoElement()
      ..autoplay = true
      ..muted = true
      ..width = html.window.innerWidth!
      ..height = html.window.innerHeight!;

    _result = html.VideoElement()
      ..autoplay = false
      ..muted = false
      ..width = html.window.innerWidth!
      ..height = html.window.innerHeight!
      ..controls = true;

    // ignore: undefined_prefixed_name
    ui.platformViewRegistry.registerViewFactory('preview', (int _) => _preview);

    // ignore: undefined_prefixed_name
    ui.platformViewRegistry.registerViewFactory('result', (int _) => _result);
  }

  Future<Uint8List> fileConverter(Blob blob) async {
    final reader = html.FileReader();
    reader.readAsArrayBuffer(blob);
    await reader.onLoad.first;
    return reader.result as Uint8List;
  }

  Future uploadFile(String uid, Blob file) async {
    print("Inside upload file.......");
    final path = "nachweise/$uid";
    Uint8List fileConverted = await fileConverter(file);
    print("File converted");
    try {
      FirebaseStorage.instance.ref().child(path).putData(fileConverted).then((bla) => print("sucess"));
    } on FirebaseException catch (e) {
      print(e.toString());
      return null;
    }
  }

  Future<html.MediaStream?> _openCamera() async {
    final html.MediaStream? stream = await html.window.navigator.mediaDevices?.getUserMedia({'video': true, 'audio': true});
    _preview.srcObject = stream;
    return stream;
  }

  void startRecording(html.MediaStream stream) {
    _recorder = html.MediaRecorder(stream);
    _recorder.start();

    html.Blob blob = html.Blob([]);

    _recorder.addEventListener('dataavailable', (event) {
      blob = js.JsObject.fromBrowserObject(event)['data'];
    }, true);

    _recorder.addEventListener('stop', (event) {
      final url = html.Url.createObjectUrl(blob);
      _result.src = url;

      stream.getTracks().forEach((track) {
        if (track.readyState == 'live') {
          track.stop();
        }
      });
      print("Uploading blob...");
      uploadFile('uid', blob);
    });
  }

  void stopRecording() => _recorder.stop();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Web Recording',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: Scaffold(
        appBar: AppBar(
          title: Text('Flutter Web Recording'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'Recording Preview',
                style: Theme.of(context).textTheme.headline6,
              ),
              Container(
                margin: EdgeInsets.symmetric(vertical: 10.0),
                width: 300,
                height: 200,
                color: Colors.blue,
                child: HtmlElementView(
                  key: UniqueKey(),
                  viewType: 'preview',
                ),
              ),
              Container(
                margin: EdgeInsets.all(20.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    ElevatedButton(
                      onPressed: () async {
                        final html.MediaStream? stream = await _openCamera();
                        startRecording(stream!);
                      },
                      child: Text('Start Recording'),
                    ),
                    SizedBox(
                      width: 20.0,
                    ),
                    ElevatedButton(
                      onPressed: () => stopRecording(),
                      child: Text('Stop Recording'),
                    ),
                  ],
                ),
              ),
              Text(
                'Recording Result',
                style: Theme.of(context).textTheme.headline6,
              ),
              Container(
                margin: EdgeInsets.symmetric(vertical: 10.0),
                width: 300,
                height: 200,
                color: Colors.blue,
                child: HtmlElementView(
                  key: UniqueKey(),
                  viewType: 'result',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
