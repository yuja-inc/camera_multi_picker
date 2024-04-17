import 'dart:async';
import 'dart:io';
import 'package:camera_multi_picker/image_preview.dart';
import "package:flutter/material.dart";
import "package:camera/camera.dart";
import 'package:flutter/services.dart';

class CameraFile extends StatefulWidget {
  final Widget? customButton;
  final SnackBar? customMaxSnackBar;

  final int maxPhotos;
  final bool isImagePreview;
  final ResolutionPreset resolution;

  const CameraFile(
      {super.key,
      this.customButton,
      this.customMaxSnackBar,
      required this.maxPhotos,
      required this.isImagePreview,
      required this.resolution});

  @override
  State<CameraFile> createState() => _CameraFileState();
}

class _CameraFileState extends State<CameraFile> with TickerProviderStateMixin {
  double zoom = 0.0;
  double _scaleFactor = 1.0;
  double scale = 1.0;

  late List<CameraDescription> _cameras;
  CameraController? _controller;
  List<XFile> imageFiles = [];
  List<MediaModel> imageList = <MediaModel>[];
  late int _currIndex;
  late Animation<double> animation;
  AnimationController? _animationController;
  late AnimationController controller;
  late Animation<double> scaleAnimation;
  int? latestImageIndex;

  void addImages(XFile image) {
    setState(() {
      imageFiles.add(image);
      latestImageIndex = imageFiles.length - 1;

      if (_animationController != null) {
        _animationController!.dispose();
      }

      _animationController = AnimationController(
          vsync: this, duration: const Duration(milliseconds: 1500));

      animation = Tween<double>(begin: 400, end: 1).animate(scaleAnimation =
          CurvedAnimation(
              parent: _animationController!, curve: Curves.elasticOut))
        ..addListener(() {});
      _animationController!.forward();
    });
  }

  removeImage() {
    setState(() {
      imageFiles.removeLast();
    });
  }

  removeImageIndex(int index) {
    setState(() {
      imageFiles.removeAt(index);
    });
  }

  Widget? _animatedButton({Widget? customContent}) {
    return customContent ??
        Container(
          height: 70,
          width: 150,
          decoration: BoxDecoration(
            color: Colors.white38,
            borderRadius: BorderRadius.circular(100.0),
          ),
          child: const Center(
            child: Text(
              'Done',
              style: TextStyle(
                  fontSize: 20.0,
                  fontWeight: FontWeight.bold,
                  color: Colors.black),
            ),
          ),
        );
  }

  Future<void> _initCamera() async {
    _cameras = await availableCameras();

    if (!_cameras.isNotEmpty) {
      // print('No available cameras found.');
      return;
    }

    _controller?.dispose();
    _controller =
        CameraController(_cameras.first, widget.resolution, enableAudio: false);

    await _controller!.initialize();

    if (!mounted) {
      return;
    }

    setState(() {});
  }

  @override
  void initState() {
    _initCamera();
    _currIndex = 0;

    super.initState();
  }

  Widget _buildCameraPreview() {
    return OrientationBuilder(builder: (context, orientation) {
      double aspectRatio = orientation == Orientation.portrait
          ? (1 / _controller!.value.aspectRatio)
          : _controller!.value.aspectRatio;

      return Stack(
        fit: StackFit.expand,
        children: [
          Container(
            color: Colors.black,
          ),
          Align(
            alignment: Alignment.center,
            child: GestureDetector(
              onScaleStart: (details) {
                // 확대/축소 시작 지점이 카메라 프리뷰 영역 내인지 확인
                var box = context.findRenderObject() as RenderBox;
                var local = box.globalToLocal(details.focalPoint);
                if (box.size.contains(local)) {
                  // print("Scale Start in Preview Area");
                  zoom = _scaleFactor;
                }
              },
              onScaleUpdate: (details) {
                // 핀치 줌이 시작된 경우에만 스케일 업데이트
                //print("details.scale : ${details.scale}");
                setState(() {
                  _scaleFactor = zoom * details.scale;
                  _controller!.setZoomLevel(_scaleFactor);
                });
              },
              onScaleEnd: (details) {
                zoom = 1.0; // 핀치 줌 종료
              },
              child: _controller?.value.isInitialized ?? false
                  ? AspectRatio(
                      aspectRatio: aspectRatio,
                      child: CameraPreview(_controller!),
                    )
                  : const CircularProgressIndicator(),
            ),
          ),
          _buildPreviewImages(),
          _buildSwitchButton(),
          _buildPictureButton(),
        ],
      );
    });
  }

  void _onTapToFocus(TapDownDetails details) {
    if (!_controller!.value.isInitialized) {
      return;
    }

    final box = context.findRenderObject() as RenderBox;
    final offset = box.globalToLocal(details.globalPosition);
    final screenSize = box.size;
    final point =
        Offset(offset.dx / screenSize.width, offset.dy / screenSize.height);

    _controller!.setFocusPoint(point);
    _controller!.setExposurePoint(point);
  }

