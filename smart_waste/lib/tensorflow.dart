import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart' as tflite;

class TensorFlowHelper {
  static final TensorFlowHelper _instance = TensorFlowHelper._internal();
  late tflite.Interpreter interpreter;
  List<String> labels = [];

  factory TensorFlowHelper() {
    return _instance;
  }

  TensorFlowHelper._internal();

  bool _isInitialized = false;

  bool get isInitialized => _isInitialized;

  Future<void> loadModel() async {
    try {
      interpreter = await tflite.Interpreter.fromAsset(
        'assets/model_unquant.tflite',
      );

      // Load labels
      final labelData = await _loadAsset('assets/labels.txt');
      labels = labelData
          .split('\n')
          .where((label) => label.isNotEmpty)
          .toList();

      debugPrint("TensorFlow Lite Model Loaded Successfully");
      debugPrint("Number of labels: ${labels.length}");
      _isInitialized = true;
    } catch (e) {
      debugPrint("Error loading TensorFlow model: $e");
      _isInitialized = false;
    }
  }

  Future<String> _loadAsset(String path) async {
    try {
      final data = await rootBundle.loadString(path);
      return data;
    } catch (e) {
      debugPrint("Error loading asset $path: $e");
      return '';
    }
  }

  Future<List<dynamic>> classifyImage(String imagePath) async {
    try {
      if (!_isInitialized) {
        await loadModel();
      }

      if (labels.isEmpty) {
        debugPrint("Labels not loaded");
        return [];
      }

      // Load and decode image
      final imageFile = File(imagePath);
      if (!imageFile.existsSync()) {
        debugPrint("Image file not found: $imagePath");
        return [];
      }

      final bytes = imageFile.readAsBytesSync();
      img.Image? image = img.decodeImage(bytes);
      if (image == null) {
        debugPrint("Failed to decode image");
        return [];
      }

      // Get input shape from model
      final inputShape = interpreter.getInputTensor(0).shape;
      int inputHeight = inputShape[1];
      int inputWidth = inputShape[2];

      debugPrint("Image resized to: $inputWidth x $inputHeight");

      // Resize image
      img.Image resized = img.copyResize(
        image,
        width: inputWidth,
        height: inputHeight,
      );

      // Convert to input format (assuming uint8)
      final input = _imageToByteList(resized, inputWidth, inputHeight);

      // Run inference
      final output = List<List<double>>.filled(
        1,
        List<double>.filled(labels.length, 0),
      );
      interpreter.run(input, output);

      // Process output
      List<Map<String, dynamic>> recognitions = [];
      List<double> predictions = output[0];

      // Find top predictions
      for (int i = 0; i < predictions.length; i++) {
        double confidence = predictions[i];
        if (confidence > 0.1) {
          recognitions.add({
            'label': labels[i],
            'confidence': confidence,
            'index': i,
          });
        }
      }

      // Sort by confidence
      recognitions.sort(
        (a, b) =>
            (b['confidence'] as double).compareTo(a['confidence'] as double),
      );

      debugPrint("Classification results: $recognitions");
      return recognitions.take(5).toList(); // Return top 5
    } catch (e) {
      debugPrint("Error classifying image: $e");
      return [];
    }
  }

  List<List<List<List<int>>>> _imageToByteList(
    img.Image image,
    int width,
    int height,
  ) {
    final convertedBytes = List<List<List<List<int>>>>.filled(
      1,
      List.filled(height, List.filled(width, List.filled(3, 0))),
    );

    var pixelData = convertedBytes[0];
    for (var y = 0; y < height; y++) {
      for (var x = 0; x < width; x++) {
        final pixel = image.getPixelSafe(x, y);
        pixelData[y][x][0] = (pixel.r.toInt());
        pixelData[y][x][1] = (pixel.g.toInt());
        pixelData[y][x][2] = (pixel.b.toInt());
      }
    }

    return convertedBytes;
  }

  Future<void> closeModel() async {
    try {
      interpreter.close();
      _isInitialized = false;
    } catch (e) {
      debugPrint("Error closing TensorFlow model: $e");
    }
  }
}
