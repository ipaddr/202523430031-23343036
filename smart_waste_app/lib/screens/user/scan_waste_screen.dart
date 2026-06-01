import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../utils/constants.dart';
import '../../services/tflite_service.dart';
import '../../services/camera_provider.dart';

class ScanWasteScreen extends StatefulWidget {
  const ScanWasteScreen({super.key});

  @override
  State<ScanWasteScreen> createState() => _ScanWasteScreenState();
}

class _ScanWasteScreenState extends State<ScanWasteScreen>
    with WidgetsBindingObserver {
  final TFLiteService _tfliteService = TFLiteService();
  final ImagePicker _imagePicker = ImagePicker();
  List<WastePrediction> _topPredictions = [];
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    try {
      print('[ScanWaste] Initializing services...');

      // Initialize TFLite model
      await _tfliteService.initialize();
      print('[ScanWaste] TFLite initialized: ${_tfliteService.isInitialized}');

      // Initialize camera
      if (mounted) {
        final cameraProvider = Provider.of<CameraProvider>(
          context,
          listen: false,
        );
        await cameraProvider.initializeCamera();
        print('[ScanWaste] Camera initialized');
      }

      print('[ScanWaste] ✅ All services initialized successfully');
    } catch (e) {
      print('[ScanWaste] ❌ Error initializing: $e');
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _tfliteService.dispose();
    super.dispose();
  }

  Future<void> _captureAndClassify() async {
    if (_isProcessing) return;

    setState(() => _isProcessing = true);

    try {
      final cameraProvider = Provider.of<CameraProvider>(
        context,
        listen: false,
      );
      
      // Check camera initialization
      if (!cameraProvider.isInitialized || cameraProvider.controller == null) {
        print('[ScanWaste] ❌ Camera not initialized');
        print('[ScanWaste] isInitialized: ${cameraProvider.isInitialized}');
        print('[ScanWaste] controller: ${cameraProvider.controller}');
        
        if (mounted) {
          setState(() => _isProcessing = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Kamera belum siap. Tunggu beberapa detik...'),
              duration: Duration(seconds: 2),
            ),
          );
        }
        return;
      }
      
      // Check TFLite initialization
      if (!_tfliteService.isInitialized) {
        print('[ScanWaste] ❌ TFLite not initialized');
        
        if (mounted) {
          setState(() => _isProcessing = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Model AI belum siap. Tunggu beberapa detik...'),
              duration: Duration(seconds: 2),
            ),
          );
        }
        return;
      }

      print('[ScanWaste] ✅ All services ready, capturing image...');

      // Capture image
      final XFile image = await cameraProvider.controller!.takePicture();
      final imageData = await image.readAsBytes();

      print('[ScanWaste] ✅ Image captured, size: ${imageData.length} bytes');

      await _classifyImageBytes(imageData);
      return;

      // Classify - get top 3 predictions
    } catch (e) {
      print('[ScanWaste] ❌ ERROR capturing image: $e');
      print('[ScanWaste] Stack trace: ${StackTrace.current}');
      
      if (mounted) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _pickFromGallery() async {
    if (_isProcessing) return;

    try {
      final image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 95,
      );

      if (image == null) return;

      if (mounted) setState(() => _isProcessing = true);

      final imageData = await image.readAsBytes();
      print(
        '[ScanWaste] Gallery image selected, size: ${imageData.length} bytes',
      );
      await _classifyImageBytes(imageData);
    } catch (e) {
      print('[ScanWaste] ERROR picking gallery image: $e');
      if (mounted) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mengambil gambar dari galeri: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<bool> _classifyImageBytes(Uint8List imageData) async {
    final predictions = await _tfliteService.classifyImageTopN(
      imageData,
      topN: 3,
    );

    if (!mounted) return true;

    if (predictions.isEmpty) {
      print('[ScanWaste] Classification returned no results');
      setState(() => _isProcessing = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Scan gagal. Coba foto lebih dekat, latar lebih bersih, atau pencahayaan lebih terang.',
          ),
          duration: Duration(seconds: 3),
          backgroundColor: Colors.red,
        ),
      );
      return true;
    }

    print(
      '[ScanWaste] Classification SUCCESS: ${predictions[0].label} (${(predictions[0].confidence * 100).toStringAsFixed(1)}%)',
    );
    setState(() {
      _topPredictions = predictions;
      _isProcessing = false;
    });
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            // Camera Preview
            _buildCameraPreview(),

            // Header
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.6),
                      Colors.transparent,
                    ],
                  ),
                ),
                padding: const EdgeInsets.all(AppPadding.lg),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.arrow_back,
                          color: AppColors.white,
                          size: 20,
                        ),
                      ),
                    ),
                    const Text(
                      'Scan Sampah',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.white,
                      ),
                    ),
                    GestureDetector(
                      onTap: () {},
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.info_outline,
                          color: AppColors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Focus Box (center)
            Positioned.fill(
              child: Center(
                child: Container(
                  width: 250,
                  height: 250,
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.secondary, width: 3),
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.secondary.withValues(alpha: 0.3),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Bottom Section
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.8),
                    ],
                  ),
                ),
                padding: const EdgeInsets.all(AppPadding.lg),
                child: _buildBottomSection(),
              ),
            ),

            // Loading Indicator
            if (_isProcessing)
              Positioned.fill(
                child: Container(
                  color: Colors.black.withValues(alpha: 0.5),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppColors.secondary,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Menganalisis sampah...',
                          style: TextStyle(
                            color: AppColors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCameraPreview() {
    return Consumer<CameraProvider>(
      builder: (context, cameraProvider, _) {
        if (!cameraProvider.isInitialized) {
          return Container(
            color: Colors.black,
            child: const Center(child: CircularProgressIndicator()),
          );
        }

        return CameraPreview(cameraProvider.controller!);
      },
    );
  }

  Widget _buildBottomSection() {
    final hasResults = _topPredictions.isNotEmpty;
    final topPrediction = hasResults ? _topPredictions[0] : null;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (hasResults) ...[
          // Detection Results Card
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.98),
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
            padding: const EdgeInsets.all(AppPadding.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title with Icon
                Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.check_circle,
                        color: Colors.green,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Detection Results',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.black,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Predictions List with Progress Bars
                ..._buildPredictionsList(),

                const SizedBox(height: 16),

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          setState(() => _topPredictions = []);
                        },
                        icon: const Icon(Icons.refresh),
                        label: const Text('Scan Ulang'),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(
                            color: AppColors.primary,
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context, topPrediction);
                        },
                        icon: const Icon(Icons.check),
                        label: const Text('Konfirmasi'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ] else ...[
          // Instructions (No Results)
          const Column(
            children: [
              Text(
                'Arahkan Kamera ke Sampah',
                style: TextStyle(
                  color: AppColors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Letakkan sampah di dalam kotak focus untuk hasil akurat',
                style: TextStyle(color: Color(0xFFD0D0D0), fontSize: 12),
              ),
            ],
          ),
        ],
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildRoundActionButton(
              icon: Icons.photo_library,
              tooltip: 'Ambil dari galeri',
              onTap: _pickFromGallery,
              size: 56,
              iconSize: 24,
              outlined: true,
            ),
            const SizedBox(width: 18),
            _buildRoundActionButton(
              icon: _isProcessing ? Icons.hourglass_bottom : Icons.camera,
              tooltip: 'Scan dengan kamera',
              onTap: _captureAndClassify,
              size: 70,
              iconSize: 28,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRoundActionButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
    double size = 64,
    double iconSize = 26,
    bool outlined = false,
  }) {
    return Tooltip(
      message: tooltip,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: outlined
              ? null
              : const LinearGradient(
                  colors: [AppColors.secondary, Color(0xFF0D5A2F)],
                ),
          color: outlined ? Colors.white.withValues(alpha: 0.18) : null,
          border: outlined ? Border.all(color: Colors.white, width: 1.5) : null,
          boxShadow: [
            BoxShadow(
              color: AppColors.secondary.withValues(alpha: 0.28),
              blurRadius: 12,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _isProcessing ? null : onTap,
            borderRadius: BorderRadius.circular(size / 2),
            child: Center(
              child: Icon(icon, color: Colors.white, size: iconSize),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildPredictionsList() {
    return List.generate(_topPredictions.length, (index) {
      final prediction = _topPredictions[index];
      final confidence = prediction.confidence * 100;
      final isHighConfidence = confidence >= 50;
      final category = _tfliteService.getWasteCategory(prediction.label);
      final categoryIcon = category == 'Organic' ? '🌱' : '♻️';

      return Padding(
        padding: EdgeInsets.only(
          bottom: index < _topPredictions.length - 1 ? 16 : 0,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Label and Confidence
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Text(
                        '${index + 1}. ',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          prediction.label,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.black,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: isHighConfidence
                        ? Colors.green.withValues(alpha: 0.2)
                        : Colors.orange.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${confidence.toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isHighConfidence
                          ? Colors.green[700]
                          : Colors.orange[700],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Info Row: Category and Points
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Category Badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: category == 'Organic'
                        ? const Color(0xFF6B8E23).withValues(alpha: 0.2)
                        : const Color(0xFF4A90E2).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    children: [
                      Text(categoryIcon, style: const TextStyle(fontSize: 12)),
                      const SizedBox(width: 4),
                      Text(
                        category,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: category == 'Organic'
                              ? const Color(0xFF6B8E23)
                              : const Color(0xFF4A90E2),
                        ),
                      ),
                    ],
                  ),
                ),
                // Points Badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    children: [
                      const Text('⭐', style: TextStyle(fontSize: 12)),
                      const SizedBox(width: 4),
                      Text(
                        '${prediction.points} pts',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFFFA500),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Progress Bar
            Stack(
              children: [
                // Background
                Container(
                  height: 6,
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                // Filled portion
                Container(
                  height: 6,
                  width:
                      (confidence / 100) *
                      (MediaQuery.of(context).size.width - 72),
                  decoration: BoxDecoration(
                    color: _getColorByIndex(index),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    });
  }

  Color _getColorByIndex(int index) {
    const colors = [
      Colors.orange, // First/top prediction - orange
      Colors.red, // Second prediction - red
      Colors.amber, // Third prediction - amber
    ];
    return colors[index < colors.length ? index : 0];
  }
}
