import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'tflite_service.dart';

class CameraProvider with ChangeNotifier {
  late CameraController _controller;
  List<CameraDescription>? _cameras;
  bool _isInitialized = false;
  bool _isScanning = false;
  WasteClassification? _lastClassification;
  String? _error;

  CameraController? get controller => _isInitialized ? _controller : null;
  bool get isInitialized => _isInitialized;
  bool get isScanning => _isScanning;
  WasteClassification? get lastClassification => _lastClassification;
  String? get error => _error;

  Future<void> initializeCamera() async {
    try {
      _cameras = await availableCameras();

      if (_cameras!.isEmpty) {
        _error = 'Tidak ada kamera tersedia';
        notifyListeners();
        return;
      }

      // Use back camera
      final camera = _cameras!.firstWhere(
        (cam) => cam.lensDirection == CameraLensDirection.back,
        orElse: () => _cameras!.first,
      );

      _controller = CameraController(
        camera,
        ResolutionPreset.high,
        enableAudio: false,
      );

      await _controller.initialize();
      _isInitialized = true;
      _error = null;
      notifyListeners();
    } catch (e) {
      _error = 'Error initializing camera: $e';
      _isInitialized = false;
      notifyListeners();
    }
  }

  Future<void> startScanning() async {
    _isScanning = true;
    _lastClassification = null;
    notifyListeners();
  }

  Future<void> stopScanning() async {
    _isScanning = false;
    notifyListeners();
  }

  Future<void> setClassification(WasteClassification? classification) async {
    _lastClassification = classification;
    notifyListeners();
  }

  @override
  void dispose() {
    if (_isInitialized) {
      _controller.dispose();
    }
    super.dispose();
  }
}
