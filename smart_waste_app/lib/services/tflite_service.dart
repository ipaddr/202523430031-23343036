import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:typed_data';
import 'dart:math' as math;
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

class WastePrediction {
  final String label;
  final double confidence;
  final int points;
  final int rank;

  WastePrediction({
    required this.label,
    required this.confidence,
    required this.points,
    required this.rank,
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

  // Waste category mapping - Kategorisasi sampah (Organic/Anorganic)
  static const Map<String, String> wasteCategoryMap = {
    'vegetation': 'Organic', // 🌱 Vegetasi
    'food_organics': 'Organic', // 🌱 Sisa makanan
    'food organics': 'Organic', // 🌱 Sisa makanan (alt)
    'paper': 'Organic', // 🌱 Kertas
    'cardboard': 'Organic', // 🌱 Karton
    'textile_trash': 'Anorganic', // ♻️ Kain/Tekstil
    'textile trash': 'Anorganic', // ♻️ Kain/Tekstil (alt)
    'plastic': 'Anorganic', // ♻️ Plastik
    'miscellaneous_trash': 'Anorganic', // ♻️ Sampah anorganik lainnya
    'miscellaneous trash': 'Anorganic', // ♻️ Sampah anorganik lainnya (alt)
    'metal': 'Anorganic', // ♻️ Logam
    'glass': 'Anorganic', // ♻️ Kaca
    'other': 'Anorganic',
  };

  factory TFLiteService() {
    return _instance;
  }

  TFLiteService._internal();

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      debugPrint('[TFLiteService] Starting model initialization...');

      // Load model
      InterpreterOptions options = InterpreterOptions();
      try {
        final gpuDelegateV2 = GpuDelegateV2(
          options: GpuDelegateOptionsV2(isPrecisionLossAllowed: false),
        );
        options.addDelegate(gpuDelegateV2);
        debugPrint('[TFLiteService] GPU delegate enabled');
      } catch (e) {
        debugPrint('[TFLiteService] GPU delegate not available or failed: $e');
      }

      interpreter = await Interpreter.fromAsset(
        'model_unquant.tflite',
        options: options,
      );
      debugPrint('[TFLiteService] Model loaded successfully');

      // Load labels
      final labelsData = await rootBundle.loadString('assets/labels.txt');
      labels = labelsData
          .split('\n')
          .map((label) => label.trim())
          .where((label) => label.isNotEmpty)
          .toList();

      debugPrint('[TFLiteService] Loaded ${labels.length} labels: $labels');

      // Debug: Print model input/output tensor shapes for verification
      try {
        final inputTensors = interpreter?.getInputTensors() ?? [];
        final outputTensors = interpreter?.getOutputTensors() ?? [];

        debugPrint('[TFLiteService] ℹ️ Model Tensor Info:');
        if (inputTensors.isNotEmpty) {
          debugPrint('[TFLiteService]   Input shape: ${inputTensors[0].shape}');
          debugPrint('[TFLiteService]   Input type: ${inputTensors[0].type}');
        }
        if (outputTensors.isNotEmpty) {
          debugPrint(
            '[TFLiteService]   Output shape: ${outputTensors[0].shape}',
          );
          debugPrint('[TFLiteService]   Output type: ${outputTensors[0].type}');
        }
      } catch (e) {
        debugPrint('[TFLiteService] ℹ️ Could not read tensor metadata: $e');
      }

      _isInitialized = true;
      debugPrint('[TFLiteService] ✅ TFLite model initialized successfully');
    } catch (e) {
      debugPrint('[TFLiteService] ❌ ERROR initializing TFLite: $e');
      _isInitialized = false;
    }
  }

  bool get isInitialized => _isInitialized;

  Future<WasteClassification?> classifyImage(Uint8List imageData) async {
    if (!_isInitialized) {
      debugPrint('[TFLiteService] ERROR: TFLite not initialized');
      return null;
    }

    try {
      debugPrint('[TFLiteService] Starting classification...');

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

      debugPrint(
        '[TFLiteService] Top prediction: ${labels[maxIndex]} (${(maxConfidence * 100).toStringAsFixed(1)}%)',
      );

      // Return result if confidence is above 20% (lowered threshold for better UX)
      // User can confirm or retry if they want higher confidence
      if (maxConfidence < 0.2) {
        debugPrint(
          '[TFLiteService] Confidence too low (< 20%): $maxConfidence',
        );
        return null;
      }

      final label = labels[maxIndex];
      final points = _getPoints(label);

      debugPrint(
        '[TFLiteService] Classification SUCCESS: $label with $maxConfidence confidence, ${points} points',
      );

      return WasteClassification(
        label: label,
        confidence: maxConfidence,
        points: points,
      );
    } catch (e) {
      debugPrint('[TFLiteService] ERROR in classifyImage: $e');
      return null;
    }
  }

