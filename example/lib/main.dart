import 'dart:io';
import 'package:camera_multi_picker/picker_resolution_preset.dart';
import 'package:flutter/material.dart';
import 'package:camera_multi_picker/camera_file.dart';
import 'package:camera_multi_picker/camera_multi_picker.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    List<MediaModel> imageList = <MediaModel>[];
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(
        imageList: imageList,
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  final List<MediaModel> imageList;
  const MyHomePage({super.key, required this.imageList});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  List<MediaModel> images = [];
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Column(
        children: [
          ElevatedButton(
            child: const Text("Capture"),
            onPressed: () async {
              CameraMultiPicker.capture(
                context: context,
                maxPhotoes: 5,
                isImagePreview: false,
                resolution: PickerResolutionPreset.max,
              ).then((value) {
                setState(() {
                  images = value;
                });
              });
            },
          ),
          Expanded(
            child: ListView.builder(
                shrinkWrap: true,
                itemCount: images.length,
                itemBuilder: (context, index) {
                  return Image.file(File(images[index].file.path));
                }),
          )
        ],
      ),
    );
  }
}
