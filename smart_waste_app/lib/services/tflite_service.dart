import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:typed_data';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;

class WasteClassification {
  final String label;
  final double confidence;
  final int points;

  WasteClassification({
    required this.label,
    required this.confidence,
    required this.points,
  });
}

class TFLiteService {
  static final TFLiteService _instance = TFLiteService._internal();
  Interpreter? interpreter;
  late List<String> labels;
  bool _isInitialized = false;

  // Waste classification points mapping - Updated to match model labels
  // Model labels: Vegetation, Textile Trash, Plastic, Paper, Miscellaneous Trash, Metal, Glass, Cardboard, Food Organics
  static const Map<String, int> wastePointsMap = {
    'vegetation': 25, // Vegetasi (mudah terurai)
    'textile_trash': 40, // Kain/tekstil
    'textile trash': 40, // Alternative format
    'plastic': 80, // Plastik (berbahaya, lama terurai)
    'paper': 20, // Kertas (mudah terurai)
    'miscellaneous_trash': 30, // Sampah anorganik lainnya
    'miscellaneous trash': 30, // Alternative format
    'metal': 70, // Logam (dapat didaur ulang)
    'glass': 75, // Kaca (dapat didaur ulang, tajam)
    'cardboard': 25, // Karton (mudah terurai, dapat didaur)
    'food_organics': 15, // Sisa makanan (mudah terurai)
    'food organics': 15, // Alternative format
    'other': 10,
  };

  factory TFLiteService() {
    return _instance;
  }

  TFLiteService._internal();

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Load model
      InterpreterOptions options = InterpreterOptions();
      try {
        final gpuDelegateV2 = GpuDelegateV2(
          options: GpuDelegateOptionsV2(isPrecisionLossAllowed: false),
        );
        options.addDelegate(gpuDelegateV2);
      } catch (e) {
        debugPrint('GPU delegate not available or failed: $e');
      }

      interpreter = await Interpreter.fromAsset(
        'model_unquant.tflite',
        options: options,
      );

      // Load labels
      final labelsData = await rootBundle.loadString('assets/labels.txt');
      labels = labelsData
          .split('\n')
          .map((label) => label.trim())
          .where((label) => label.isNotEmpty)
          .toList();

      _isInitialized = true;
      debugPrint('TFLite model initialized successfully');
    } catch (e) {
      debugPrint('Error initializing TFLite: $e');
      _isInitialized = false;
    }
  }

  bool get isInitialized => _isInitialized;

  Future<WasteClassification?> classifyImage(Uint8List imageData) async {
    if (!_isInitialized) {
      debugPrint('TFLite not initialized');
      return null;
    }

    try {
      // Prepare input - resize to 224x224 (common for image classification models)
      final input = _preprocessImage(imageData);

      // Run inference
      final List<List<double>> output = List.generate(
        1,
        (_) => List.filled(labels.length, 0.0),
      );
      interpreter?.run(input, output);

      // Get highest confidence result
      final List<double> predictions = output.isNotEmpty
          ? List<double>.from(output[0])
          : <double>[];
      int maxIndex = 0;
      double maxConfidence = predictions.isNotEmpty ? predictions[0] : 0.0;

      for (int i = 1; i < predictions.length; i++) {
        if (predictions[i] > maxConfidence) {
          maxConfidence = predictions[i];
          maxIndex = i;
        }
      }

      // Only return if confidence is above threshold (50%)
      if (maxConfidence < 0.5) {
        return null;
      }

      final label = labels[maxIndex];
      final points = _getPoints(label);

      return WasteClassification(
        label: label,
        confidence: maxConfidence,
        points: points,
      );
    } catch (e) {
      debugPrint('Error classifying image: $e');
      return null;
    }
  }

  List<List<List<List<double>>>> _preprocessImage(Uint8List imageData) {
    try {
      // Decode the image
      img.Image? image = img.decodeImage(imageData);
      if (image == null) {
        debugPrint('Failed to decode image');
        throw Exception('Image decoding failed');
      }

      // Resize to 224x224 (common input size for mobile models)
      const int inputSize = 224;
      final img.Image resized = img.copyResize(
        image,
        width: inputSize,
        height: inputSize,
      );

      // Normalize and convert to input tensor format
      // Most TFLite models expect values normalized to [-1, 1] or [0, 1]
      final List<List<List<List<double>>>> input = List.generate(
        1,
        (_) => List.generate(
          inputSize,
          (y) => List.generate(inputSize, (x) {
            final pixel = resized.getPixelSafe(x, y);
            // Extract RGB channels and normalize to [0, 1]
            final r = (pixel.r as int) / 255.0;
            final g = (pixel.g as int) / 255.0;
            final b = (pixel.b as int) / 255.0;
            return [r, g, b];
          }),
        ),
      );

      return input;
    } catch (e) {
      debugPrint('Error preprocessing image: $e');
      // Return placeholder if preprocessing fails
      const int inputSize = 224;
      return List.generate(
        1,
        (_) => List.generate(
          inputSize,
          (_) => List.generate(inputSize, (_) => [0.5, 0.5, 0.5]),
        ),
      );
    }
  }

  int _getPoints(String label) {
    // Normalize label for matching
    final labelKey = label.toLowerCase().trim();

    // Direct lookup first
    if (wastePointsMap.containsKey(labelKey)) {
      return wastePointsMap[labelKey] ?? 10;
    }

    // Try with underscore replacement
    final labelWithUnderscore = labelKey.replaceAll(' ', '_');
    if (wastePointsMap.containsKey(labelWithUnderscore)) {
      return wastePointsMap[labelWithUnderscore] ?? 10;
    }

    // Try partial matching
    for (var key in wastePointsMap.keys) {
      if (labelKey.contains(key) || key.contains(labelKey)) {
        return wastePointsMap[key] ?? 10;
      }
    }

    // Default fallback
    return wastePointsMap['other'] ?? 10;
  }

  void dispose() {
    try {
      interpreter?.close();
    } catch (e) {
      debugPrint('Error closing interpreter: $e');
    }
    interpreter = null;
    _isInitialized = false;
  }
}