  /// Get top N predictions for waste classification
  /// Returns list of predictions sorted by confidence (highest first)
  Future<List<WastePrediction>> classifyImageTopN(
    Uint8List imageData, {
    int topN = 3,
  }) async {
    if (!_isInitialized) {
      debugPrint('[TFLiteService] ERROR: TFLite not initialized');
      return [];
    }

    try {
      debugPrint('[TFLiteService] Starting top-N classification (N=$topN)...');

      // Prepare input
      final input = _preprocessImage(imageData);

      // Run inference
      final List<List<double>> output = List.generate(
        1,
        (_) => List.filled(labels.length, 0.0),
      );
      interpreter?.run(input, output);

      final List<double> predictions = output.isNotEmpty
          ? List<double>.from(output[0])
          : <double>[];

      debugPrint('[TFLiteService] Got ${predictions.length} predictions');

      // Create list of (index, confidence) pairs
      List<MapEntry<int, double>> indexed = [];
      for (int i = 0; i < predictions.length; i++) {
        indexed.add(MapEntry(i, predictions[i]));
      }

      // Sort by confidence descending
      indexed.sort((a, b) => b.value.compareTo(a.value));

      // Create WastePrediction objects for top N
      final topPredictions = <WastePrediction>[];
      for (int i = 0; i < math.min(topN, indexed.length); i++) {
        final index = indexed[i].key;
        final confidence = indexed[i].value;
        final label = labels[index];
        final points = _getPoints(label);

        debugPrint(
          '[TFLiteService] Rank ${i + 1}: $label - ${(confidence * 100).toStringAsFixed(1)}%',
        );

        topPredictions.add(
          WastePrediction(
            label: label,
            confidence: confidence,
            points: points,
            rank: i + 1,
          ),
        );
      }

      // Keep low-confidence results visible so users can confirm or rescan.
      // PERBAIKAN: Ubah threshold dari 0.05 menjadi 0.01 (1%)
      // Ini memungkinkan hasil dengan confidence lebih rendah untuk ditampilkan
      if (topPredictions.isNotEmpty && topPredictions[0].confidence < 0.01) {
        debugPrint(
          '[TFLiteService] Top confidence too low (${topPredictions[0].confidence}): filtering out',
        );
        return [];
      }

      debugPrint(
        '[TFLiteService] ✅ Top-N classification SUCCESS: ${topPredictions.length} results',
      );
      return topPredictions;
    } catch (e) {
      debugPrint('[TFLiteService] ERROR in classifyImageTopN: $e');
      return [];
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

      image = img.bakeOrientation(image);

      // Resize to 224x224 (common input size for mobile image models)
      const int inputSize = 224;
      final img.Image resized = img.copyResize(
        image,
        width: inputSize,
        height: inputSize,
      );

      // Teachable Machine unquantized image models expect float values in [-1, 1].
      final List<List<List<List<double>>>> input = List.generate(
        1,
        (_) => List.generate(
          inputSize,
          (y) => List.generate(inputSize, (x) {
            final pixel = resized.getPixelSafe(x, y);
            final r = ((pixel.r as int) - 127.5) / 127.5;
            final g = ((pixel.g as int) - 127.5) / 127.5;
            final b = ((pixel.b as int) - 127.5) / 127.5;
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

  /// Get waste category (Organic/Anorganic) based on waste type label
  /// Returns 'Organic' or 'Anorganic'
  String getWasteCategory(String label) {
    final labelKey = label.toLowerCase().trim();

    // Direct lookup first
    if (wasteCategoryMap.containsKey(labelKey)) {
      return wasteCategoryMap[labelKey] ?? 'Anorganic';
    }

    // Try with underscore replacement
    final labelWithUnderscore = labelKey.replaceAll(' ', '_');
    if (wasteCategoryMap.containsKey(labelWithUnderscore)) {
      return wasteCategoryMap[labelWithUnderscore] ?? 'Anorganic';
    }

    // Try partial matching
    for (var key in wasteCategoryMap.keys) {
      if (labelKey.contains(key) || key.contains(labelKey)) {
        return wasteCategoryMap[key] ?? 'Anorganic';
      }
    }

    // Default fallback
    return 'Anorganic';
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
