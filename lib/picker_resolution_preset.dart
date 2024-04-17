import 'package:camera/camera.dart';

enum PickerResolutionPreset {
  low,
  medium,
  high,
  veryHigh,
  ultraHigh,
  max,
}

ResolutionPreset mapToInternalPreset(PickerResolutionPreset preset) {
  switch (preset) {
    case PickerResolutionPreset.low:
      return ResolutionPreset.low;
    case PickerResolutionPreset.medium:
      return ResolutionPreset.medium;
    case PickerResolutionPreset.high:
      return ResolutionPreset.high;
    case PickerResolutionPreset.veryHigh:
      return ResolutionPreset.veryHigh;
    case PickerResolutionPreset.ultraHigh:
      return ResolutionPreset.ultraHigh;
    case PickerResolutionPreset.max:
      return ResolutionPreset.max;
    default:
      return ResolutionPreset.medium;
  }
}
