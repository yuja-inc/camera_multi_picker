// ignore_for_file: depend_on_referenced_packages

library camera_multi_picker;

import 'package:camera_multi_picker/picker_resolution_preset.dart';
import 'package:flutter/material.dart';
import 'package:camera_multi_picker/camera_file.dart';

class CameraMultiPicker {
  static Future<List<MediaModel>> capture({
    required BuildContext context,
    Widget? customDoneButton,
    SnackBar? customMaxSnackBar,
    int maxPhotoes = 50,
    bool isImagePreview = true,
    PickerResolutionPreset resolution = PickerResolutionPreset.max,
  }) async {
    List<MediaModel> images = [];
    try {
      images = await Navigator.push(
          context,
          MaterialPageRoute(
              builder: (BuildContext context) => CameraFile(
                    customButton: customDoneButton,
                    customMaxSnackBar: customMaxSnackBar,
                    maxPhotos: maxPhotoes,
                    isImagePreview: isImagePreview,
                    resolution: mapToInternalPreset(resolution),
                  )));
      // ignore: empty_catches
    } catch (e) {}

    return images;
  }
}
