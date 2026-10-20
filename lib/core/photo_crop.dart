import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';

const _presets = [
  CropAspectRatioPreset.original,
  CropAspectRatioPreset.square,
  CropAspectRatioPreset.ratio4x3,
  CropAspectRatioPreset.ratio16x9,
];

/// Opens the crop screen on the whole photo with a free-form frame. Nothing forces a
/// square: confirm as is to keep the photo whole, drag the frame for any shape, or pick
/// a preset. Returns null if the user backs out.
Future<CroppedFile?> cropPhoto(String sourcePath) => ImageCropper().cropImage(
  sourcePath: sourcePath,
  compressFormat: ImageCompressFormat.jpg,
  compressQuality: 100,
  uiSettings: [
    AndroidUiSettings(
      toolbarTitle: 'Adjust photo',
      toolbarColor: Colors.blue,
      toolbarWidgetColor: Colors.white,
      initAspectRatio: CropAspectRatioPreset.original,
      lockAspectRatio: false,
      aspectRatioPresets: _presets,
    ),
    IOSUiSettings(
      title: 'Adjust photo',
      aspectRatioLockEnabled: false,
      resetAspectRatioEnabled: true,
      aspectRatioPresets: _presets,
    ),
  ],
);