  Widget _buildPreviewImages() {
    return ListView.builder(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).orientation == Orientation.portrait
              ? 100
              : 30),
      shrinkWrap: true,
      itemCount: imageFiles.length,
      itemBuilder: ((context, index) {
        return Row(
          children: <Widget>[
            Container(
                alignment: Alignment.bottomLeft,
                // ignore: unnecessary_null_comparison
                child: imageFiles[index] != null
                    ? index == latestImageIndex // 최신 이미지만 애니메이션 적용
                        ? ScaleTransition(
                            scale: scaleAnimation,
                            child: buildImageItem(index),
                          )
                        : buildImageItem(index) // 나머지 이미지는 애니메이션 없이
                    : const Text("No image captured"))
          ],
        );
      }),
      scrollDirection: Axis.horizontal,
    );
  }

  Widget buildImageItem(int index) {
    return GestureDetector(
      onTap: () {
        if (!widget.isImagePreview) return;

        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (BuildContext context) => ImagePreviewView(
                      File(imageFiles[index].path),
                      "",
                    )));
      },
      child: Stack(
        children: [
          Image.file(
            File(imageFiles[index].path),
            height: 90,
            width: 60,
          ),
          Positioned(
              top: -10,
              right: -10,
              child: IconButton(
                iconSize: 30,
                icon: const Icon(
                  Icons.cancel_sharp,
                  color: Colors.red,
                ),
                onPressed: () {
                  setState(() {
                    removeImageIndex(index);
                  });
                },
              )),
        ],
      ),
    );
  }

  Widget _buildSwitchButton() {
    return Positioned(
      right: 30,
      bottom: 30,
      child: IconButton(
        iconSize: 40,
        icon: const Icon(
          Icons.autorenew,
          color: Colors.white,
        ),
        onPressed: _onCameraSwitch,
      ),
    );
  }

  Widget _buildPictureButton() {
    return Positioned(
      left:
          MediaQuery.of(context).orientation == Orientation.portrait ? 0 : null,
      bottom: MediaQuery.of(context).orientation == Orientation.portrait
          ? 0
          : MediaQuery.of(context).size.height / 2.5,
      right: 0,
      child: Column(
        children: [
          SafeArea(
            child: IconButton(
              iconSize: 80,
              icon: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  transitionBuilder: (child, anim) => RotationTransition(
                        turns: child.key == const ValueKey('icon1')
                            ? Tween<double>(begin: 1, end: 0.75).animate(anim)
                            : Tween<double>(begin: 0.75, end: 1).animate(anim),
                        child: ScaleTransition(scale: anim, child: child),
                      ),
                  child: _currIndex == 0
                      ? Container(
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: Colors.white,
                            ),
                            shape: BoxShape.circle,
                          ),
                          key: const ValueKey("icon1"),
                          child: Padding(
                            padding: const EdgeInsets.all(2.0),
                            child: Container(
                              height: 50,
                              width: 50,
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        )
                      : Container(
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: Colors.white,
                            ),
                            shape: BoxShape.circle,
                          ),
                          key: const ValueKey("icon2"),
                          child: Padding(
                            padding: const EdgeInsets.all(2.0),
                            child: Container(
                              height: 50,
                              width: 50,
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        )),
              onPressed: () {
                _currIndex = _currIndex == 0 ? 1 : 0;
                takePicture();
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _onCameraSwitch() async {
    final CameraDescription cameraDescription =
        (_controller!.description == _cameras[0]) ? _cameras[1] : _cameras[0];
    if (_controller != null) {
      await _controller!.dispose();
    }
    _controller = CameraController(cameraDescription, widget.resolution,
        enableAudio: false);

    _controller!.addListener(() {
      if (mounted) setState(() {});
      if (_controller!.value.hasError) {}
    });

    try {
      await _controller!.initialize();
      // ignore: empty_catches
    } on CameraException {}
    if (mounted) {
      setState(() {});
    }
  }

  takePicture() async {
    if (_controller!.value.isTakingPicture) {
      return null;
    }

    if (imageFiles.length >= widget.maxPhotos) {
      ScaffoldMessenger.of(context).showSnackBar(
        widget.customMaxSnackBar ??
            SnackBar(
              content:
                  Text('You cannot take more than ${widget.maxPhotos} photos.'),
              duration: Duration(seconds: 3),
            ),
      );

      return;
    }

    try {
      final image = await _controller!.takePicture();
      setState(() {
        addImages(image);
        HapticFeedback.lightImpact();
      });
    } on CameraException {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_controller != null) {
      if (!_controller!.value.isInitialized) {
        return Container();
      }
    } else {
      return const Center(
        child: SizedBox(
          width: 32,
          height: 32,
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        leading: IconButton(
          icon: const CircleAvatar(
            backgroundColor: Colors.white,
            child: Icon(Icons.arrow_back, color: Colors.black),
          ),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        actions: [
          imageFiles.isNotEmpty
              ? GestureDetector(
                  onTap: () {
                    for (int i = 0; i < imageFiles.length; i++) {
                      File file = File(imageFiles[i].path);
                      imageList.add(
                          MediaModel.blob(file, "", file.readAsBytesSync()));
                    }
                    Navigator.pop(context, imageList);
                  },
                  child: Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: _animatedButton(customContent: widget.customButton),
                  ))
              : const SizedBox()
        ],
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      backgroundColor: Theme.of(context).colorScheme.background,
      extendBody: true,
      body: _buildCameraPreview(),
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    _animationController?.dispose();

    super.dispose();
  }
}

class MediaModel {
  File file;
  String filePath;
  Uint8List blobImage;
  MediaModel.blob(this.file, this.filePath, this.blobImage);
}
